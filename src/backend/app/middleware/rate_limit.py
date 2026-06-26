import time
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from cachetools import TTLCache
from app.settings import settings

# Menggunakan cachetools sebagai pengganti Redis untuk Serverless
# Cache menyimpan request_count per IP. Max 10.000 IP (TTL 60 detik)
rate_limit_cache = TTLCache(maxsize=10000, ttl=60)

class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app):
        super().__init__(app)
        self.default_limit = 100
        self.default_window = 60
        
        self.strict_paths = {
            "/v1/auth": {"limit": 10, "window": 60},
            "/v1/journals/sync": {"limit": 20, "window": 60},
        }

    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host if request.client else "127.0.0.1"
        path = request.url.path

        limit = self.default_limit
        rate_limit_category = "global"

        for strict_path, config in self.strict_paths.items():
            if path.startswith(strict_path):
                limit = config["limit"]
                rate_limit_category = strict_path
                break

        key = f"{client_ip}:{rate_limit_category}"
        
        # Ambil nilai saat ini dan tambah 1
        current_count = rate_limit_cache.get(key, 0)
        
        if current_count >= limit:
            return JSONResponse(
                status_code=429,
                headers={
                    "Access-Control-Allow-Origin": settings.FRONTEND_URL,
                    "Access-Control-Allow-Credentials": "true",
                },
                content={
                    "success": False,
                    "data": None,
                    "error": {
                        "code": "RATE_LIMIT_EXCEEDED", 
                        "message": "Terlalu banyak permintaan. Silakan coba lagi nanti."
                    }
                },
            )
            
        rate_limit_cache[key] = current_count + 1

        return await call_next(request)

def setup_rate_limit(app):
    app.add_middleware(RateLimitMiddleware)