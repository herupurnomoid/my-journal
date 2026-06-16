package com.example.data.repository

import android.content.Context
import android.util.Log
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import kotlinx.coroutines.tasks.await
import com.example.data.remote.ApiClient
import com.example.data.remote.dto.ForgotPinRequest
import com.example.data.remote.dto.VerifyOtpRequest

class AuthRepository {
    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
    private val api = ApiClient.apiService

    val currentUser: FirebaseUser?
        get() = auth.currentUser

    suspend fun signInWithGoogle(context: Context, serverClientId: String): AuthResult? {
        if (serverClientId.isEmpty()) {
            Log.e("AuthRepository", "Server Client ID is empty! Please check your .env file or build configuration.")
            throw Exception("Google Sign-In configuration error: Empty Server Client ID")
        }
        try {
            val credentialManager = CredentialManager.create(context)
            
            // Build the option for Google ID
            val googleIdOption: GetGoogleIdOption = GetGoogleIdOption.Builder()
                .setFilterByAuthorizedAccounts(false)
                .setServerClientId(serverClientId)
                .setAutoSelectEnabled(false) // Dimatikan agar selalu memunculkan dialog (lebih aman untuk testing awal)
                .build()

            // Request the credential
            val request: GetCredentialRequest = GetCredentialRequest.Builder()
                .addCredentialOption(googleIdOption)
                .build()

            val result = credentialManager.getCredential(
                request = request,
                context = context,
            )
            
            val credential = result.credential

            // If it's a Google ID Token Credential
            if (credential is CustomCredential && credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
                
                // Pass it to Firebase
                val firebaseCredential = GoogleAuthProvider.getCredential(googleIdTokenCredential.idToken, null)
                
                val authResult = auth.signInWithCredential(firebaseCredential).await()
                val user = authResult.user
                if (user != null) {
                    UserRepository().syncUserProfile(user)
                }
                return authResult
            }
            return null

        } catch (e: GetCredentialException) {
            Log.e("AuthRepository", "Failed to get Google Credential", e)
            throw e
        } catch (e: Exception) {
            Log.e("AuthRepository", "Failed to sign in with Google", e)
            throw e
        }
    }

    suspend fun signInAnonymously(): AuthResult? {
        try {
            val authResult = auth.signInAnonymously().await()
            val user = authResult.user
            if (user != null) {
                UserRepository().syncUserProfile(user)
            }
            return authResult
        } catch (e: Exception) {
            Log.e("AuthRepository", "Failed to sign in anonymously", e)
            throw e
        }
    }

    fun signOut() {
        auth.signOut()
    }

    suspend fun forgotPin(email: String): Result<String> {
        return try {
            val response = api.forgotPin(ForgotPinRequest(email))
            if (response.isSuccessful) {
                val body = response.body()
                if (body != null && body.success) {
                    Result.success(body.data ?: "OTP Terkirim")
                } else {
                    Result.failure(Exception(body?.message ?: "Unknown error"))
                }
            } else {
                Result.failure(Exception("HTTP Error: ${response.code()}"))
            }
        } catch (e: Exception) {
            Log.e("AuthRepository", "forgotPin failed", e)
            Result.failure(e)
        }
    }

    suspend fun verifyPinOtp(email: String, otpCode: String): Result<String> {
        return try {
            val response = api.verifyPinOtp(VerifyOtpRequest(email, otpCode))
            if (response.isSuccessful) {
                val body = response.body()
                if (body != null && body.success && body.data != null) {
                    Result.success(body.data.resetToken)
                } else {
                    Result.failure(Exception(body?.message ?: "Invalid OTP"))
                }
            } else {
                Result.failure(Exception("HTTP Error: ${response.code()}"))
            }
        } catch (e: Exception) {
            Log.e("AuthRepository", "verifyPinOtp failed", e)
            Result.failure(e)
        }
    }
}
