package com.example.data.remote

import com.example.data.remote.dto.*
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.Header
import retrofit2.http.POST

interface ApiService {

    // 1.1 Lupa PIN (Kirim OTP)
    @POST("auth/pin/forgot")
    suspend fun forgotPin(
        @Body request: ForgotPinRequest
    ): Response<StandardResponse<String>>

    // 1.2 Verifikasi OTP PIN
    @POST("auth/pin/verify-otp")
    suspend fun verifyPinOtp(
        @Body request: VerifyOtpRequest
    ): Response<StandardResponse<VerifyOtpResponse>>

    // 2.1 Analisis Mood Jurnal
    @POST("ai/analyze-mood")
    suspend fun analyzeMood(
        @Header("Authorization") authHeader: String,
        @Body request: AnalyzeMoodRequest
    ): Response<StandardResponse<AnalyzeMoodResponse>>

    // 2.2 Insight Emosi Mingguan
    @POST("ai/weekly-insights")
    suspend fun getWeeklyInsights(
        @Header("Authorization") authHeader: String,
        @Body request: WeeklyInsightRequest
    ): Response<StandardResponse<WeeklyInsightResponse>>

    // 3.1 Ekspor Data PDF
    @POST("journals/export")
    suspend fun exportJournals(
        @Header("Authorization") authHeader: String
    ): Response<StandardResponse<ExportPdfResponse>>
}
