import re

with open("PinSecurityScreen.kt", "r") as f:
    content = f.read()

# Replace the method signature
content = content.replace(
    "onResetPin: () -> Unit,",
    "onNewPinSet: (String) -> Unit,"
)

# Add enum and variables inside PinSecurityScreen
enum_decl = """enum class PinScreenMode { VERIFY, SET_NEW }

@Composable
fun PinSecurityScreen("""

content = content.replace("@Composable\nfun PinSecurityScreen(", enum_decl)

var_decls = """    var enteredPin by remember { mutableStateOf("") }
    var errorMessage by remember { mutableStateOf("") }

    // OTP Reset State
    var showOtpDialog by remember { mutableStateOf(false) }
    var otpCode by remember { mutableStateOf("") }
    var otpError by remember { mutableStateOf("") }
    var currentMode by remember { mutableStateOf(PinScreenMode.VERIFY) }"""

content = re.sub(r"\s*var enteredPin by remember.*?var otpError by remember \{ mutableStateOf\(\"\"\) \}", var_decls, content, flags=re.DOTALL)


# Update handleKeyPress logic
handle_key_logic = """    val handleKeyPress: (String) -> Unit = { digit ->
        if (enteredPin.length < 6) {
            enteredPin += digit
            errorMessage = ""
            if (enteredPin.length == 6) {
                if (currentMode == PinScreenMode.VERIFY) {
                    if (enteredPin == correctPin) {
                        onPinVerified()
                    } else {
                        errorMessage = "PIN Salah!"
                        enteredPin = ""
                    }
                } else {
                    // SET_NEW mode
                    onNewPinSet(enteredPin)
                }
            }
        }
    }"""

content = re.sub(r"\s*val handleKeyPress: \(String\) -> Unit = \{ digit ->.*?    val handleDelete", handle_key_logic + "\n\n    val handleDelete", content, flags=re.DOTALL)


# Update UI titles
ui_title = """                Text(
                    text = if (currentMode == PinScreenMode.VERIFY) "Sandi Keamanan" else "Buat PIN Baru",
                    style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.onBackground
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = if (currentMode == PinScreenMode.VERIFY) "Masukkan PIN pribadi Anda" else "Masukkan 6 digit PIN baru",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )"""

content = re.sub(r"\s*Text\(\s*text = \"Sandi Keamanan\".*?color = MaterialTheme\.colorScheme\.onBackground\.copy\(alpha = 0\.6f\)\s*\)", ui_title, content, flags=re.DOTALL)


# Hide forgot PIN button in SET_NEW mode
forgot_pin_btn = """            if (currentMode == PinScreenMode.VERIFY) {
                TextButton(
                    onClick = { 
                        otpCode = ""
                        otpError = ""
                        showOtpDialog = true 
                    },
                    modifier = Modifier.testTag("forgot_pin_button")
                ) {
                    Text(
                        text = "Lupa PIN?",
                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            } else {
                Spacer(modifier = Modifier.height(48.dp))
            }"""

content = re.sub(r"\s*TextButton\(\s*onClick = \{ \s*otpStep = 1.*?color = MaterialTheme\.colorScheme\.primary\s*\)\s*\}", forgot_pin_btn, content, flags=re.DOTALL)


# Update OTP Dialog
otp_dialog = """    if (showOtpDialog) {
        AlertDialog(
            onDismissRequest = { showOtpDialog = false },
            title = { Text("Verifikasi OTP") },
            text = {
                Column {
                    Text("Masukkan 4 digit kode OTP yang telah dikirim ke herupurnomo.id@gmail.com. (KODE DEMO: 1234)")
                    Spacer(modifier = Modifier.height(16.dp))
                    OutlinedTextField(
                        value = otpCode,
                        onValueChange = { if (it.length <= 4 && it.all { char -> char.isDigit() }) otpCode = it },
                        label = { Text("Kode OTP") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        singleLine = true
                    )
                    if (otpError.isNotEmpty()) {
                        Text(text = otpError, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall, modifier = Modifier.padding(top = 4.dp))
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (otpCode == "1234") {
                            showOtpDialog = false
                            enteredPin = ""
                            currentMode = PinScreenMode.SET_NEW
                        } else {
                            otpError = "Kode OTP tidak valid!"
                        }
                    },
                    enabled = otpCode.length == 4
                ) {
                    Text("Verifikasi")
                }
            },
            dismissButton = {
                TextButton(onClick = { showOtpDialog = false }) {
                    Text("Batal")
                }
            }
        )
    }"""

content = re.sub(r"\s*if \(showOtpDialog\) \{.*?\}\s*\)\s*\}", otp_dialog, content, flags=re.DOTALL)

with open("PinSecurityScreen.kt", "w") as f:
    f.write(content)
