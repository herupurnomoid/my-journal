import re

with open("JournalViewModel.kt", "r") as f:
    content = f.read()

# Remove Sync & Offline Status
sync_pattern = re.compile(r"    // Sync & Offline Status\s+private val _isSyncing = MutableStateFlow\(false\)\s+val isSyncing = _isSyncing\.asStateFlow\(\)\s+private val _syncHistory = MutableStateFlow<List<String>>\(\s+listOf\(\s+\"Sinkronisasi berhasil: 10 Jun 2026, 18:30\",\s+\"Sinkronisasi berhasil: 11 Jun 2026, 08:15\"\s+\)\s+\)\s+val syncHistory = _syncHistory\.asStateFlow\(\)\s+private val _isOnline = MutableStateFlow\(true\)\s+val isOnline = _isOnline\.asStateFlow\(\)", re.MULTILINE)
content = re.sub(sync_pattern, "", content)

# Remove triggerSync and toggleNetworkStatus
trigger_sync_pattern = re.compile(r"    fun triggerSync\(\) \{\s+viewModelScope\.launch \{\s+if \(_isOnline\.value\) \{\s+_isSyncing\.value = true\s+delay\(1500\)\s+_syncHistory\.value = listOf\(\"Sinkronisasi berhasil: Baru saja\"\) \+ _syncHistory\.value\s+_isSyncing\.value = false\s+\}\s+\}\s+\}\s+fun toggleNetworkStatus\(\) \{\s+_isOnline\.value = !_isOnline\.value\s+\}", re.MULTILINE)
content = re.sub(trigger_sync_pattern, "", content)

# Add isPinEnabled and modify isPinSetup logic
# We need to find: private val _isPinSetup = MutableStateFlow(true)
pin_setup_pattern = re.compile(r"    private val _isPinSetup = MutableStateFlow\(true\)\s+val isPinSetup = _isPinSetup\.asStateFlow\(\)")
pin_replacement = """    private val _isPinSetup = MutableStateFlow(true)
    val isPinSetup = _isPinSetup.asStateFlow()

    private val _isPinEnabled = MutableStateFlow(false)
    val isPinEnabled = _isPinEnabled.asStateFlow()
"""
content = re.sub(pin_setup_pattern, pin_replacement, content)

# Add togglePinLock
toggle_pin_logic = """    fun togglePinLock(enabled: Boolean) {
        _isPinEnabled.value = enabled
        if (!enabled) {
            _isPinVerified.value = true // automatically verified if disabled
        }
    }
"""
content = content.replace("    fun updatePin(newPin: String) {\n        _userPin.value = newPin\n    }", toggle_pin_logic + "    fun updatePin(newPin: String) {\n        _userPin.value = newPin\n        _isPinSetup.value = true\n    }")

with open("JournalViewModel.kt", "w") as f:
    f.write(content)
