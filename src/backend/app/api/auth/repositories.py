import hashlib
from datetime import datetime, timedelta, timezone
from app.connections.firebase import get_firestore_client

class AuthRepository:
    @staticmethod
    def get_user_by_email(email: str) -> dict | None:
        from app.connections.firebase import get_auth_client
        auth_client = get_auth_client()
        try:
            user_record = auth_client.get_user_by_email(email)
            return {"uid": user_record.uid, "email": user_record.email}
        except Exception:
            return None

    @staticmethod
    def save_otp_to_firestore(user_id: str, otp_code: str) -> None:
        """
        Menyimpan hash kode OTP ke koleksi otp_tokens di Firestore.
        """
        db = get_firestore_client()
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=5)
        otp_hash = hashlib.sha256(otp_code.encode('utf-8')).hexdigest()
        
        db.collection("otp_tokens").add({
            "userId": user_id,
            "otpCode": otp_hash,
            "expiresAt": expires_at,
            "isUsed": False,
            "createdAt": datetime.now(timezone.utc)
        })

    @staticmethod
    def get_valid_otp_doc(user_id: str, otp_code: str) -> str | None:
        """
        Mencari dan memvalidasi OTP. Mengembalikan Document ID jika valid dan belum kedaluwarsa.
        """
        db = get_firestore_client()
        otp_hash = hashlib.sha256(otp_code.encode('utf-8')).hexdigest()
        
        query = db.collection("otp_tokens")\
            .where("userId", "==", user_id)\
            .where("isUsed", "==", False)\
            .get()
            
        now = datetime.now(timezone.utc)
        
        for doc in query:
            data = doc.to_dict()
            if data.get("otpCode") == otp_hash:
                expires_at = data.get("expiresAt")
                if expires_at and expires_at > now:
                    return doc.id
        return None

    @staticmethod
    def mark_otp_as_used(doc_id: str) -> None:
        """Tandai OTP sebagai telah digunakan."""
        db = get_firestore_client()
        db.collection("otp_tokens").document(doc_id).update({
            "isUsed": True,
            "updatedAt": datetime.now(timezone.utc)
        })
