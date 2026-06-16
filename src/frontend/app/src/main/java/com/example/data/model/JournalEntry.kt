package com.example.data.model

import java.io.Serializable

/**
 * JournalEntry serves as a Firestore document model (cloud source of truth).
 *
 * Firestore fields: firestoreId (document ID), createdAt, updatedAt
 */
data class JournalEntry(
    val id: Int = 0, // Legacy local ID, safe to ignore now
    val firestoreId: String = "",  // Firestore document ID
    val title: String = "",
    val content: String = "",
    val userMood: String = "",     // e.g., "😀 Bahagia", "😌 Tenang"
    val date: String = "",
    val timestamp: Long = System.currentTimeMillis(),
    val location: String = "Jakarta, Indonesia",
    val photoUri: String? = null,  // Local URI (camera/gallery)
    val photoUrl: String? = null,  // Firebase Storage public URL

    // AI Analysis (populated by Backend response)
    val aiMoodPrimary: String? = null,
    val aiStressLevel: Int? = null,
    val aiHappinessLevel: Int? = null,
    val aiEmotionSummary: String? = null,
    val aiRecommendations: String? = null, // Pipe-delimited for Room, Array for Firestore

    // Sync Status (Room only)
    val isSynced: Boolean = false,
    val lastSyncTime: Long = System.currentTimeMillis(),

    // Draft Status
    val isDraft: Boolean = false,

    // Firestore Timestamps (stored as Long epoch millis for Room compatibility)
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) : Serializable {

    /**
     * Converts this JournalEntry into a Map suitable for Firestore document.
     * Excludes Room-only fields (id, isSynced, lastSyncTime).
     */
    fun toFirestoreMap(): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "title" to title,
            "content" to content,
            "userMood" to userMood,
            "date" to date,
            "timestamp" to timestamp,
            "location" to location,
            "photoUrl" to photoUrl,
            "aiMoodPrimary" to aiMoodPrimary,
            "aiStressLevel" to aiStressLevel,
            "aiHappinessLevel" to aiHappinessLevel,
            "aiEmotionSummary" to aiEmotionSummary,
            "isDraft" to isDraft,
            "updatedAt" to com.google.firebase.Timestamp.now()
        )
        // Store recommendations as List<String> in Firestore
        if (aiRecommendations != null) {
            map["aiRecommendations"] = aiRecommendations.split("|").filter { it.isNotBlank() }
        }
        return map
    }

    companion object {
        /**
         * Creates a JournalEntry from a Firestore document snapshot map.
         */
        fun fromFirestore(docId: String, data: Map<String, Any?>): JournalEntry {
            // Handle aiRecommendations: Firestore stores as List<String>, Room stores pipe-delimited
            val recsRaw = data["aiRecommendations"]
            val recsString = when (recsRaw) {
                is List<*> -> recsRaw.filterIsInstance<String>().joinToString("|")
                is String -> recsRaw
                else -> null
            }

            // Handle timestamps: could be Firebase Timestamp or Long
            val createdAtRaw = data["createdAt"]
            val updatedAtRaw = data["updatedAt"]
            val createdAtMs = when (createdAtRaw) {
                is com.google.firebase.Timestamp -> createdAtRaw.toDate().time
                is Long -> createdAtRaw
                is Number -> createdAtRaw.toLong()
                else -> System.currentTimeMillis()
            }
            val updatedAtMs = when (updatedAtRaw) {
                is com.google.firebase.Timestamp -> updatedAtRaw.toDate().time
                is Long -> updatedAtRaw
                is Number -> updatedAtRaw.toLong()
                else -> System.currentTimeMillis()
            }

            return JournalEntry(
                firestoreId = docId,
                title = data["title"] as? String ?: "",
                content = data["content"] as? String ?: "",
                userMood = data["userMood"] as? String ?: "",
                date = data["date"] as? String ?: "",
                timestamp = (data["timestamp"] as? Number)?.toLong() ?: System.currentTimeMillis(),
                location = data["location"] as? String ?: "",
                photoUrl = data["photoUrl"] as? String,
                aiMoodPrimary = data["aiMoodPrimary"] as? String,
                aiStressLevel = (data["aiStressLevel"] as? Number)?.toInt(),
                aiHappinessLevel = (data["aiHappinessLevel"] as? Number)?.toInt(),
                aiEmotionSummary = data["aiEmotionSummary"] as? String,
                aiRecommendations = recsString,
                isDraft = data["isDraft"] as? Boolean ?: false,
                isSynced = true,
                createdAt = createdAtMs,
                updatedAt = updatedAtMs
            )
        }
    }
}
