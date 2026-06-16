import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
from app.settings import settings

class EmailService:
    """
    Layanan terpusat untuk mengirim email (SMTP).
    Mendukung pengiriman email berformat HTML menggunakan template.
    """
    
    @staticmethod
    def send_otp_email(receiver_email: str, otp_code: str) -> None:
        """Mengirim email OTP pemulihan PIN menggunakan template HTML."""
        if not settings.SMTP_USER or not settings.SMTP_PASS:
            print("⚠️ SMTP belum dikonfigurasi. Abaikan pengiriman email.")
            return

        # 1. Struktur utama adalah 'related' untuk menyertakan gambar inline
        msg = MIMEMultipart('related')
        msg['From'] = f"{settings.SMTP_FROM_NAME} <{settings.SMTP_USER}>"
        msg['To'] = receiver_email
        msg['Subject'] = "Kode OTP Pemulihan PIN MyJournal"

        # 2. Sub-struktur 'alternative' untuk Fallback Teks vs HTML
        msg_alternative = MIMEMultipart('alternative')
        msg.attach(msg_alternative)

        # 3. Fallback Plain Text
        text_body = f"""Halo,

Anda meminta pemulihan PIN untuk akun MyJournal.
Berikut adalah 6 digit kode OTP rahasia Anda: {otp_code}

Kode ini hanya berlaku selama 5 menit. Jangan berikan kode ini kepada siapa pun.

Salam,
Tim Keamanan MyJournal
"""
        part1 = MIMEText(text_body, 'plain')
        msg_alternative.attach(part1)

        # 4. Versi HTML yang Kaya Visual
        template_dir = os.path.join(os.path.dirname(__file__), 'templates')
        template_path = os.path.join(template_dir, 'otp_email.html')
        css_path = os.path.join(template_dir, 'styles.css')
        try:
            with open(template_path, 'r', encoding='utf-8') as f:
                html_template = f.read()
            with open(css_path, 'r', encoding='utf-8') as f:
                css_styles = f.read()
            
            # Menyisipkan CSS dan kode OTP ke dalam template HTML
            html_body = html_template.replace('/* CSS_STYLES_PLACEHOLDER */', css_styles)
            html_body = html_body.replace('{otp_code}', otp_code)
            part2 = MIMEText(html_body, 'html')
            msg_alternative.attach(part2)
            
            # 5. Memuat dan melampirkan gambar logo sebagai CID (Content-ID)
            logo_path = os.path.join(template_dir, 'assets', 'logo.png')
            if os.path.exists(logo_path):
                with open(logo_path, 'rb') as img_file:
                    img_data = img_file.read()
                image_part = MIMEImage(img_data, _subtype="png")
                # Penanda khusus untuk dipanggil di HTML via src="cid:myjournal_logo"
                image_part.add_header('Content-ID', '<myjournal_logo>')
                # Set inline tanpa 'filename' agar Gmail tidak melihatnya sebagai attachment klip
                image_part.add_header('Content-Disposition', 'inline')
                msg.attach(image_part)
            else:
                print("⚠️ File logo.png tidak ditemukan di folder assets.")
                
        except Exception as e:
            print(f"⚠️ Gagal membaca template HTML/Logo, melanjutkan dengan plain text. Error: {e}")

        # 6. Proses Pengiriman via SMTP
        try:
            server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT)
            server.starttls() # Mengenkripsi koneksi menjadi aman (TLS)
            server.login(settings.SMTP_USER, settings.SMTP_PASS)
            
            server.send_message(msg)
            server.quit()
            print(f"✅ Email OTP berhasil dikirim ke {receiver_email} (HTML support)")
        except Exception as e:
            print(f"❌ Gagal mengirim email: {e}")
