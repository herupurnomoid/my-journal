package com.example.ui.viewmodel

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.model.JournalEntry
import com.example.data.model.UserProfile
import com.example.data.remote.dto.AnalyzeMoodResponse
import com.example.data.remote.dto.JournalTextDto
import com.example.data.repository.AiBackendRepository
import com.example.data.repository.AuthRepository
import com.example.data.repository.ImageStorageRepository
import com.example.data.repository.JournalFirestoreRepository
import com.example.data.repository.UserRepository
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class JournalViewModel(application: Application) : AndroidViewModel(application) {
    private val TAG = "JournalViewModel"
    private val authRepo = AuthRepository()
    private val userRepo = UserRepository()
    private val journalRepo = JournalFirestoreRepository()
    private val storageRepo = ImageStorageRepository()
    private val aiBackendRepo = AiBackendRepository()

    // ─── Firestore Journal Flows ─────────────────────────────────
    val allJournals: StateFlow<List<JournalEntry>> = journalRepo.getAllJournalsFlow()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allDrafts: StateFlow<List<JournalEntry>> = journalRepo.getAllDraftsFlow()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val journalCount: StateFlow<Int> = journalRepo.getJournalCountFlow()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    // ─── Session States ──────────────────────────────────────────
    private val _isLoggedIn = MutableStateFlow(false)
    val isLoggedIn = _isLoggedIn.asStateFlow()

    private val _isProfileLoaded = MutableStateFlow(false)
    val isProfileLoaded = _isProfileLoaded.asStateFlow()

    private val _userPin = MutableStateFlow("")
    val userPin = _userPin.asStateFlow()

    private val _isPinVerified = MutableStateFlow(false)
    val isPinVerified = _isPinVerified.asStateFlow()

    private val _isPinSetup = MutableStateFlow(false)
    val isPinSetup = _isPinSetup.asStateFlow()

    private val _isPinEnabled = MutableStateFlow(false)
    val isPinEnabled = _isPinEnabled.asStateFlow()

    // Grace period flag: prevents onStop from resetting PIN verification
    // immediately after user just set/changed their PIN
    private var pinSetupGraceUntil: Long = 0L

    private val _reminderTime = MutableStateFlow("20:00")
    val reminderTime = _reminderTime.asStateFlow()

    private val _isReminderEnabled = MutableStateFlow(true)
    val isReminderEnabled = _isReminderEnabled.asStateFlow()

    // ─── Firestore Profile Flow ──────────────────────────────────
    private var profileJob: Job? = null
    private val _userProfile = MutableStateFlow<UserProfile?>(null)
    val userProfile = _userProfile.asStateFlow()

    // ─── Active Selection for detail / edit ──────────────────────
    private val _selectedJournal = MutableStateFlow<JournalEntry?>(null)
    val selectedJournal = _selectedJournal.asStateFlow()

    // ─── AI Analysis States ──────────────────────────────────────
    private val _currentAnalysis = MutableStateFlow<AnalyzeMoodResponse?>(null)
    val currentAnalysis = _currentAnalysis.asStateFlow()
    
    private val _weeklyInsights = MutableStateFlow<String?>(null)
    val weeklyInsights = _weeklyInsights.asStateFlow()

    private val _isAnalyzing = MutableStateFlow(false)
    val isAnalyzing = _isAnalyzing.asStateFlow()

    // ═══════════════════════════════════════════════════════════════
    // Auth & Navigation
    // ═══════════════════════════════════════════════════════════════

    fun logInWithGoogle() {
        // Start observing the user profile from Firestore.
        // The navigator will wait for isProfileLoaded=true before deciding PIN vs MAIN_SHELL.
        observeUserProfile()
        _isLoggedIn.value = true
    }

    private fun observeUserProfile() {
        val currentUser = FirebaseAuth.getInstance().currentUser ?: return
        profileJob?.cancel()
        _isProfileLoaded.value = false
        profileJob = viewModelScope.launch {
            userRepo.getUserProfileFlow().collect { profile ->
                if (profile != null) {
                    _userProfile.value = profile
                    // During grace period, don't let Firestore snapshot overwrite
                    // the local PIN-related state that we just set
                    val inGracePeriod = System.currentTimeMillis() < pinSetupGraceUntil
                    if (!inGracePeriod) {
                        _isPinEnabled.value = profile.isPinEnabled
                        Log.d(TAG, "Profile loaded: isPinEnabled=${profile.isPinEnabled}, pinHash=${if (profile.pinHash != null) "set" else "null"}")
                    }
                    _isReminderEnabled.value = profile.reminderEnabled
                    _reminderTime.value = profile.reminderTime
                    if (profile.pinHash != null) {
                        _userPin.value = profile.pinHash
                        _isPinSetup.value = true
                    } else if (!inGracePeriod) {
                        _isPinSetup.value = false
                    }
                    // Mark profile as loaded so the navigator can make routing decisions
                    if (!_isProfileLoaded.value) {
                        _isProfileLoaded.value = true
                        Log.d(TAG, "Profile loaded for first time, isPinEnabled=${_isPinEnabled.value}")
                    }
                }
            }
        }
    }

    fun logOut() {
        profileJob?.cancel()
        authRepo.signOut()
        _isLoggedIn.value = false
        // Reset all state so it's cleanly loaded from Firestore on next login
        _isProfileLoaded.value = false
        _isPinVerified.value = false
        _isPinEnabled.value = false
        _isPinSetup.value = false
        _userPin.value = ""
        _userProfile.value = null
    }

    fun resetPinVerification() {
        // Don't reset during grace period (right after PIN setup)
        if (System.currentTimeMillis() < pinSetupGraceUntil) {
            Log.d(TAG, "resetPinVerification SKIPPED (grace period active)")
            return
        }
        Log.d(TAG, "resetPinVerification -> false")
        _isPinVerified.value = false
    }

    private fun hashPin(pin: String): String {
        val bytes = java.security.MessageDigest.getInstance("SHA-256").digest(pin.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }

    fun verifyPin(pin: String): Boolean {
        val hashedInput = hashPin(pin)
        // Check hash, or plain text for backward compatibility if user already saved plain text PIN
        return if (hashedInput == _userPin.value || pin == _userPin.value) {
            _isPinVerified.value = true
            true
        } else {
            false
        }
    }

    fun togglePinLock(enabled: Boolean) {
        _isPinEnabled.value = enabled
        if (!enabled) {
            _isPinVerified.value = true
        }
        updateFirestoreSetting("isPinEnabled", enabled)
    }

    fun updatePin(newPin: String) {
        Log.d(TAG, "updatePin called")
        val hashedPin = hashPin(newPin)
        _userPin.value = hashedPin
        _isPinSetup.value = true
        _isPinVerified.value = true
        _isPinEnabled.value = true
        // Set grace period: 5 seconds after PIN setup, Firestore snapshot won't overwrite local state
        pinSetupGraceUntil = System.currentTimeMillis() + 5000L
        // Write both pinHash and isPinEnabled atomically in a single Firestore operation
        // to prevent snapshot listener from seeing intermediate state
        updateFirestoreSettings(mapOf("pinHash" to hashedPin, "isPinEnabled" to true))
    }

    // ─── Reminder toggles ────────────────────────────────────────

    fun toggleReminder(enabled: Boolean) {
        _isReminderEnabled.value = enabled
        updateFirestoreSetting("reminderEnabled", enabled)
    }

    fun updateReminderTime(hour: Int, minute: Int) {
        val formattedHour = String.format("%02d", hour)
        val formattedMin = String.format("%02d", minute)
        val timeStr = "$formattedHour:$formattedMin"
        _reminderTime.value = timeStr
        updateFirestoreSetting("reminderTime", timeStr)
    }

    private fun updateFirestoreSetting(field: String, value: Any) {
        val currentUser = FirebaseAuth.getInstance().currentUser ?: return
        viewModelScope.launch {
            userRepo.updateSetting(currentUser.uid, field, value)
        }
    }

    private fun updateFirestoreSettings(fields: Map<String, Any>) {
        val currentUser = FirebaseAuth.getInstance().currentUser ?: return
        viewModelScope.launch {
            userRepo.updateSettings(currentUser.uid, fields)
        }
    }

    fun updateLastActive() {
        val currentUser = FirebaseAuth.getInstance().currentUser ?: return
        viewModelScope.launch {
            userRepo.updateLastActive(currentUser.uid)
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // Journal Operations (Firestore)
    // ═══════════════════════════════════════════════════════════════

    fun saveJournal(
        title: String,
        content: String,
        userMood: String,
        photoUri: String?,
        location: String,
        isDraft: Boolean = false
    ) {
        viewModelScope.launch {
            _isAnalyzing.value = true

            // Run AI analysis via Backend (skip for drafts)
            val analysis = if (!isDraft) {
                try {
                    aiBackendRepo.analyzeMood(title, content)
                } catch (e: Exception) {
                    Log.e(TAG, "AI analysis failed", e)
                    null
                }
            } else null

            if (analysis != null) _currentAnalysis.value = analysis

            val dateFormat = java.text.SimpleDateFormat("dd MMM yyyy", java.util.Locale.getDefault())
            val dateStr = dateFormat.format(java.util.Date())

            // Process images
            val (processedContent, finalPhotoUrl) = processContentAndImages(content, photoUri)

            val entry = JournalEntry(
                title = title,
                content = processedContent,
                userMood = userMood,
                date = dateStr,
                timestamp = System.currentTimeMillis(),
                location = location,
                photoUri = photoUri,
                photoUrl = finalPhotoUrl,
                aiMoodPrimary = analysis?.primaryMood,
                aiStressLevel = analysis?.stressLevel,
                aiHappinessLevel = analysis?.happinessLevel,
                aiEmotionSummary = analysis?.emotionSummary,
                aiRecommendations = analysis?.recommendations?.joinToString("|"),
                isDraft = isDraft
            )

            journalRepo.insertJournal(entry)
            _isAnalyzing.value = false
        }
    }

    fun updateJournal(
        firestoreId: String,
        title: String,
        content: String,
        userMood: String,
        photoUri: String?,
        location: String,
        isDraft: Boolean = false
    ) {
        viewModelScope.launch {
            _isAnalyzing.value = true
            val analysis = if (!isDraft) {
                try {
                    aiBackendRepo.analyzeMood(title, content)
                } catch (e: Exception) {
                    Log.e(TAG, "AI analysis failed", e)
                    null
                }
            } else null

            if (analysis != null) _currentAnalysis.value = analysis

            val existing = journalRepo.getJournalById(firestoreId)
            if (existing != null) {
                // Process images
                val (processedContent, finalPhotoUrl) = processContentAndImages(content, photoUri)

                val updated = existing.copy(
                    title = title,
                    content = processedContent,
                    userMood = userMood,
                    location = location,
                    photoUri = photoUri,
                    photoUrl = finalPhotoUrl,
                    aiMoodPrimary = analysis?.primaryMood ?: existing.aiMoodPrimary,
                    aiStressLevel = analysis?.stressLevel ?: existing.aiStressLevel,
                    aiHappinessLevel = analysis?.happinessLevel ?: existing.aiHappinessLevel,
                    aiEmotionSummary = analysis?.emotionSummary ?: existing.aiEmotionSummary,
                    aiRecommendations = analysis?.recommendations?.joinToString("|") ?: existing.aiRecommendations,
                    isDraft = isDraft
                )
                journalRepo.updateJournal(firestoreId, updated)
                if (_selectedJournal.value?.firestoreId == firestoreId) {
                    _selectedJournal.value = updated
                }
            }
            _isAnalyzing.value = false
        }
    }

    fun deleteJournal(firestoreId: String) {
        viewModelScope.launch {
            journalRepo.deleteJournal(firestoreId)
        }
    }

    // Overload for backward compatibility with Int id (ignored, uses firestoreId)
    fun deleteJournal(id: Int) {
        val journal = _selectedJournal.value ?: return
        if (journal.firestoreId.isNotEmpty()) {
            deleteJournal(journal.firestoreId)
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // AI Insights (Weekly)
    // ═══════════════════════════════════════════════════════════════

    fun fetchWeeklyInsights() {
        viewModelScope.launch {
            val prefs = getApplication<Application>().getSharedPreferences("ai_insights_prefs", android.content.Context.MODE_PRIVATE)
            val lastFetchTime = prefs.getLong("last_fetch_time", 0L)
            val cachedInsight = prefs.getString("cached_insight", null)
            
            val currentTime = System.currentTimeMillis()
            val oneDayInMillis = 24 * 60 * 60 * 1000L
            
            // Gunakan cache jika belum lewat 24 jam dan cache tersedia
            if (cachedInsight != null && (currentTime - lastFetchTime) < oneDayInMillis) {
                _weeklyInsights.value = cachedInsight
                return@launch
            }
            
            val journals = allJournals.value.take(7).map {
                JournalTextDto(title = it.title, content = it.content)
            }
            if (journals.isNotEmpty()) {
                val insight = aiBackendRepo.getWeeklyInsights(journals)
                if (insight != null) {
                    _weeklyInsights.value = insight
                    // Simpan ke cache
                    prefs.edit()
                        .putLong("last_fetch_time", currentTime)
                        .putString("cached_insight", insight)
                        .apply()
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // Export Data (PDF)
    // ═══════════════════════════════════════════════════════════════

    fun exportJournalsToPdf(onResult: (Boolean, String?) -> Unit) {
        viewModelScope.launch {
            val downloadUrl = aiBackendRepo.exportPdf()
            if (downloadUrl != null) {
                onResult(true, downloadUrl)
            } else {
                onResult(false, null)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // PIN Recovery via Backend
    // ═══════════════════════════════════════════════════════════════

    fun requestPinReset(email: String, onResult: (Boolean, String) -> Unit) {
        viewModelScope.launch {
            val result = authRepo.forgotPin(email)
            if (result.isSuccess) {
                onResult(true, result.getOrNull() ?: "Success")
            } else {
                onResult(false, result.exceptionOrNull()?.message ?: "Failed")
            }
        }
    }

    fun verifyPinOtpAndReset(email: String, otp: String, newPin: String, onResult: (Boolean, String) -> Unit) {
        viewModelScope.launch {
            val result = authRepo.verifyPinOtp(email, otp)
            if (result.isSuccess) {
                // Jika backend memberikan reset token, kita simpan PIN baru
                updatePin(newPin)
                onResult(true, "PIN berhasil direset")
            } else {
                onResult(false, result.exceptionOrNull()?.message ?: "Invalid OTP")
            }
        }
    }

    fun selectJournal(journal: JournalEntry) {
        _selectedJournal.value = journal
        if (journal.aiMoodPrimary != null) {
            _currentAnalysis.value = AnalyzeMoodResponse(
                primaryMood = journal.aiMoodPrimary,
                stressLevel = journal.aiStressLevel ?: 30,
                happinessLevel = journal.aiHappinessLevel ?: 70,
                emotionSummary = journal.aiEmotionSummary ?: "",
                recommendations = journal.aiRecommendations?.split("|") ?: emptyList()
            )
        } else {
            _currentAnalysis.value = null
            
            // Lakukan analisis secara otomatis jika jurnal belum pernah dianalisis
            viewModelScope.launch {
                _isAnalyzing.value = true
                try {
                    val analysis = aiBackendRepo.analyzeMood(journal.title, journal.content)
                    if (analysis != null) {
                        _currentAnalysis.value = analysis
                        
                        // Simpan hasil analisis ke Firestore agar tidak perlu hit lagi ke depannya
                        if (journal.firestoreId.isNotEmpty()) {
                            val updated = journal.copy(
                                aiMoodPrimary = analysis.primaryMood,
                                aiStressLevel = analysis.stressLevel,
                                aiHappinessLevel = analysis.happinessLevel,
                                aiEmotionSummary = analysis.emotionSummary,
                                aiRecommendations = analysis.recommendations.joinToString("|")
                            )
                            journalRepo.updateJournal(journal.firestoreId, updated)
                            _selectedJournal.value = updated
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "AI analysis failed on demand", e)
                } finally {
                    _isAnalyzing.value = false
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // CRUD & Image Upload Processing
    // ═══════════════════════════════════════════════════════════════

    private suspend fun processContentAndImages(content: String, photoUri: String?): Pair<String, String?> {
        var processedContent = content
        var finalPhotoUrl = photoUri

        // 1. Process Main Photo (Cover)
        if (photoUri != null && !photoUri.startsWith("http")) {
            try {
                val downloadUrl = storageRepo.uploadImage(android.net.Uri.parse(photoUri))
                if (downloadUrl != null) {
                    finalPhotoUrl = downloadUrl
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to upload cover image", e)
            }
        }

        // 2. Process Embedded Images in content
        val parts = processedContent.split("<!--BLOCK_DELIMITER-->").toMutableList()
        
        for (i in parts.indices) {
            val part = parts[i]
            if (part.startsWith("IMAGE:")) {
                val uriStr = part.removePrefix("IMAGE:")
                if (!uriStr.startsWith("http")) {
                    try {
                        val downloadUrl = storageRepo.uploadImage(android.net.Uri.parse(uriStr))
                        if (downloadUrl != null) {
                            parts[i] = "IMAGE:$downloadUrl"
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to upload embedded image", e)
                    }
                }
            }
        }
        
        processedContent = parts.joinToString("<!--BLOCK_DELIMITER-->")
        
        return Pair(processedContent, finalPhotoUrl)
    }

    // ═══════════════════════════════════════════════════════════════
    // Export Functions
    // ═══════════════════════════════════════════════════════════════

    fun exportJournalsToMarkdown(context: android.content.Context): Boolean {
        return try {
            val journals = allJournals.value
            val mdContent = java.lang.StringBuilder().apply {
                append("# Rekap Jurnal Kelas Reflektif\n\n")
                journals.forEach { journal ->
                    append("## ${journal.title}\n")
                    val dateStr = java.text.SimpleDateFormat("dd MMM yyyy, HH:mm", java.util.Locale.getDefault()).format(java.util.Date(journal.timestamp))
                    append("**Waktu:** $dateStr | **Mood:** ${journal.userMood}\n\n")
                    append("${journal.content.replace("<!--BLOCK_DELIMITER-->", "\n")}\n\n")
                    append("---\n\n")
                }
            }.toString()

            val fileName = "MyJournal_Export_${System.currentTimeMillis()}.md"
            val contentValues = android.content.ContentValues().apply {
                put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "text/markdown")
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH, android.os.Environment.DIRECTORY_DOWNLOADS + "/MyJurnal")
                }
            }

            val uri = context.contentResolver.insert(android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            if (uri != null) {
                context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                    outputStream.write(mdContent.toByteArray())
                }
                true
            } else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
