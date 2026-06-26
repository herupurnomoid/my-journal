import uuid
import datetime
from fastapi import HTTPException
from firebase_admin import storage
from fpdf import FPDF
from app.settings import settings

class JournalUseCases:
    @staticmethod
    def export_to_pdf(user_id: str, journals: list) -> str:
        """
        Menghasilkan file PDF dari daftar jurnal dan mengunggahnya ke Firebase Storage.
        Mengembalikan Signed URL untuk mengunduh file.
        """
        # 1. Inisialisasi PDF
        pdf = FPDF()
        pdf.set_auto_page_break(auto=True, margin=15)
        pdf.add_page()
        
        # Header PDF
        pdf.set_font("helvetica", "B", 18)
        pdf.cell(0, 10, "MyJournal - Ekspor Pribadi", new_x="LMARGIN", new_y="NEXT", align="C")
        pdf.ln(10)
        
        # 2. Render setiap jurnal
        for idx, j in enumerate(journals, 1):
            # Menggunakan encode latin-1 replace untuk menghindari error karakter tak dikenal (seperti emoji rumit) 
            # pada font bawaan FPDF.
            title = j.title.encode('latin-1', 'replace').decode('latin-1')
            date_str = j.date.encode('latin-1', 'replace').decode('latin-1')
            mood_str = (j.userMood or "-").encode('latin-1', 'replace').decode('latin-1')
            content_str = j.content.encode('latin-1', 'replace').decode('latin-1')
            
            # Judul Jurnal
            pdf.set_font("helvetica", "B", 14)
            pdf.cell(0, 10, f"{idx}. {title}", new_x="LMARGIN", new_y="NEXT")
            
            # Tanggal & Mood
            pdf.set_font("helvetica", "I", 10)
            pdf.set_text_color(100, 100, 100)
            pdf.cell(0, 8, f"Tanggal: {date_str}  |  Mood: {mood_str}", new_x="LMARGIN", new_y="NEXT")
            pdf.set_text_color(0, 0, 0)
            
            # Isi Jurnal
            pdf.set_font("helvetica", "", 12)
            pdf.multi_cell(0, 8, content_str, new_x="LMARGIN", new_y="NEXT")
            pdf.ln(10)
            
        # Dapatkan byte array dari PDF
        pdf_bytes = bytes(pdf.output())
        
        # 3. Mengunggah ke Google/Firebase Cloud Storage
        try:
            bucket_name = settings.GOOGLE_STORAGE_BUCKET
            if not bucket_name:
                raise Exception("GOOGLE_STORAGE_BUCKET is not configured.")
                
            bucket = storage.bucket(bucket_name)
            file_name = f"exports/{user_id}/{uuid.uuid4().hex}.pdf"
            blob = bucket.blob(file_name)
            
            download_token = uuid.uuid4()
            blob.metadata = {"firebaseStorageDownloadTokens": str(download_token)}
            
            # Upload file
            blob.upload_from_string(pdf_bytes, content_type='application/pdf')
            
            # Construct Firebase Storage download URL
            import urllib.parse
            encoded_name = urllib.parse.quote(file_name, safe='')
            url = f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}/o/{encoded_name}?alt=media&token={download_token}"
            return url
            
        except Exception as e:
            print(f"Error Uploading PDF: {e}")
            raise HTTPException(status_code=500, detail="Gagal mengunggah file PDF ke Cloud Storage.")
