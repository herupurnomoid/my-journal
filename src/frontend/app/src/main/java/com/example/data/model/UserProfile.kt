package com.example.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.Exclude
import com.google.firebase.firestore.IgnoreExtraProperties
import com.google.firebase.firestore.PropertyName
import com.google.firebase.firestore.ServerTimestamp

@IgnoreExtraProperties
data class UserProfile(
    @get:Exclude val uid: String = "",
    val email: String = "",
    val name: String = "",
    val avatarUrl: String? = null,
    val pinHash: String? = null,
    @get:PropertyName("isPinEnabled")
    val isPinEnabled: Boolean = false,
    val reminderEnabled: Boolean = true,
    val reminderTime: String = "20:00",
    val fcmToken: String? = null,
    val lastActiveAt: Timestamp? = null,
    @ServerTimestamp val createdAt: Timestamp? = null,
    @ServerTimestamp val updatedAt: Timestamp? = null
)
