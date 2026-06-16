from fastapi import FastAPI
from fastapi.responses import JSONResponse

from app.settings import settings
from app.api.main import api_router
from app.api.exceptions.global_exception import setup_global_exceptions

# Middlewares
from app.middleware.cors import setup_cors
from app.middleware.csrf import setup_csrf
from app.middleware.access_log import setup_access_log
from app.middleware.request_id import setup_request_id
from app.middleware.security_headers import setup_security_headers
from app.middleware.nonce import setup_nonce
from app.middleware.rate_limit import setup_rate_limit

app = FastAPI(
    title=settings.APP_NAME,
    description="Backend Serverless API for MyJournal",
    version="1.0.0",
)

# 1. Setup Exception Handlers (Global & Validation)
setup_global_exceptions(app)

# 2. Setup Middlewares (Urutan penting!)
# Middleware ditambahkan berurutan dan dieksekusi dari yang terakhir ditambahkan (LIFO untuk Call Next)
setup_rate_limit(app)         # Cek rate limit dulu
setup_nonce(app)              # Cek nonce untuk replay attack
setup_csrf(app)               # Proteksi CSRF
setup_cors(app)               # Konfigurasi CORS
setup_security_headers(app)   # Header keamanan tambahan
setup_access_log(app)         # Logging request time
setup_request_id(app)         # Inject X-Request-ID ke setiap request

# 3. Include API Routers
app.include_router(api_router, prefix="/api/v1")

@app.get("/", tags=["Health"])
async def root():
    return JSONResponse(
        content={
            "success": True, 
            "data": "MyJournal API Server is running", 
            "error": None
        }
    )
