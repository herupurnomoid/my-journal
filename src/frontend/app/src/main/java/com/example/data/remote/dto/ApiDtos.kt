package com.example.data.remote.dto

import com.squareup.moshi.JsonClass

// Base Standard Response matching Backend StandardResponse model
@JsonClass(generateAdapter = true)
data class StandardResponse<T>(
    val success: Boolean,
    val message: String? = null,
    val error: String? = null,
    val data: T? = null
)

// ------------------------------------------------------------------
// Auth DTOs
// ------------------------------------------------------------------

@JsonClass(generateAdapter = true)
data class ForgotPinRequest(
    val email: String
)

@JsonClass(generateAdapter = true)
data class VerifyOtpRequest(
    val email: String,
    val otpCode: String
)

@JsonClass(generateAdapter = true)
data class VerifyOtpResponse(
    val resetToken: String
)

// ------------------------------------------------------------------
// AI DTOs
// ------------------------------------------------------------------

@JsonClass(generateAdapter = true)
data class AnalyzeMoodRequest(
    val title: String,
    val content: String
)

@JsonClass(generateAdapter = true)
data class AnalyzeMoodResponse(
    val primaryMood: String,
    val stressLevel: Int,
    val happinessLevel: Int,
    val emotionSummary: String,
    val recommendations: List<String>
)

@JsonClass(generateAdapter = true)
data class JournalTextDto(
    val title: String,
    val content: String
)

@JsonClass(generateAdapter = true)
data class WeeklyInsightRequest(
    val journals: List<JournalTextDto>
)

@JsonClass(generateAdapter = true)
data class WeeklyInsightResponse(
    val weeklySummary: String
)

// ------------------------------------------------------------------
// Export DTOs
// ------------------------------------------------------------------

@JsonClass(generateAdapter = true)
data class ExportPdfResponse(
    val downloadUrl: String
)
