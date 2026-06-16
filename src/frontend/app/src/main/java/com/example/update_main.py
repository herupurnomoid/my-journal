import re

with open("MainActivity.kt", "r") as f:
    content = f.read()

# 1. Add new state collectors
new_collectors = """    val isLoggedIn by viewModel.isLoggedIn.collectAsState()
    val isPinVerified by viewModel.isPinVerified.collectAsState()
    val isPinEnabled by viewModel.isPinEnabled.collectAsState()
    val userPin by viewModel.userPin.collectAsState()"""
content = re.sub(r"\s+val isLoggedIn by viewModel\.isLoggedIn\.collectAsState\(\)\s+val isPinVerified by viewModel\.isPinVerified\.collectAsState\(\)", "\n" + new_collectors, content)

# 2. Update LaunchedEffect logic
old_effect = r"LaunchedEffect\(isLoggedIn, isPinVerified\) \{\s+if \(!isLoggedIn\) \{\s+appState = AppFlowState\.SPLASH\s+\} else if \(!isPinVerified\) \{\s+appState = AppFlowState\.PIN\s+\} else \{\s+appState = AppFlowState\.MAIN_SHELL\s+\}\s+\}"
new_effect = """LaunchedEffect(isLoggedIn, isPinVerified, isPinEnabled) {
        if (!isLoggedIn) {
            appState = AppFlowState.SPLASH
        } else if (isPinEnabled && !isPinVerified) {
            appState = AppFlowState.PIN
        } else {
            appState = AppFlowState.MAIN_SHELL
        }
    }"""
content = re.sub(old_effect, new_effect, content)

# 3. Update PinSecurityScreen invocation
content = content.replace('correctPin = "123456",', 'correctPin = userPin,')

# 4. Update Profile Tab label
content = content.replace('label = { Text("Profile") },', 'label = { Text("Profil") },')

with open("MainActivity.kt", "w") as f:
    f.write(content)
