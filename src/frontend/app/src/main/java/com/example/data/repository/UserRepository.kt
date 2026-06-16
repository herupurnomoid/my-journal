package com.example.data.repository

import android.util.Log
import com.example.data.model.UserProfile
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.tasks.await

class UserRepository {
    private val firestore = FirebaseFirestore.getInstance()
    private val usersCollection = firestore.collection("users")

    companion object {
        private const val TAG = "UserRepository"
    }

    @kotlinx.coroutines.ExperimentalCoroutinesApi
    private fun getAuthUidFlow(): Flow<String?> = callbackFlow {
        val auth = FirebaseAuth.getInstance()
        val listener = FirebaseAuth.AuthStateListener { 
            trySend(it.currentUser?.uid)
        }
        auth.addAuthStateListener(listener)
        awaitClose { auth.removeAuthStateListener(listener) }
    }

    /**
     * Syncs the user profile to Firestore after login.
     * - First login: creates the full document with createdAt.
     * - Subsequent logins: updates lastActiveAt, fcmToken, and updatedAt.
     */
    suspend fun syncUserProfile(user: FirebaseUser) {
        try {
            val docRef = usersCollection.document(user.uid)
            val snapshot = docRef.get().await()

            // Try to get FCM Token
            var fcmToken: String? = null
            try {
                fcmToken = FirebaseMessaging.getInstance().token.await()
            } catch (e: Exception) {
                Log.w(TAG, "Failed to get FCM token", e)
            }

            val now = Timestamp.now()

            if (!snapshot.exists()) {
                // First time login — create full profile with createdAt
                val profileData = hashMapOf<String, Any?>(
                    "email" to (user.email ?: ""),
                    "name" to (user.displayName ?: "New User"),
                    "avatarUrl" to user.photoUrl?.toString(),
                    "isPinEnabled" to false,
                    "reminderEnabled" to true,
                    "reminderTime" to "20:00",
                    "fcmToken" to fcmToken,
                    "lastActiveAt" to now,
                    "createdAt" to now,
                    "updatedAt" to now
                )
                docRef.set(profileData).await()
                Log.d(TAG, "Created new user profile for ${user.uid}")
            } else {
                // Existing user — update activity fields
                val updates = hashMapOf<String, Any>(
                    "lastActiveAt" to now,
                    "updatedAt" to now
                )
                if (fcmToken != null) {
                    updates["fcmToken"] = fcmToken
                }
                docRef.set(updates, SetOptions.merge()).await()
                Log.d(TAG, "Updated existing user profile for ${user.uid}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error syncing user profile", e)
        }
    }

    /**
     * Listens to real-time changes on the current user's profile document.
     * Firestore Offline Persistence ensures this works even without internet.
     */
    @kotlinx.coroutines.ExperimentalCoroutinesApi
    fun getUserProfileFlow(): Flow<UserProfile?> = getAuthUidFlow().flatMapLatest { uid ->
        if (uid == null) {
            flowOf(null)
        } else {
            callbackFlow {
                val docRef = usersCollection.document(uid)
                val listenerRegistration = docRef.addSnapshotListener { snapshot, error ->
                    if (error != null) {
                        Log.e(TAG, "Listen failed.", error)
                        trySend(null)
                        return@addSnapshotListener
                    }

                    if (snapshot != null && snapshot.exists()) {
                        val profile = snapshot.toObject(UserProfile::class.java)
                        if (profile != null) {
                            trySend(profile.copy(uid = uid))
                        } else {
                            trySend(null)
                        }
                    } else {
                        trySend(null)
                    }
                }

                awaitClose {
                    listenerRegistration.remove()
                }
            }
        }
    }

    /**
     * Updates a specific setting field in Firestore.
     * Always stamps updatedAt alongside the changed field.
     */
    suspend fun updateSetting(uid: String, field: String, value: Any) {
        try {
            val updates = hashMapOf(
                field to value,
                "updatedAt" to Timestamp.now()
            )
            usersCollection.document(uid).set(updates, SetOptions.merge()).await()
            Log.d(TAG, "Updated setting $field for user $uid")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update $field", e)
        }
    }

    /**
     * Updates multiple setting fields atomically in a single Firestore operation.
     * This prevents snapshot listeners from seeing intermediate states.
     */
    suspend fun updateSettings(uid: String, fields: Map<String, Any>) {
        try {
            val updates = HashMap<String, Any>(fields)
            updates["updatedAt"] = Timestamp.now()
            usersCollection.document(uid).set(updates, SetOptions.merge()).await()
            Log.d(TAG, "Updated settings ${fields.keys} for user $uid")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update settings ${fields.keys}", e)
        }
    }

    /**
     * Stamps lastActiveAt and updatedAt. Called from MainActivity.onResume().
     */
    suspend fun updateLastActive(uid: String) {
        try {
            val now = Timestamp.now()
            usersCollection.document(uid).set(
                mapOf(
                    "lastActiveAt" to now,
                    "updatedAt" to now
                ),
                SetOptions.merge()
            ).await()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update lastActiveAt", e)
        }
    }
}
