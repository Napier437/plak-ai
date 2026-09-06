import subprocess
from pathlib import Path
import re
class FileManager:
    def __init__(self):
        ev = Path.home()
        self.ozel_klasorler = {
            "indirilenler": ev / "İndirilenler",
            "downloads": ev / "İndirilenler",
            "masaüstü": ev / "Masaüstü",
            "desktop": ev / "Masaüstü",
            "belgeler": ev / "Belgeler",
            "resimler": ev / "Resimler",
            "müzik": ev / "Müzik",
            "videolar": ev / "Videolar",
            "ev": ev,
            "home": ev
        }

    def klasor_ac(self, hedef_ad: str):
        # 1. Eğer ev dizinindeki resimleri/dosyaları sorduysa klasörü değil listeyi dön
        hedef_temiz = hedef_ad.lower().strip()
        
        yol = self.ozel_klasorler.get(hedef_temiz, Path.home())
        try:
            # Dolphin'i verilen dizinde açar
            subprocess.Popen(["dolphin", str(yol)])
            return f"'{hedef_temiz.capitalize()}' dizini açıldı."
        except Exception as e:
            return f"Klasör açılamadı: {e}"

def dosya_bul_ve_ac(self, aranan_ifade: str):
        ev_dizini = Path.home()
        temiz_arama = aranan_ifade.lower().strip()

        # "limon jpg" yazıldıysa "limon.jpg" yap
        temiz_arama = re.sub(r'\s+(jpg|jpeg|png|svg|pdf|mp3|mp4|desktop)$', r'.\1', temiz_arama)

        # Uzantı ve anahtar kelimeyi ayır (örn: "javascript" ve ".pdf")
        uzanti = None
        for uzt in [".pdf", ".png", ".jpg", ".jpeg", ".svg", ".mp3", ".mp4", ".desktop"]:
            if uzt in temiz_arama:
                uzanti = uzt
                temiz_arama = temiz_arama.replace(uzt, "").strip()
                break

        print(f"[DOSYA ARANIYOR]: İfade='{temiz_arama}', Uzantı='{uzanti}'")

        bulunanlar = []
        for dosya in ev_dizini.rglob("*"):
            if any(p.startswith(".") for p in dosya.parts):
                continue
            if not dosya.is_file():
                continue

            ad_kucuk = dosya.name.lower()

            # 1. Tam eşleşme
            if temiz_arama == ad_kucuk:
                bulunanlar.insert(0, dosya)
                break

            # 2. İsim içinde geçiyor mu? (Örn: "JavaScript - The Good Parts.pdf")
            if temiz_arama in ad_kucuk:
                if uzanti:
                    if dosya.suffix.lower() == uzanti:
                        bulunanlar.append(dosya)
                else:
                    bulunanlar.append(dosya)

        if not bulunanlar:
            return f"'{aranan_ifade}' ile eşleşen bir dosya bulunamadı."

        hedef_dosya = bulunanlar[0]
        try:
            # .desktop dosyası ise doğrudan gtk-launch veya desktop-file-validate/çalıştırma
            if hedef_dosya.suffix == ".desktop":
                subprocess.Popen(["gtk-launch", hedef_dosya.stem])
            else:
                subprocess.Popen(["xdg-open", str(hedef_dosya)])
            return f"Dosya bulundu: {hedef_dosya.name}\n(Ekranda açıldı)"
        except Exception as e:
            return f"Dosya bulundu ({hedef_dosya.name}) fakat açılamadı: {e}"