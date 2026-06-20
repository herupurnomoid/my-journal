from fastapi import HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from cachetools import TTLCache
from app.settings import settings

NONCE_TTL_SECONDS = 300  # 5 menit

EXEMPT_PATHS = {
    "/v1/auth/google",
    "/v1/auth/refresh",
    "/v1/auth/logout",
    "/",
}

PROTECTED_METHODS = {"POST", "PUT", "DELETE", "PATCH"}

# Menggunakan in-memory cache pengganti Redis. Max 10.000 nonce aktif.
nonce_cache = TTLCache(maxsize=10000, ttl=NONCE_TTL_SECONDS)

class NonceMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if settings.APP_ENV == "development" or request.url.path in EXEMPT_PATHS:
            return await call_next(request)

        if request.method not in PROTECTED_METHODS:
            return await call_next(request)

        nonce = request.headers.get("X-Request-Nonce")
        if not nonce:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="X-Request-Nonce header is required for non-idempotent requests",
            )

        if nonce in nonce_cache:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Replay attack detected: duplicate nonce",
            )

        # Simpan nonce ke in-memory cache
        nonce_cache[nonce] = True

        response = await call_next(request)
        response.headers["X-Request-Nonce"] = nonce
        return response


def setup_nonce(app):
    app.add_middleware(NonceMiddleware)