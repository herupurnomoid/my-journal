import random
import jwt
from datetime import datetime, timedelta, timezone
from fastapi import HTTPException, status
from app.api.auth.repositories import AuthRepository
from app.services.email.sender import EmailService
from app.settings import settings

class AuthUseCases:
    @staticmethod
    def forgot_pin(email: str) -> str:
        """
        Memproses permintaan lupa PIN, menghasilkan OTP,
        menyimpannya di Firestore, dan mengirimkannya via email.
        """
        user = AuthRepository.get_user_by_email(email)
        if not user:
            # Cegah enumerasi email: tetap berikan pesan sukses walau email tak terdaftar
            return "Jika email Anda terdaftar, kode OTP telah dikirimkan."

        user_id = user.get("uid")
        
        # 1. Generate 6 digit OTP
        otp_code = str(random.randint(100000, 999999))
        
        # 2. Simpan OTP ke Firestore
        AuthRepository.save_otp_to_firestore(user_id, otp_code)
        
        # 3. Mengirim email SMTP menggunakan Email Service terpusat
        EmailService.send_otp_email(email, otp_code)
        
        return "Jika email Anda terdaftar, kode OTP telah dikirimkan."

    @staticmethod
    def verify_otp(email: str, otp_code: str) -> str:
        """
        Memvalidasi OTP dan mengembalikan token JWT sementara untuk reset PIN.
        """
        user = AuthRepository.get_user_by_email(email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="OTP tidak valid atau kedaluwarsa"
            )
            
        user_id = user.get("uid")
        
        otp_doc_id = AuthRepository.get_valid_otp_doc(user_id, otp_code)
        if not otp_doc_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="OTP tidak valid atau kedaluwarsa"
            )
            
        # Tandai OTP sebagai telah digunakan
        AuthRepository.mark_otp_as_used(otp_doc_id)
        
        # Buat temporary JWT token
        payload = {
            "sub": user_id,
            "purpose": "pin_reset",
            "exp": datetime.now(timezone.utc) + timedelta(minutes=15)
        }
        reset_token = jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
        
        return reset_token
