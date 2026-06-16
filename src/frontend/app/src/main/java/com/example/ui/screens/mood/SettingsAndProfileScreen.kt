package com.example.ui.screens.mood

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.ui.viewmodel.JournalViewModel

@Composable
fun SettingsAndProfileScreen(
    viewModel: JournalViewModel,
    modifier: Modifier = Modifier
) {
    var showSettings by remember { mutableStateOf(false) }

    if (showSettings) {
        SettingsTab(viewModel = viewModel, onBack = { showSettings = false })
    } else {
        ProfileTab(viewModel = viewModel, onOpenSettings = { showSettings = true })
    }
}

@Composable
fun ProfileTab(viewModel: JournalViewModel, onOpenSettings: () -> Unit) {
    val context = LocalContext.current
    val userProfile by viewModel.userProfile.collectAsState()
    val journalCount by viewModel.journalCount.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Profil", style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold))
            IconButton(onClick = onOpenSettings) {
                Icon(imageVector = Icons.Default.Settings, contentDescription = "Pengaturan")
            }
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Profile Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Row(modifier = Modifier.padding(20.dp), verticalAlignment = Alignment.CenterVertically) {
                    // Avatar: show real Google photo or fallback icon
                    val avatarUrl = userProfile?.avatarUrl
                    if (avatarUrl != null && avatarUrl.isNotEmpty()) {
                        AsyncImage(
                            model = avatarUrl,
                            contentDescription = "Foto Profil",
                            modifier = Modifier
                                .size(64.dp)
                                .clip(CircleShape),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .size(64.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Person,
                                contentDescription = "User",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(32.dp)
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column {
                        Text(
                            text = userProfile?.name ?: "Memuat...",
                            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold)
                        )
                        Text(
                            text = userProfile?.email ?: "",
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color.Gray
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(Color(0xFF81C784).copy(alpha = 0.2f))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = "$journalCount Jurnal Tersimpan",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color(0xFF4CAF50),
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }

            // Export Controls
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Text(text = "Ekspor & Cadangkan Jurnal", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)

                    var exportToastText by remember { mutableStateOf("") }

                    var isExporting by remember { mutableStateOf(false) }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Button(
                            onClick = {
                                isExporting = true
                                exportToastText = "Mengekspor PDF..."
                                viewModel.exportJournalsToPdf { success, url ->
                                    isExporting = false
                                    if (success && url != null) {
                                        exportToastText = "Berhasil mengekspor PDF"
                                        val intent = android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url))
                                        context.startActivity(intent)
                                    } else {
                                        exportToastText = "Gagal mengekspor PDF ke server"
                                    }
                                }
                            },
                            modifier = Modifier.weight(1f).testTag("export_pdf_button"),
                            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primaryContainer, contentColor = MaterialTheme.colorScheme.primary)
                        ) {
                            Icon(imageVector = Icons.Default.PictureAsPdf, contentDescription = "PDF", modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(text = "PDF")
                        }

                        Button(
                            onClick = {
                                val success = viewModel.exportJournalsToMarkdown(context)
                                exportToastText = if (success) "Berhasil mengekspor catatan ke Markdown" else "Gagal mengekspor Markdown"
                            },
                            modifier = Modifier.weight(1f).testTag("export_markdown_button"),
                            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primaryContainer, contentColor = MaterialTheme.colorScheme.primary)
                        ) {
                            Icon(imageVector = Icons.Default.Article, contentDescription = "MD", modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(text = "Markdown")
                        }
                    }

                    if (exportToastText.isNotEmpty()) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color(0xFF81C784).copy(alpha = 0.2f))
                                .padding(12.dp)
                        ) {
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                Text(text = exportToastText, color = Color(0xFF2E7D32), fontWeight = FontWeight.SemiBold, fontSize = 12.sp, modifier = Modifier.weight(1f))
                                IconButton(onClick = { exportToastText = "" }, modifier = Modifier.size(16.dp)) {
                                    Icon(imageVector = Icons.Default.Close, contentDescription = "Close", tint = Color(0xFF2E7D32))
                                }
                            }
                        }
                    }
                }
            }

            // Logout exit button
            Button(
                onClick = { viewModel.logOut() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .testTag("logout_button"),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.errorContainer, contentColor = MaterialTheme.colorScheme.error)
            ) {
                Icon(imageVector = Icons.Default.ExitToApp, contentDescription = "Logout")
                Spacer(modifier = Modifier.width(8.dp))
                Text(text = "Keluar Kelas Reflektif", fontWeight = FontWeight.Bold)
            }

            Spacer(modifier = Modifier.height(48.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsTab(viewModel: JournalViewModel, onBack: () -> Unit) {
    val isPinEnabled by viewModel.isPinEnabled.collectAsState()
    var showPinSetupDialog by remember { mutableStateOf(false) }
    var pinInput by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        TopAppBar(
            title = { Text("Pengaturan", fontWeight = FontWeight.Bold) },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(imageVector = Icons.Default.ArrowBack, contentDescription = "Kembali")
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Keamanan
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Icon(imageVector = Icons.Default.Lock, contentDescription = "Lock", tint = MaterialTheme.colorScheme.primary)
                            Column {
                                Text(text = "Kunci PIN Aplikasi", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                                Text(text = "Minta PIN saat aplikasi dibuka", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                            }
                        }
                        Switch(
                            checked = isPinEnabled,
                            onCheckedChange = { checked ->
                                if (checked) {
                                    showPinSetupDialog = true
                                } else {
                                    viewModel.togglePinLock(false)
                                }
                            }
                        )
                    }
                }
            }

            if (showPinSetupDialog) {
                val focusRequester = remember { FocusRequester() }
                LaunchedEffect(Unit) {
                    kotlinx.coroutines.delay(100)
                    focusRequester.requestFocus()
                }
                AlertDialog(
                    onDismissRequest = { showPinSetupDialog = false },
                    title = { Text(text = "Atur PIN Baru") },
                    text = {
                        Column {
                            Text(text = "Masukkan 6 digit PIN untuk mengamankan jurnal Anda.")
                            Spacer(modifier = Modifier.height(16.dp))
                            OutlinedTextField(
                                value = pinInput,
                                onValueChange = { if (it.length <= 6 && it.all { char -> char.isDigit() }) pinInput = it },
                                label = { Text("PIN Baru (6 Digit)") },
                                singleLine = true,
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                                modifier = Modifier.focusRequester(focusRequester)
                            )
                        }
                    },
                    confirmButton = {
                        Button(
                            onClick = {
                                if (pinInput.length == 6) {
                                    viewModel.updatePin(pinInput)
                                    showPinSetupDialog = false
                                    pinInput = ""
                                }
                            },
                            enabled = pinInput.length == 6
                        ) {
                            Text("Simpan PIN")
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { 
                            showPinSetupDialog = false 
                            pinInput = ""
                        }) {
                            Text("Batal")
                        }
                    }
                )
            }
            
            Spacer(modifier = Modifier.height(48.dp))
        }
    }
}
