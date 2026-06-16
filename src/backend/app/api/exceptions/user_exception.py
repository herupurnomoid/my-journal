from fastapi import HTTPException, status

class InvalidGoogleTokenException(HTTPException):
    def __init__(self, detail: str = "Token Google tidak valid"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail
        )

class UserNotFoundException(HTTPException):
    def __init__(self, detail: str = "Pengguna tidak ditemukan"):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=detail
        )
