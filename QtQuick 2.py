import os
import sys
import json
import re
import queue
import threading
import io
import wave
import psutil
import subprocess
import time
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
from dotenv import load_dotenv
import difflib

# .env dosyasındaki değişkenleri otomatik sisteme yükler
load_dotenv()

os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
torch.set_num_threads(os.cpu_count() or 4)

from PySide6.QtCore import QObject, Signal, Slot, Property
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
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
SOHBETLER_DOSYASI = Path.home() / ".plak_ai_sohbetler.json"

class AsistanKoprusu(QObject):
    cevapGeldi = Signal(str)
    yeniMesajEkle = Signal(str, str)
    mesajGuncelle = Signal(str)
    durumDegisti = Signal(str)
    duvarKagidiDegisti = Signal()
    modDegisti = Signal()
    ttsModDegisti = Signal()
    metriklerGuncellendi = Signal(float, float, float, float) # cpu, ram_veya_vram, audio, threads
    gecmisYuklendi = Signal(str) # QML'e JSON aktarımı için

    def _arac_calistir(self, eylem, hedef, son_kullanici_mesaji=""):
        # Model saçmalayıp hedefi boş geçerse veya geri_try derse
        if not hedef or eylem == "geri_try":
            hedef = son_kullanici_mesaji

        uygulama_eslesmeleri = {
            "dosya yöneticisi": "dolphin",
            "klasör": "dolphin",
            "klasörler": "dolphin",
            "belgeler": "dolphin",
            "terminal": "konsole",
            "konsol": "konsole",
            "bash": "konsole",
            "tarayıcı": "firefox",
            "internet": "firefox",
            "google": "firefox",
            "youtube": "firefox",
            "hesap makinesi": "kcalc"
        }

        hedef_temiz = hedef.replace("_", " ").lower().strip()

        # Doğrudan metin içinde anahtar kelime var mı bak (örn: "klasörlerimi görmek istiyorum")
        komut = None
        for anahtar, app_komut in uygulama_eslesmeleri.items():
            if anahtar in hedef_temiz:
                komut = app_komut
                break

        # Bulamadıysa fuzzy dene
        if not komut:
            eslesenler = difflib.get_close_matches(hedef_temiz, uygulama_eslesmeleri.keys(), n=1, cutoff=0.5)
            if eslesenler:
                komut = uygulama_eslesmeleri[eslesenler[0]]
            else:
                komut = hedef_temiz

        try:
            subprocess.Popen([komut])
            print(f"[ARAÇ ÇALIŞTI]: {komut} arka planda fırlatıldı.")
            return f"{komut} uygulamasını açtım."
        except Exception as e:
            print(f"[ARAÇ HATASI]: {e}")
            return f"Uygulama başlatılamadı."
        return ""
            # örn: "hesap makinesi": "kcalc" (veya gnome-calculator/calc)
            # "tarayıcı": "firefox"
            # subprocess.Popen([komut]) ile arka planda pencereyi açtır


    def _metrik_timer_baslat(self):
        def loop():
            while True:
                time.sleep(2)
                cpu = psutil.cpu_percent() / 100.0
                threads = min(1.0, len(psutil.Process().threads()) / 20.0)
                
                # VRAM okumayı dene (nvidia-smi), yoksa RAM yüzdesi al
                vram_val = 0.5
                try:
                    out = subprocess.check_output(["nvidia-smi", "--query-gpu=memory.used,memory.total", "--format=csv,nounits,noheader"]).decode()
                    used, total = map(float, out.strip().split(","))
                    vram_val = used / total
                except Exception:
                    vram_val = psutil.virtual_memory().percent / 100.0

                self.metriklerGuncellendi.emit(cpu, vram_val, 0.35, threads)

        threading.Thread(target=loop, daemon=True).start()
    def __init__(self):
        super().__init__()
        # Sisteme asistan kimliği veriyoruz:
        self._tum_sohbetler = self._diskten_sohbetleri_oku()
        self._aktif_sohbet_id = "Sohbet 1"
        if "Sohbet 1" not in self._tum_sohbetler:
            self._tum_sohbetler["Sohbet 1"] = []
        klasor = Path.home() / "Masaüstü" / "my wallpaper trials"
        gecerli_uzantilar = {".jpg", ".jpeg", ".png", ".webp"}

        self._duvar_kagitlari = [""]
        if klasor.exists():
            for dosya in klasor.iterdir():
                if dosya.suffix.lower() in gecerli_uzantilar:
                    self._duvar_kagitlari.append(f"file://{dosya.resolve()}")
        self._metrik_timer_baslat()
        self._index = 0
        self._kayit_suruyor = False
        self._ses_bloklari = []
        self._stream = None
        
        self._online_mod = True
        self._piper_mod = True

# _piper_mod yerine 3 durumlu tts modu (0: Piper, 1: Meta, 2: Sessiz)
        self._tts_mod = 0  # 0: Piper, 1: Meta, 2: Sessiz/Mute

    @Property(bool, notify=modDegisti)
    def onlineMod(self):
        return self._online_mod

    @onlineMod.setter
    def onlineMod(self, val):
        if self._online_mod != val:
            self._online_mod = val
            self.modDegisti.emit()
            print(f"[STT Modu]: {'ONLINE (Groq Cloud)' if val else 'OFFLINE (Yerel Whisper)'}")

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
    def sohbetiSifirla(self):
        self._tum_sohbetler[self._aktif_sohbet_id] = []
        self._diske_kaydet()

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
                    wav_file.setnchannels(1)        # 1 Kanal (Mono)
                    wav_file.setsampwidth(2)        # 16-bit (2 byte)
                    wav_file.setframerate(piper_voice.config.sample_rate) # Modelin frekansı
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


    def _diskten_sohbetleri_oku(self):
        if SOHBETLER_DOSYASI.exists():
            try:
                with open(SOHBETLER_DOSYASI, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                print(f"[Hafıza Hatası]: {e}")
        return {}

    def _diske_kaydet(self):
        try:
            with open(SOHBETLER_DOSYASI, "w", encoding="utf-8") as f:
                json.dump(self._tum_sohbetler, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"[Kayıt Hatası]: {e}")

    @Slot(str)
    def aktifSohbetiDegistir(self, sohbet_baslik):
        self._aktif_sohbet_id = sohbet_baslik
        if sohbet_baslik not in self._tum_sohbetler:
            self._tum_sohbetler[sohbet_baslik] = []

    @Slot(result=str)
    def sohbetleriGetirJson(self):
        return json.dumps(self._tum_sohbetler, ensure_ascii=False)
    
    def _llm_sorgula(self, prompt):
        seyyaptigimindegiskeni = """Sen Plak! AI masaüstü asistanısın.

GÖREV: Kullanıcı bir uygulama açmanı veya sisteme erişmeni isterse BAŞKA HİÇBİR ŞEY YAZMADAN sadece bu JSON'ı üret:
TOOL: {"eylem": "uygulama_ac", "hedef": "<uygulama_adi>"}
Bunun için sadece ama sadece _arac_calistir() json yöntemini kullan.
geri_try diye bir json yöntemi yok. bir daha denemek istiyorsan yine _arac_calistir() kullanacaksın.
Kesin Kurallar:
- "Açamam", "başlatılamadı", "kaynak yok" gibi bahaneler üretmek KESİNLİKLE YASAKTIR.
- google/internet/youtube denirse hedef "tarayıcı" olsun.
- dosya/klasör denirse hedef "dosya yöneticisi" olsun.
- terminal/konsol denirse hedef "terminal" olsun.
- Sohbet ediliyorsa normal Türkçe cevap ver."""
        try:
            # Kullanıcının mesajını geçmişe ekle
            aktif_liste = self._tum_sohbetler.get(self._aktif_sohbet_id, [])
            aktif_liste.append({"role": "user", "content": prompt})
            gonderilecek_mesajlar = [
            {"role": "system", "content":seyyaptigimindegiskeni}] + aktif_liste
            payload = {
                "model": MODEL_NAME,
                "messages": gonderilecek_mesajlar,
                "stream": True,
                "options": {
                    "temperature": 0.2,
                    "num_ctx": 32768  # Donanımı boğmadan geniş bir hafıza penceresi
                }
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
                    # /api/chat formatında parça 'message' -> 'content' içinde gelir
                    kelime = chunk.get("message", {}).get("content", "")
                    tam_cevap += kelime
                    cumle_tamponu += kelime

                    self.mesajGuncelle.emit(tam_cevap)

                    if "TOOL:" not in tam_cevap and self._tts_mod != 2 and re.search(r'[.!?\n]', kelime) and len(cumle_tamponu.strip()) > 2:
                        self._cumleyi_kuyruga_at(cumle_tamponu.strip(), ses_kuyrugu)
                        cumle_tamponu = ""
            print("--- MODELİN VERDİĞİ SAF CEVAP ---")
            print(tam_cevap)
            print("---------------------------------")
            # DÖNGÜ BİTTİ: Araç kontrolü tam burada yapılır
            arac_metni = None
            if "TOOL:" in tam_cevap:
                arac_metni = tam_cevap.split("TOOL:")[1].strip()
            elif "```json" in tam_cevap:
                arac_metni = tam_cevap.split("```json")[1].split("```")[0].strip()

            if arac_metni:
                try:
                    veri = json.loads(arac_metni)
                    eylem = veri.get("eylem")
                    hedef = veri.get("hedef")

                    bildirim = self._arac_calistir(eylem, hedef)
                    if bildirim:
                        tam_cevap = bildirim
                        self.mesajGuncelle.emit(bildirim)
                        if self._tts_mod != 2:
                            self._cumleyi_kuyruga_at(tam_cevap, ses_kuyrugu)
                except Exception as e:
                    print(f"[ARAÇ AYRIŞTIRMA HATASI]: {e}")
            elif self._tts_mod != 2 and cumle_tamponu.strip():
                self._cumleyi_kuyruga_at(cumle_tamponu.strip(), ses_kuyrugu)

            # Asistanın verdiği cevabı da geçmişe kaydet ki bir dahaki sefere hatırlasın
            aktif_liste.append({"role": "assistant", "content": tam_cevap})
            self._tum_sohbetler[self._aktif_sohbet_id] = aktif_liste
            self._diske_kaydet()

            self.cevapGeldi.emit(tam_cevap)
            ses_kuyrugu.put(None)
            oynatici_thread.join()
            self.durumDegisti.emit("hazir")

        except Exception as e:
            print(f"Hata: {e}")
            self.mesajGuncelle.emit(f"Hata: {str(e)}")
            self.durumDegisti.emit("hazir")

    def _niyet_kontrol(self, metin):
        temiz = metin.lower().strip()
        
        # 1. Klasör / Dosya niyetleri
        if any(kelime in temiz for kelime in ["klasör", "dosya", "belge"]):
            if any(eylem in temiz for eylem in ["aç", "göster", "bak", "gör", "listele"]):
                return "dosya yöneticisi"

        # 2. Terminal niyetleri
        if any(kelime in temiz for kelime in ["terminal", "konsol", "bash", "kod ekranı"]):
            if any(eylem in temiz for eylem in ["aç", "başlat", "gir"]):
                return "terminal"

        # 3. İnternet / Tarayıcı niyetleri
        if any(kelime in temiz for kelime in ["internet", "tarayıcı", "google", "youtube", "site"]):
            if any(eylem in temiz for eylem in ["aç", "gir", "bağlan", "başlat"]):
                return "tarayıcı"

        # 4. Genel standart kalıp (... aç, ... başlat)
        desen = r'(.*?)\s*(i|ı|u|ü|yi|yı|yu|yü)?\s*(aç|başlat|çalıştır|açsana|açar mısın)\b'
        eslesme = re.search(desen, temiz)
        if eslesme:
            hedef = eslesme.group(1).strip()
            return re.sub(r'(i|ı|u|ü|yi|yı|yu|yü)$', '', hedef).strip()

        return None

    @Slot(str)
    def mesajGonder(self, metin):
        self.durumDegisti.emit("dinliyor")
        self.yeniMesajEkle.emit("user", metin)

        # 1. Önce kapıdaki bekçiye sor: Bu bir sistem açma komutu mu?
        hedef = self._niyet_kontrol(metin)

        if hedef:
            # Sistem komutuysa LLM'e hiç gitme! Doğrudan aç.
            bildirim = self._arac_calistir("uygulama_ac", hedef)
            if bildirim:
                self.yeniMesajEkle.emit("asistan", bildirim)
                self.cevapGeldi.emit(bildirim)
                self.durumDegisti.emit("hazir")
                return

        # 2. Sistem komutu değilse (sohbetse) LLM'i uyandır
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