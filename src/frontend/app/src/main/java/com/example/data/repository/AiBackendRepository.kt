package com.example.data.repository

import android.util.Log
import com.example.data.remote.ApiClient
import com.example.data.remote.dto.*
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.tasks.await

class AiBackendRepository {
    private val TAG = "AiBackendRepo"
    private val api = ApiClient.apiService

    private suspend fun getAuthHeader(): String? {
        return try {
            val user = FirebaseAuth.getInstance().currentUser
            if (user != null) {
                val tokenResult = user.getIdToken(false).await()
                tokenResult.token?.let { "Bearer $it" }
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get auth token", e)
            null
        }
    }

    suspend fun analyzeMood(title: String, content: String): AnalyzeMoodResponse? {
        val authHeader = getAuthHeader()
        if (authHeader == null) {
            Log.e(TAG, "Auth header missing")
            return null
        }

        return try {
            val req = AnalyzeMoodRequest(title, content)
            val response = api.analyzeMood(authHeader, req)
            if (response.isSuccessful && response.body()?.success == true) {
                response.body()?.data
            } else {
                Log.e(TAG, "API Error: ${response.code()} - ${response.message()}")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception during analyzeMood", e)
            null
        }
    }

    suspend fun getWeeklyInsights(journals: List<JournalTextDto>): String? {
        val authHeader = getAuthHeader()
        if (authHeader == null) return null

        return try {
            val req = WeeklyInsightRequest(journals)
            val response = api.getWeeklyInsights(authHeader, req)
            if (response.isSuccessful && response.body()?.success == true) {
                response.body()?.data?.weeklySummary
            } else {
                Log.e(TAG, "API Error: ${response.code()} - ${response.message()}")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception during getWeeklyInsights", e)
            null
        }
    }

    suspend fun exportPdf(): String? {
        val authHeader = getAuthHeader()
        if (authHeader == null) return null

        return try {
            val response = api.exportJournals(authHeader)
            if (response.isSuccessful && response.body()?.success == true) {
                response.body()?.data?.downloadUrl
            } else {
                Log.e(TAG, "API Error: ${response.code()} - ${response.message()}")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception during exportPdf", e)
            null
        }
    }
}
