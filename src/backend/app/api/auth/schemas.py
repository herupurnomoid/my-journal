from pydantic import BaseModel, EmailStr

class ForgotPinRequest(BaseModel):
    email: EmailStr

class VerifyOTPRequest(BaseModel):
    email: EmailStr
    otpCode: str

class VerifyOTPResponse(BaseModel):
    resetToken: str
