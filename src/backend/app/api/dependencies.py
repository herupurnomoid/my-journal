from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.connections.firebase import get_auth_client
from app.settings import settings

security = HTTPBearer(auto_error=False)

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Memverifikasi Firebase ID Token dari header Authorization.
    Jika environment 'development', otomatis bypass dan kembalikan mock user
    agar mudah di-test lewat Swagger.
    """
    if settings.APP_ENV == "development":
        return {
            "uid": "dev-mock-uid-12345",
            "email": "dev@myjournal.com",
            "name": "Developer User"
        }
        
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Autentikasi diperlukan",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    token = credentials.credentials
    auth = get_auth_client()
    
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token autentikasi tidak valid atau sudah kedaluwarsa",
            headers={"WWW-Authenticate": "Bearer"},
        )
