from fastapi import APIRouter
from app.api.auth.schemas import ForgotPinRequest, VerifyOTPRequest, VerifyOTPResponse
from app.api.auth.use_cases import AuthUseCases
from app.api.standard_response import StandardResponse, success_response

auth_router = APIRouter()

@auth_router.post("/pin/forgot", response_model=StandardResponse[str])
async def forgot_pin(payload: ForgotPinRequest):
    """
    Endpoint untuk mengirimkan kode OTP Lupa PIN ke email pengguna.
    """
    message = AuthUseCases.forgot_pin(payload.email)
    return success_response(data=message)

@auth_router.post("/pin/verify-otp", response_model=StandardResponse[VerifyOTPResponse])
async def verify_otp(payload: VerifyOTPRequest):
    """
    Endpoint untuk memverifikasi OTP.
    """
    reset_token = AuthUseCases.verify_otp(payload.email, payload.otpCode)
    return success_response(data=VerifyOTPResponse(resetToken=reset_token))
