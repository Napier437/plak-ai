import re
import difflib
import subprocess
from pathlib import Path

class AppLauncher:
    def __init__(self):
        self.uygulamalar = {
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

    def niyet_kontrol(self, metin: str):
        temiz = metin.lower().strip()

        # 1. DOSYA BULMA / ARAMA (Öncelikli! Örn: steam.desktop, limon.jpg, limon jpg, js pdf)
        # Noktalı veya boşluklu uzantıları yakalar:
        dosya_eslesme = re.search(r'([a-zA-Z0-9_\-\.\[\]\(\)\s]+[\.\s](mp3|png|jpg|jpeg|svg|txt|pdf|mp4|desktop))\b', temiz)
        if dosya_eslesme:
            return ("dosya_ac", dosya_eslesme.group(1).strip())

        # "javascript ile alakalı pdf", "şu dosyayı bul" gibi doğal aramalar
        if any(k in temiz for k in ["pdf", "resim", "fotoğraf", "belge"]) and any(e in temiz for euffix in ["bul", "ara", "aç", "nerede"] for e in [euffix]):
            # Aramayı dosya modülüne yolla
            temiz_hedef = re.sub(r'(dosyası|dosyasını|ile alakalı|olan|bi|tane|aç|bul|nerede)\b', '', temiz).strip()
            return ("dosya_ac", temiz_hedef)

        # 2. ÖZEL KLASÖRLER (Sadece saf klasör taleplerinde çalışır)
        klasor_kelimeleri = ["indirilenler", "downloads", "masaüstü", "desktop", "belgeler", "resimler", "müzik", "videolar", "ev dizini"]
        for kl in klasor_kelimeleri:
            # Yanında uzantı yoksa ve klasör geçiyorsa
            if kl in temiz and not any(u in temiz for u in [".desktop", ".pdf", ".jpg", ".png"]):
                return ("klasor_ac", kl.replace(" dizini", ""))

        # 3. GENEL PROGRAMLAR
        if any(kelime in temiz for kelime in ["terminal", "konsol", "bash"]):
            return ("uygulama_ac", "terminal")

        if any(kelime in temiz for kelime in ["internet", "tarayıcı", "google", "youtube"]):
            return ("uygulama_ac", "tarayıcı")

        if "steam" in temiz:
            return ("uygulama_ac", "steam")

        # 4. Genel Regex (... aç, ... başlat)
        desen = r'(.*?)\s*(i|ı|u|ü|yi|yı|yu|yü)?\s*(aç|başlat|çalıştır|gir|açsana|açar mısın)\b'
        eslesme = re.search(desen, temiz)
        if eslesme:
            hedef = eslesme.group(1).strip()
            hedef_temiz = re.sub(r'(i|ı|u|ü|yi|yı|yu|yü)$', '', hedef).strip()
            return ("uygulama_ac", hedef_temiz)

        return None

        # Ev dizininde dosyayı ara (gizli klasörleri atlayarak)
        hedef_dosya = None
        for dosya in ev_dizini.rglob("*"):
            if any(parca.startswith(".") for parca in dosya.parts):
                continue
            if dosya.is_file() and dosya.name.lower() == dosya_adi.lower():
                hedef_dosya = dosya
                break

        if not hedef_dosya:
            return f"'{dosya_adi}' ev dizininde bulunamadı."

        try:
            # xdg-open: Dosyayı Linux'taki varsayılan programıyla açar
            subprocess.Popen(["xdg-open", str(hedef_dosya)])
            return f"'{hedef_dosya.name}' bulundu ve açıldı."
        except Exception as e:
            return f"Dosya açılamadı: {e}"
    def uygulama_ac(self, hedef: str, eylem="uygulama_ac", son_kullanici_mesaji=""):
        hedef_temiz = hedef.replace("_", " ").lower().strip()
        komut = None

        # 1. Doğrudan sözlükte ara ("tarayıcı" -> "firefox", "terminal" -> "konsole")
        for anahtar, app_komut in self.uygulamalar.items():
            if anahtar == hedef_temiz or anahtar in hedef_temiz:
                komut = app_komut
                break

        # 2. Yakın eşleşme ara (yazım hataları için)
        if not komut:
            eslesenler = difflib.get_close_matches(hedef_temiz, self.uygulamalar.keys(), n=1, cutoff=0.5)
            if eslesenler:
                komut = self.uygulamalar[eslesenler[0]]
            else:
                komut = hedef_temiz

        # 3. Komutu çalıştır
        try:
            subprocess.Popen([komut])
            print(f"[ARAÇ ÇALIŞTI]: {komut} başlatıldı.")
            return f"{komut} uygulamasını açtım."
        except Exception as e:
            print(f"[ARAÇ HATASI]: {e}")
            return f"{hedef.capitalize()} başlatılamadı."