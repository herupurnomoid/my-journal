from fastapi import APIRouter
from app.api.auth.views import auth_router
from app.api.ai.views import ai_router
from app.api.journals.views import journal_router
from app.api.notifications.views import router as notifications_router

api_router = APIRouter()

# Daftarkan router pengguna di bawah prefix /auth
api_router.include_router(auth_router, prefix="/auth", tags=["Authentication"])
api_router.include_router(ai_router, prefix="/ai")
api_router.include_router(journal_router, prefix="/journals")
api_router.include_router(notifications_router)
