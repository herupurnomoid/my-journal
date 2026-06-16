from typing import Generic, TypeVar, Optional
from pydantic import BaseModel

T = TypeVar("T")


class ErrorDetail(BaseModel):
    code: str
    message: str
    request_id: Optional[str] = None


class StandardResponse(BaseModel, Generic[T]):
    success: bool
    data: Optional[T] = None
    error: Optional[ErrorDetail] = None


def success_response(data):
    return {
        "success": True,
        "data": data,
        "error": None,
    }


def error_response(code: str, message: str, request_id: str | None = None):
    return {
        "success": False,
        "data": None,
        "error": {
            "code": code,
            "message": message,
            "request_id": request_id,
        },
    }