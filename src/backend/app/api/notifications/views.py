from fastapi import APIRouter, Depends, HTTPException, Header, status
from app.api.notifications.use_cases import NotificationUseCases
from app.settings import settings

router = APIRouter(prefix="/notifications", tags=["Notifications"])

def verify_cron_token(x_cron_token: str = Header(None)):
    """
    Memverifikasi token statis untuk mengamankan endpoint cron.
    """
    # Untuk environment lokal, kita bisa mock atau pakai token dummy
    expected_token = "my-journal-cron-secret-2026"
    if x_cron_token != expected_token and settings.APP_ENV != "development":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized cron trigger"
        )
    return True

@router.post("/cron/inactive-users")
def trigger_inactive_users_notifications(is_valid: bool = Depends(verify_cron_token)):
    """
    Endpoint yang dipanggil oleh cron job eksternal secara berkala.
    Sistem akan mengecek pengguna yang inaktif selama > 48 jam dan mengirimkan notifikasi.
    """
    result = NotificationUseCases.process_inactive_users_notifications()
    return result
