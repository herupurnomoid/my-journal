import sys
from werkzeug.test import EnvironBuilder
from werkzeug.test import run_wsgi_app
from sync_wsgi import SyncASGIMiddleware
from app.main import app

print("Wrapping app with SyncASGIMiddleware...")
wsgi_app = SyncASGIMiddleware(app)

print("Building environment...")
builder = EnvironBuilder(path='/', method='GET')
environ = builder.get_environ()

print("Running WSGI app...")
try:
    app_iter, status, headers = run_wsgi_app(wsgi_app, environ)
    print("Done!")
    print("Status:", status)
    print("Headers:", headers)
    body_bytes = b"".join(app_iter)
    print("Body:", body_bytes.decode())
except Exception as e:
    import traceback
    traceback.print_exc()
