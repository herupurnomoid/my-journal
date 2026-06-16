package com.example.data.repository

import android.util.Log
import com.example.data.model.JournalEntry
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.tasks.await

/**
 * Repository for journal operations using Firestore sub-collection:
 *   users/{uid}/journals/{journalId}
 *
 * Firestore Offline Persistence is enabled by default, so all reads
 * work without network. Writes are queued and synced automatically.
 */
class JournalFirestoreRepository {
    private val firestore = FirebaseFirestore.getInstance()
    private val TAG = "JournalFirestoreRepo"

    private fun getJournalsCollection(uid: String) =
        firestore.collection("users").document(uid).collection("journals")

    private fun getCurrentUid(): String? =
        FirebaseAuth.getInstance().currentUser?.uid

    @kotlinx.coroutines.ExperimentalCoroutinesApi
    private fun getAuthUidFlow(): Flow<String?> = callbackFlow {
        val auth = FirebaseAuth.getInstance()
        val listener = FirebaseAuth.AuthStateListener { 
            trySend(it.currentUser?.uid)
        }
        auth.addAuthStateListener(listener)
        awaitClose { auth.removeAuthStateListener(listener) }
    }

    // ─── READ ────────────────────────────────────────────────────

    /**
     * Real-time Flow of all published journals (isDraft == false),
     * ordered by timestamp descending.
     */
    @kotlinx.coroutines.ExperimentalCoroutinesApi
    fun getAllJournalsFlow(): Flow<List<JournalEntry>> = getAuthUidFlow().flatMapLatest { uid ->
        if (uid == null) {
            flowOf(emptyList())
        } else {
            callbackFlow {
                val query = getJournalsCollection(uid)
                    .whereEqualTo("isDraft", false)
                    .orderBy("timestamp", Query.Direction.DESCENDING)

                val listener = query.addSnapshotListener { snapshot, error ->
                    if (error != null) {
                        Log.e(TAG, "Error listening to journals", error)
                        trySend(emptyList())
                        return@addSnapshotListener
                    }
                    val journals = snapshot?.documents?.mapNotNull { doc ->
                        doc.data?.let { data -> JournalEntry.fromFirestore(doc.id, data) }
                    } ?: emptyList()
                    trySend(journals)
                }

                awaitClose { listener.remove() }
            }
        }
    }

    /**
     * Real-time Flow of all draft journals (isDraft == true).
     */
    @kotlinx.coroutines.ExperimentalCoroutinesApi
    fun getAllDraftsFlow(): Flow<List<JournalEntry>> = getAuthUidFlow().flatMapLatest { uid ->
        if (uid == null) {
            flowOf(emptyList())
        } else {
            callbackFlow {
                val query = getJournalsCollection(uid)
                    .whereEqualTo("isDraft", true)
                    .orderBy("timestamp", Query.Direction.DESCENDING)

                val listener = query.addSnapshotListener { snapshot, error ->
                    if (error != null) {
                        Log.e(TAG, "Error listening to drafts", error)
                        trySend(emptyList())
                        return@addSnapshotListener
                    }
                    val drafts = snapshot?.documents?.mapNotNull { doc ->
                        doc.data?.let { data -> JournalEntry.fromFirestore(doc.id, data) }
                    } ?: emptyList()
                    trySend(drafts)
                }

                awaitClose { listener.remove() }
            }
        }
    }

    /**
     * Real-time Flow of total journal count (published + drafts).
     */
    @kotlinx.coroutines.ExperimentalCoroutinesApi
    fun getJournalCountFlow(): Flow<Int> = getAuthUidFlow().flatMapLatest { uid ->
        if (uid == null) {
            flowOf(0)
        } else {
            callbackFlow {
                val listener = getJournalsCollection(uid)
                    .whereEqualTo("isDraft", false)
                    .addSnapshotListener { snapshot, error ->
                        if (error != null) {
                            trySend(0)
                            return@addSnapshotListener
                        }
                        trySend(snapshot?.size() ?: 0)
                    }

                awaitClose { listener.remove() }
            }
        }
    }

    /**
     * Fetches a single journal by its Firestore document ID.
     */
    suspend fun getJournalById(firestoreId: String): JournalEntry? {
        val uid = getCurrentUid() ?: return null
        return try {
            val doc = getJournalsCollection(uid).document(firestoreId).get().await()
            doc.data?.let { data -> JournalEntry.fromFirestore(doc.id, data) }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get journal $firestoreId", e)
            null
        }
    }

    // ─── WRITE ───────────────────────────────────────────────────

    /**
     * Inserts a new journal. Returns the auto-generated Firestore document ID.
     */
    suspend fun insertJournal(journal: JournalEntry): String? {
        val uid = getCurrentUid() ?: return null
        return try {
            val data = journal.toFirestoreMap().toMutableMap()
            data["createdAt"] = Timestamp.now()
            data["updatedAt"] = Timestamp.now()

            val docRef = getJournalsCollection(uid).add(data).await()
            Log.d(TAG, "Inserted journal ${docRef.id}")
            docRef.id
        } catch (e: Exception) {
            Log.e(TAG, "Failed to insert journal", e)
            null
        }
    }

    /**
     * Updates an existing journal by its Firestore document ID.
     */
    suspend fun updateJournal(firestoreId: String, journal: JournalEntry) {
        val uid = getCurrentUid() ?: return
        try {
            val data = journal.toFirestoreMap()
            getJournalsCollection(uid).document(firestoreId).update(data).await()
            Log.d(TAG, "Updated journal $firestoreId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update journal $firestoreId", e)
        }
    }

    /**
     * Deletes a journal document by its Firestore document ID.
     */
    suspend fun deleteJournal(firestoreId: String) {
        val uid = getCurrentUid() ?: return
        try {
            getJournalsCollection(uid).document(firestoreId).delete().await()
            Log.d(TAG, "Deleted journal $firestoreId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete journal $firestoreId", e)
        }
    }
}
