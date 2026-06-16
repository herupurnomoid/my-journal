package com.example.data.repository

import android.net.Uri
import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.storage.FirebaseStorage
import kotlinx.coroutines.tasks.await
import java.util.UUID

class ImageStorageRepository {
    private val storage = FirebaseStorage.getInstance()
    private val TAG = "ImageStorageRepo"

    /**
     * Uploads an image Uri to Firebase Cloud Storage and returns the public Download URL.
     * Path: users/{uid}/images/{uuid}.jpg
     */
    suspend fun uploadImage(localUri: Uri): String? {
        val uid = FirebaseAuth.getInstance().currentUser?.uid
        if (uid == null) {
            Log.e(TAG, "Cannot upload image: User not logged in.")
            return null
        }

        return try {
            val fileName = "${UUID.randomUUID()}.jpg"
            val storageRef = storage.reference.child("users/$uid/images/$fileName")

            Log.d(TAG, "Starting upload for $localUri to ${storageRef.path}")
            
            // Upload the file
            val uploadTask = storageRef.putFile(localUri).await()
            Log.d(TAG, "Upload complete. Bytes transferred: ${uploadTask.bytesTransferred}")

            // Get the download URL
            val downloadUrl = storageRef.downloadUrl.await()
            Log.d(TAG, "Download URL retrieved: $downloadUrl")
            
            downloadUrl.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to upload image: $localUri", e)
            null
        }
    }
}
