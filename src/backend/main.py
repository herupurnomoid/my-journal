from firebase_functions import https_fn
from sync_wsgi import SyncASGIMiddleware
from app.main import app

# Wrap the FastAPI application in a synchronous WSGI middleware
wsgi_app = SyncASGIMiddleware(app)

# Expose the API function to Firebase Functions
@https_fn.on_request(
    region="asia-southeast2",
    cpu=1,
    memory=256,
)
def api(req: https_fn.Request) -> https_fn.Response:
    import sys
    
    # In Firebase Functions, the first "/api" acts as the function name trigger,
    # leaving only "/v1/..." as PATH_INFO. Since FastAPI now uses "/v1" as router prefix,
    # we don't need to rewrite the PATH_INFO anymore.
    path_info = req.environ.get('PATH_INFO', '')
        
    print(f"DEBUG: Received request: {req.method} {req.path}", file=sys.stderr)
    print(f"DEBUG: req.environ PATH_INFO: {req.environ.get('PATH_INFO')}", file=sys.stderr)
    print(f"DEBUG: req.environ SCRIPT_NAME: {req.environ.get('SCRIPT_NAME')}", file=sys.stderr)
    
    try:
        print("DEBUG: Executing WSGI app...", file=sys.stderr)
        resp = https_fn.Response.from_app(wsgi_app, req.environ)
        print(f"DEBUG: WSGI app execution finished with status {resp.status_code}", file=sys.stderr)
        return resp
    except Exception as e:
        import traceback
        print("DEBUG: Exception during WSGI app execution:", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
        return https_fn.Response("Internal Server Error", status=500)

