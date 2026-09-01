import os
import sys
import json
import re
import queue
import threading
import io
import wave
from pathlib import Path
import requests
import torch
import scipy.io.wavfile
import numpy as np
import sounddevice as sd
from transformers import VitsModel, AutoTokenizer
from faster_whisper import WhisperModel
from groq import Groq
from piper.voice import PiperVoice

os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
torch.set_num_threads(os.cpu_count() or 4)

from PySide6.QtCore import QObject, Signal, Slot, Property
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
MODEL_NAME = "hizli-asistan"

# --- GROQ API ---
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
groq_client = Groq(api_key=GROQ_API_KEY) if GROQ_API_KEY.startswith("gsk_") else None

# --- META MMS-TTS MODELİ ---
TTS_MODEL_NAME = "facebook/mms-tts-tur"
tts_tokenizer = AutoTokenizer.from_pretrained(TTS_MODEL_NAME)
tts_model = VitsModel.from_pretrained(TTS_MODEL_NAME)
tts_model.eval()
tts_model.speaking_rate = 1.05

# --- PIPER TTS MODELİ ---
piper_model_path = "tr_kadin.onnx"
piper_config_path = "tr_kadin.onnx.json"
piper_voice = None
if os.path.exists(piper_model_path) and os.path.exists(piper_config_path):
    piper_voice = PiperVoice.load(piper_model_path, config_path=piper_config_path)

# --- YEREL WHISPER ---
stt_model = WhisperModel("large-v3-turbo", device="cpu", compute_type="int8", cpu_threads=os.cpu_count() or 4)


class AsistanKoprusu(QObject):
    cevapGeldi = Signal(str)
    yeniMesajEkle = Signal(str, str)
    mesajGuncelle = Signal(str)
    durumDegisti = Signal(str)
    duvarKagidiDegisti = Signal()
    modDegisti = Signal()
    ttsModDegisti = Signal()

    def __init__(self):
        super().__init__()
        klasor = Path.home() / "Masaüstü" / "my wallpaper trials"
        gecerli_uzantilar = {".jpg", ".jpeg", ".png", ".webp"}

        self._duvar_kagitlari = [""]
        if klasor.exists():
            for dosya in klasor.iterdir():
                if dosya.suffix.lower() in gecerli_uzantilar:
                    self._duvar_kagitlari.append(f"file://{dosya.resolve()}")

        self._index = 0
        self._kayit_suruyor = False
        self._ses_bloklari = []
        self._stream = None
        
        self._online_mod = True
        self._piper_mod = True

# _piper_mod yerine 3 durumlu tts modu (0: Piper, 1: Meta, 2: Sessiz)
        self._tts_mod = 0  # 0: Piper, 1: Meta, 2: Sessiz/Mute

    @Property(int, notify=ttsModDegisti)
    def ttsMod(self):
        return self._tts_mod

    @ttsMod.setter
    def ttsMod(self, val):
        if self._tts_mod != val:
            self._tts_mod = val
            self.ttsModDegisti.emit()
            durumlar = ["PIPER (Ultra Hızlı)", "META MMS (Doğal)", "SESSİZ (Mute)"]
            print(f"[TTS Motoru]: {durumlar[val]}")

    # _llm_sorgula içinde ses kuyruğuna atarken:
    # if self._tts_mod != 2:
    #     self._cumleyi_kuyruga_at(cumle_tamponu.strip(), ses_kuyrugu)

    @Property(bool, notify=ttsModDegisti)
    def piperMod(self):
        return self._piper_mod

    @piperMod.setter
    def piperMod(self, val):
        if self._piper_mod != val:
            self._piper_mod = val
            self.ttsModDegisti.emit()
            print(f"[TTS Motoru]: {'PIPER (Ultra Hızlı)' if val else 'META MMS (Doğal/Ağır)'}")

    @Property(str, notify=duvarKagidiDegisti)
    def aktifDuvarKagidi(self):
        return self._duvar_kagitlari[self._index]

    @Property(bool, notify=duvarKagidiDegisti)
    def duvarKagidiVarMi(self):
        return bool(self._duvar_kagitlari[self._index])

    @Slot()
    def sonrakiDuvarKagidi(self):
        if self._duvar_kagitlari:
            self._index = (self._index + 1) % len(self._duvar_kagitlari)
            self.duvarKagidiDegisti.emit()

    @Slot()
    def oncekiDuvarKagidi(self):
        if self._duvar_kagitlari:
            self._index = (self._index - 1 + len(self._duvar_kagitlari)) % len(self._duvar_kagitlari)
            self.duvarKagidiDegisti.emit()

    @Slot()
    def basKonusBasla(self):
        if self._kayit_suruyor:
            return
        self._kayit_suruyor = True
        self._ses_bloklari = []
        self.durumDegisti.emit("dinliyor")

        def callback(indata, frames, time_info, status):
            if self._kayit_suruyor:
                self._ses_bloklari.append(indata.copy())

        self._stream = sd.InputStream(samplerate=16000, channels=1, dtype="float32", callback=callback)
        self._stream.start()

    @Slot()
    def basKonusBitir(self):
        if not self._kayit_suruyor:
            return
        self._kayit_suruyor = False
        if self._stream:
            self._stream.stop()
            self._stream.close()

        self.durumDegisti.emit("dusunuyor")
        threading.Thread(target=self._sesi_isle, daemon=True).start()

    def _sesi_isle(self):
        try:
            if not self._ses_bloklari:
                self.durumDegisti.emit("hazir")
                return

            tam_ses = np.concatenate(self._ses_bloklari, axis=0).flatten()
            maks_deger = np.max(np.abs(tam_ses))
            if maks_deger > 0:
                tam_ses = tam_ses / maks_deger * 0.95

            algilanan_metin = ""

            if self._online_mod and groq_client:
                print("[STT] Groq API çalışıyor...")
                wav_io = io.BytesIO()
                scipy.io.wavfile.write(wav_io, 16000, (tam_ses * 32767).astype(np.int16))
                wav_io.seek(0)
                transcription = groq_client.audio.transcriptions.create(
                    file=("ses.wav", wav_io.read()),
                    model="whisper-large-v3",
                    language="tr"
                )
                algilanan_metin = transcription.text.strip()
            else:
                print("[STT] Yerel Whisper çalışıyor...")
                segments, _ = stt_model.transcribe(
                    tam_ses,
                    language="tr",
                    beam_size=5,
                    vad_filter=True,
                    vad_parameters=dict(min_silence_duration_ms=400)
                )
                algilanan_metin = " ".join([s.text for s in segments]).strip()

            print(f"[Algılandı]: '{algilanan_metin}'")

            if algilanan_metin:
                self.yeniMesajEkle.emit("user", algilanan_metin)
                self.cevapGeldi.emit(f"Siz: {algilanan_metin}")
                self._llm_sorgula(algilanan_metin)
            else:
                self.durumDegisti.emit("hazir")
        except Exception as e:
            print(f"[STT Hatası]: {e}")
            self.durumDegisti.emit("hazir")

    def _cumleyi_kuyruga_at(self, metin, ses_kuyrugu):
        try:
            temiz = metin.replace('"', '').replace("'", "").replace("\n", " ").strip()
            if not temiz:
                return

            if self._piper_mod and piper_voice:
                wav_io = io.BytesIO()
                with wave.open(wav_io, "wb") as wav_file:
                    piper_voice.synthesize_wav(temiz, wav_file)
                wav_io.seek(0)
                sr, data = scipy.io.wavfile.read(wav_io)
                ses_kuyrugu.put((data, sr))
            elif tts_model:
                temiz = re.sub(r'([ıiuü])r\b', r'\1r ', temiz)
                torch.manual_seed(7)
                inputs = tts_tokenizer(temiz, return_tensors="pt")
                with torch.inference_mode():
                    output = tts_model(**inputs, noise_scale=0.3, noise_scale_dp=0.0).waveform
                ses_kuyrugu.put((output[0].cpu().numpy(), tts_model.config.sampling_rate))
        except Exception as e:
            print(f"Parça sentez hatası: {e}")

    def _llm_sorgula(self, prompt):
        try:
            payload = {
                "model": MODEL_NAME,
                "prompt": prompt,
                "stream": True,
                "options": {"temperature": 0.7, "num_ctx": 4096}
            }
            response = requests.post(OLLAMA_URL, json=payload, stream=True, timeout=60)

            tam_cevap = ""
            cumle_tamponu = ""

            self.yeniMesajEkle.emit("asistan", "")

            ses_kuyrugu = queue.Queue()

            def ses_oynatici():
                while True:
                    item = ses_kuyrugu.get()
                    if item is None:
                        break
                    data, sr = item
                    sd.play(data, samplerate=sr)
                    sd.wait()
                    ses_kuyrugu.task_done()

            oynatici_thread = threading.Thread(target=ses_oynatici, daemon=True)
            oynatici_thread.start()

            for line in response.iter_lines():
                if line:
                    chunk = json.loads(line.decode("utf-8"))
                    kelime = chunk.get("response", "")
                    tam_cevap += kelime
                    cumle_tamponu += kelime

                    self.mesajGuncelle.emit(tam_cevap)

                    # --- GÜNCELLENEN YER (BURASI): Sadece Sessiz (2) Değilse Seslendir ---
                    if self._tts_mod != 2 and re.search(r'[.!?\n]', kelime) and len(cumle_tamponu.strip()) > 2:
                        self._cumleyi_kuyruga_at(cumle_tamponu.strip(), ses_kuyrugu)
                        cumle_tamponu = ""

            # --- DÖNGÜ BİTİMİNDEKİ SON KONTROL ---
            if self._tts_mod != 2 and cumle_tamponu.strip():
                self._cumleyi_kuyruga_at(cumle_tamponu.strip(), ses_kuyrugu)

            self.cevapGeldi.emit(tam_cevap)
            ses_kuyrugu.put(None)
            oynatici_thread.join()
            self.durumDegisti.emit("hazir")

        except Exception as e:
            print(f"Hata: {e}")
            self.mesajGuncelle.emit(f"Hata: {str(e)}")
            self.durumDegisti.emit("hazir")

    @Slot(str)
    def mesajGonder(self, metin):
        self.durumDegisti.emit("dinliyor")
        self.yeniMesajEkle.emit("user", metin)
        threading.Thread(target=self._llm_sorgula, args=(metin,), daemon=True).start()


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    kopru = AsistanKoprusu()
    engine.rootContext().setContextProperty("asistan", kopru)
    engine.load("arayuz.qml")
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
