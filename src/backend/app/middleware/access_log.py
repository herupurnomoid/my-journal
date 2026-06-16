import time
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from app.settings import settings

logger = logging.getLogger("access")

class AccessLogMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        response = await call_next(request)
        process_time = (time.time() - start_time) * 1000

        client_ip = request.client.host if request.client else "127.0.0.1"

        logger.info(
            f"{client_ip} - {request.method} {request.url.path} " 
            f"{response.status_code} - {process_time:.2f}ms"
        )

        return response

def setup_access_log(app):
    if settings.APP_ENV == "development":
        app.add_middleware(AccessLogMiddleware)