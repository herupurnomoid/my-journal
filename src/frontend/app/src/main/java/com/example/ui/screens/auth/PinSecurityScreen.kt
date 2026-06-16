package com.example.ui.screens.auth

import kotlinx.coroutines.delay
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.JournalEntry
import com.example.ui.viewmodel.JournalViewModel

enum class PinScreenMode { VERIFY, SET_NEW }

@Composable
fun PinSecurityScreen(
    viewModel: JournalViewModel,
    correctPin: String,
    onPinVerified: () -> Unit,
    onNewPinSet: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val currentUserEmail = com.google.firebase.auth.FirebaseAuth.getInstance().currentUser?.email ?: ""
    var enteredPin by remember { mutableStateOf("") }
    var errorMessage by remember { mutableStateOf("") }

    // OTP Reset State
    var showOtpDialog by remember { mutableStateOf(false) }
    var isLoadingOtp by remember { mutableStateOf(false) }
    var otpCode by remember { mutableStateOf("") }
    var otpError by remember { mutableStateOf("") }
    var currentMode by remember { mutableStateOf(PinScreenMode.VERIFY) }
    
    val handleKeyPress: (String) -> Unit = { digit ->
        if (enteredPin.length < 6) {
            enteredPin += digit
            errorMessage = ""
            if (enteredPin.length == 6) {
                if (currentMode == PinScreenMode.VERIFY) {
                    if (viewModel.verifyPin(enteredPin)) {
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
    }

    val handleDelete: () -> Unit = {
        if (enteredPin.isNotEmpty()) {
            enteredPin = enteredPin.dropLast(1)
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween,
            modifier = Modifier
                .padding(24.dp)
                .fillMaxHeight(0.85f)
                .fillMaxWidth()
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    imageVector = Icons.Default.Security,
                    contentDescription = "Shield Guard",
                    tint = MaterialTheme.colorScheme.secondary,
                    modifier = Modifier.size(56.dp)
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = if (currentMode == PinScreenMode.VERIFY) "Sandi Keamanan" else "Buat PIN Baru",
                    style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.onBackground
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = if (currentMode == PinScreenMode.VERIFY) "Masukkan PIN pribadi Anda" else "Masukkan 6 digit PIN baru",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )
            }

            // Dot pin indicators
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(24.dp)
            ) {
                for (i in 0 until 6) {
                    val active = i < enteredPin.length
                    Box(
                        modifier = Modifier
                            .size(20.dp)
                            .clip(CircleShape)
                            .background(
                                if (active) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                            )
                    )
                }
            }

            if (errorMessage.isNotEmpty()) {
                Text(
                    text = errorMessage,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.labelLarge,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 16.dp)
                )
            }

            // Numeric Keyboard Grid
            Column(
                modifier = Modifier.fillMaxWidth(0.85f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                val buttonLayout = listOf(
                    listOf("1", "2", "3"),
                    listOf("4", "5", "6"),
                    listOf("7", "8", "9"),
                    listOf("Clear", "0", "Del")
                )

                for (row in buttonLayout) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        for (key in row) {
                            Box(
                                modifier = Modifier
                                    .size(64.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (key == "Clear" || key == "Del") Color.Transparent
                                        else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                                    )
                                    .clickable {
                                        when (key) {
                                            "Clear" -> enteredPin = ""
                                            "Del" -> handleDelete()
                                            else -> handleKeyPress(key)
                                        }
                                    },
                                contentAlignment = Alignment.Center
                            ) {
                                if (key == "Del") {
                                    Icon(
                                        imageVector = Icons.Default.Backspace,
                                        contentDescription = "Delete",
                                        tint = MaterialTheme.colorScheme.onBackground
                                    )
                                } else {
                                    Text(
                                        text = key,
                                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                        color = if (key == "Clear") MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onBackground
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            if (currentMode == PinScreenMode.VERIFY) {
                TextButton(
                    onClick = { 
                        if (currentUserEmail.isNotEmpty()) {
                            isLoadingOtp = true
                            viewModel.requestPinReset(currentUserEmail) { success, msg ->
                                isLoadingOtp = false
                                if (success) {
                                    otpCode = ""
                                    otpError = ""
                                    showOtpDialog = true 
                                } else {
                                    errorMessage = msg
                                }
                            }
                        } else {
                            errorMessage = "Tidak ada sesi email yang aktif."
                        }
                    },
                    modifier = Modifier.testTag("forgot_pin_button"),
                    enabled = !isLoadingOtp
                ) {
                    Text(
                        text = if (isLoadingOtp) "Mengirim OTP..." else "Lupa PIN?",
                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            } else {
                Spacer(modifier = Modifier.height(48.dp))
            }
        }
    }
    
    if (showOtpDialog) {
        var isVerifying by remember { mutableStateOf(false) }
        AlertDialog(
            onDismissRequest = { if (!isVerifying) showOtpDialog = false },
            title = { Text("Verifikasi OTP") },
            text = {
                Column {
                    Text("Masukkan 6 digit kode OTP yang telah dikirim ke $currentUserEmail.")
                    Spacer(modifier = Modifier.height(16.dp))
                    OutlinedTextField(
                        value = otpCode,
                        onValueChange = { if (it.length <= 6 && it.all { char -> char.isDigit() }) otpCode = it },
                        label = { Text("Kode OTP") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        singleLine = true,
                        enabled = !isVerifying
                    )
                    if (otpError.isNotEmpty()) {
                        Text(text = otpError, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall, modifier = Modifier.padding(top = 4.dp))
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        isVerifying = true
                        otpError = ""
                        // Temporary dummy PIN set up first, backend gives a reset token.
                        // We tell the user to set a NEW PIN instead.
                        viewModel.verifyPinOtpAndReset(currentUserEmail, otpCode, "000000") { success, msg ->
                            isVerifying = false
                            if (success) {
                                showOtpDialog = false
                                enteredPin = ""
                                currentMode = PinScreenMode.SET_NEW
                            } else {
                                otpError = msg
                            }
                        }
                    },
                    enabled = otpCode.length == 6 && !isVerifying
                ) {
                    Text(if (isVerifying) "Verifikasi..." else "Verifikasi")
                }
            },
            dismissButton = {
                TextButton(onClick = { showOtpDialog = false }, enabled = !isVerifying) {
                    Text("Batal")
                }
            }
        )
    }
}
