import asyncio
from io import BytesIO
from http.client import responses
from typing import Any, Callable, Iterable, List, Tuple

class SyncASGIMiddleware:
    """
    A simple, synchronous ASGI-to-WSGI middleware.
    Runs the ASGI application entirely on the main thread's event loop,
    which is safe and ideal for serverless environments (like AWS Lambda
    or Google Cloud Functions) where background threads are suspended.
    """
    def __init__(self, app: Any) -> None:
        self.app = app

    def __call__(self, environ: dict, start_response: Callable) -> Iterable[bytes]:
        # 1. Read input body
        body = environ.get("wsgi.input")
        if body:
            content_length = int(environ.get("CONTENT_LENGTH") or 0)
            body_bytes = body.read(content_length)
        else:
            body_bytes = b""

        # 2. Build ASGI headers
        headers = []
        for key, value in environ.items():
            if key.startswith("HTTP_"):
                header_name = key[5:].lower().replace("_", "-").encode("latin1")
                headers.append((header_name, value.encode("latin1")))
            elif key in ("CONTENT_TYPE", "CONTENT_LENGTH"):
                header_name = key.lower().replace("_", "-").encode("latin1")
                headers.append((header_name, value.encode("latin1")))

        # 3. Build path and query
        path = environ.get("PATH_INFO", "")
        query_string = environ.get("QUERY_STRING", "").encode("ascii")

        # 4. Build ASGI scope
        scope = {
            "type": "http",
            "asgi": {"version": "3.0", "spec_version": "2.3"},
            "http_version": "1.1",
            "method": environ["REQUEST_METHOD"],
            "path": path,
            "raw_path": path.encode("ascii"),
            "query_string": query_string,
            "headers": headers,
            "client": (environ.get("REMOTE_ADDR", "127.0.0.1"), int(environ.get("REMOTE_PORT") or 0)) if environ.get("REMOTE_ADDR") else None,
            "server": (environ.get("SERVER_NAME", "localhost"), int(environ.get("SERVER_PORT") or 80)) if environ.get("SERVER_NAME") else None,
        }

        # Response state
        response_status = 200
        response_headers: List[Tuple[str, str]] = []
        response_body: List[bytes] = []

        # ASGI receive channel
        receive_called = False
        async def receive() -> dict:
            nonlocal receive_called
            if not receive_called:
                receive_called = True
                return {
                    "type": "http.request",
                    "body": body_bytes,
                    "more_body": False
                }
            else:
                return {"type": "http.disconnect"}

        # ASGI send channel
        async def send(message: dict) -> None:
            nonlocal response_status, response_headers
            msg_type = message.get("type")
            if msg_type == "http.response.start":
                response_status = message["status"]
                response_headers = [
                    (k.decode("latin1"), v.decode("latin1"))
                    for k, v in message.get("headers", [])
                ]
            elif msg_type == "http.response.body":
                body_chunk = message.get("body", b"")
                if body_chunk:
                    response_body.append(body_chunk)

        # 5. Run the ASGI app in a fresh event loop
        loop = asyncio.new_event_loop()
        try:
            asyncio.set_event_loop(loop)
            loop.run_until_complete(self.app(scope, receive, send))
        finally:
            loop.close()

        # 6. Format status string and invoke start_response
        status_phrase = responses.get(response_status, "OK")
        status_str = f"{response_status} {status_phrase}"

        start_response(status_str, response_headers)
        return response_body
