from fastapi import HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.settings import settings

# Endpoint yang sudah memiliki proteksi CSRF sendiri (OAuth state)
CSRF_EXEMPT_PATHS = {
    "/v1/auth/google",
    "/v1/auth/refresh",
    "/v1/auth/logout",
    "/",
}

# Hanya method state-changing yang perlu proteksi CSRF
CSRF_PROTECTED_METHODS = {"POST", "PUT", "DELETE", "PATCH"}


class CSRFMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path in CSRF_EXEMPT_PATHS:
            return await call_next(request)

        if request.method not in CSRF_PROTECTED_METHODS:
            return await call_next(request)

        allowed_origins = [settings.FRONTEND_URL]
        if settings.APP_ENV == "development":
            allowed_origins.extend([
                f"http://localhost:{settings.PORT}",
                f"http://127.0.0.1:{settings.PORT}",
            ])

        origin = request.headers.get("origin")
        referer = request.headers.get("referer")

        if origin:
            if origin not in allowed_origins:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Invalid origin",
                )
        elif referer:
            if not any(referer.startswith(allowed) for allowed in allowed_origins):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Invalid referer",
                )
        else:
            if settings.APP_ENV == "production":
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Missing origin or referer headers",
                )

        return await call_next(request)


def setup_csrf(app):
    app.add_middleware(CSRFMiddleware)