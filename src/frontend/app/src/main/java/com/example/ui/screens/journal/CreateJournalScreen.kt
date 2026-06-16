package com.example.ui.screens.journal

import androidx.compose.animation.*

import android.Manifest
import android.content.Context
import android.location.Geocoder
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.google.android.gms.location.LocationServices
import java.io.File
import java.util.Locale

import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.data.model.JournalEntry
import com.example.ui.viewmodel.JournalViewModel
import java.util.UUID
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.material3.TabRow
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRowDefaults.SecondaryIndicator
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset

@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class, com.google.accompanist.permissions.ExperimentalPermissionsApi::class)
@Composable
fun CreateJournalScreen(
    viewModel: JournalViewModel,
    journalToEdit: com.example.data.model.JournalEntry? = null,
    onSaveSuccess: () -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = androidx.compose.ui.platform.LocalContext.current


    // Block-based Editor State
    val blocks = remember { 
        mutableStateListOf<JournalBlock>().apply {
            if (journalToEdit != null) {
                val parts = if (journalToEdit.content.contains("<!--BLOCK_DELIMITER-->")) {
                    journalToEdit.content.split("<!--BLOCK_DELIMITER-->")
                } else {
                    journalToEdit.content.split("<!--IMAGE_DELIMITER-->")
                }
                parts.forEach { part ->
                    when {
                        part.startsWith("IMAGE:") -> add(JournalBlock.ImageBlock(part.substringAfter("IMAGE:")))
                        part.startsWith("DIVIDER:") -> add(JournalBlock.DividerBlock())
                        part.startsWith("CHECKLIST:") -> {
                            val content = part.substringAfter("CHECKLIST:")
                            val isChecked = content.substringBefore("|") == "1"
                            val text = content.substringAfter("|")
                            add(JournalBlock.ChecklistBlock(text, isChecked))
                        }
                        part.isNotBlank() || parts.size == 1 -> {
                            val state = com.mohamedrejeb.richeditor.model.RichTextState()
                            state.setHtml(part)
                            add(JournalBlock.TextBlock(state))
                        }
                    }
                }
                if (isEmpty()) add(JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
            } else {
                add(JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
            }
        }
    }
    var activeBlockIndex by remember { mutableIntStateOf(0) }
    var currentLocationName by remember { mutableStateOf(journalToEdit?.location ?: "Mencari lokasi...") }
    
    // Media Attachments
    var cameraTempUri by remember { mutableStateOf<Uri?>(null) }
    val galleryLauncher = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) {
            val insertIdx = (activeBlockIndex + 1).coerceIn(0, blocks.size)
            blocks.add(insertIdx, JournalBlock.ImageBlock(uri.toString()))
            blocks.add(insertIdx + 1, JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
            activeBlockIndex = insertIdx + 1
        }
    }
    
    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        if (success && cameraTempUri != null) {
            val insertIdx = (activeBlockIndex + 1).coerceIn(0, blocks.size)
            blocks.add(insertIdx, JournalBlock.ImageBlock(cameraTempUri.toString()))
            blocks.add(insertIdx + 1, JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
            activeBlockIndex = insertIdx + 1
        }
    }

    var showMediaDropdown by remember { mutableStateOf(false) }

    // Location Permission & Fetch
    val locationPermissions = rememberMultiplePermissionsState(
        permissions = listOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
    )

    LaunchedEffect(Unit) {
        if (!locationPermissions.allPermissionsGranted) {
            locationPermissions.launchMultiplePermissionRequest()
        }
    }

    LaunchedEffect(locationPermissions.allPermissionsGranted) {
        if (locationPermissions.allPermissionsGranted && journalToEdit == null) {
            try {
                val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context.applicationContext)
                fusedLocationClient.lastLocation.addOnSuccessListener { loc ->
                    if (loc != null) {
                        try {
                            val geocoder = Geocoder(context, Locale.getDefault())
                            val addresses = geocoder.getFromLocation(loc.latitude, loc.longitude, 1)
                            if (!addresses.isNullOrEmpty()) {
                                currentLocationName = "${addresses[0].subAdminArea ?: addresses[0].locality}, ${addresses[0].countryCode}"
                            } else {
                                currentLocationName = "Lokasi tidak diketahui"
                            }
                        } catch (e: Exception) {
                            currentLocationName = "GPS Aktif (${loc.latitude}, ${loc.longitude})"
                        }
                    } else {
                        currentLocationName = "Gagal membaca GPS"
                    }
                }
            } catch (e: SecurityException) {
                currentLocationName = "Akses lokasi ditolak"
            }
        }
    }
    var title by remember { mutableStateOf(journalToEdit?.title ?: "") }
    var selectedMood by remember { mutableStateOf(journalToEdit?.userMood ?: "😌 Tenang") }
    val isAnalyzing by viewModel.isAnalyzing.collectAsState()

    var isSavedOrDiscarded by remember { mutableStateOf(false) }
    val currentTitle by rememberUpdatedState(title)
    val currentMood by rememberUpdatedState(selectedMood)
    val currentJournalToEdit by rememberUpdatedState(journalToEdit)
    
    val currentBlocks by rememberUpdatedState(blocks.toList())

    DisposableEffect(Unit) {
        onDispose {
            if (!isSavedOrDiscarded && currentTitle.isNotEmpty()) {
                val fullContent = currentBlocks.joinToString("<!--BLOCK_DELIMITER-->") { block ->
                    when (block) {
                        is JournalBlock.TextBlock -> block.state.toHtml()
                        is JournalBlock.ImageBlock -> "IMAGE:${block.uri}"
                        is JournalBlock.DividerBlock -> "DIVIDER:"
                        is JournalBlock.ChecklistBlock -> "CHECKLIST:${if (block.isChecked) "1" else "0"}|${block.text}"
                    }
                }
                val firstImage = currentBlocks.filterIsInstance<JournalBlock.ImageBlock>().firstOrNull()?.uri
                if (currentJournalToEdit != null) {
                    viewModel.updateJournal(
                        firestoreId = currentJournalToEdit!!.firestoreId,
                        title = currentTitle,
                        content = fullContent.ifEmpty { "Kisah hari ini..." },
                        userMood = currentMood,
                        photoUri = firstImage,
                        location = currentJournalToEdit!!.location,
                        isDraft = true
                    )
                } else {
                    viewModel.saveJournal(
                        title = currentTitle,
                        content = fullContent.ifEmpty { "Kisah hari ini..." },
                        userMood = currentMood,
                        photoUri = firstImage,
                        location = currentLocationName,
                        isDraft = true
                    )
                }
            }
        }
    }

    // Floating Side Toolbar UI state
    var showSideMenu by remember { mutableStateOf(false) }

    val moodEmojis = listOf(
        "😀 Bahagia",
        "😌 Tenang",
        "😐 Netral",
        "😰 Cemas",
        "😢 Sedih"
    )

    val naturePhotos = listOf(
        Pair("mock_hutan", "https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?auto=format&fit=crop&w=500&q=80"),
        Pair("mock_taman", "https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=500&q=80"),
        Pair("mock_teh", "https://images.unsplash.com/photo-1544787219-7f47ccb76574?auto=format&fit=crop&w=500&q=80"),
        Pair("mock_kopi", "https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&w=500&q=80")
    )

    // Helper to get active text block
    val activeTextBlock = blocks.getOrNull(activeBlockIndex) as? JournalBlock.TextBlock

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.surface)
            .padding(top = 16.dp, start = 16.dp, end = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // App top actions bar
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextButton(onClick = {
                onCancel()
            }) {
                Text(text = "Batal", color = Color.Gray, fontWeight = FontWeight.SemiBold)
            }
            Text(
                text = "Tulis Jurnal",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.ExtraBold)
            )
            Button(
                onClick = {
                    if (title.isNotEmpty()) {
                        // Serialize blocks with custom delimiter to preserve structure
                        val fullContent = blocks.joinToString("<!--BLOCK_DELIMITER-->") { block ->
                            when (block) {
                                is JournalBlock.TextBlock -> block.state.toHtml()
                                is JournalBlock.ImageBlock -> "IMAGE:${block.uri}"
                                is JournalBlock.DividerBlock -> "DIVIDER:"
                                is JournalBlock.ChecklistBlock -> "CHECKLIST:${if (block.isChecked) "1" else "0"}|${block.text}"
                            }
                        }
                        val firstImage = blocks.filterIsInstance<JournalBlock.ImageBlock>().firstOrNull()?.uri
                        
                        if (journalToEdit != null) {
                            viewModel.updateJournal(
                                firestoreId = journalToEdit.firestoreId,
                                title = title,
                                content = fullContent.ifEmpty { "Kisah hari ini..." },
                                userMood = selectedMood,
                                photoUri = firstImage,
                                location = journalToEdit.location
                            )
                        } else {
                            viewModel.saveJournal(
                                title = title,
                                content = fullContent.ifEmpty { "Kisah hari ini..." },
                                userMood = selectedMood,
                                photoUri = firstImage,
                                location = currentLocationName
                            )
                        }
                        isSavedOrDiscarded = true
                        onSaveSuccess()
                    }
                },
                enabled = title.isNotEmpty() && !isAnalyzing,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant,
                    contentColor = MaterialTheme.colorScheme.onSurface,
                    disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                ),
                shape = RoundedCornerShape(20.dp)
            ) {
                if (isAnalyzing) {
                    CircularProgressIndicator(color = MaterialTheme.colorScheme.primary, modifier = Modifier.size(16.dp))
                } else {
                    Text(text = "Simpan", fontWeight = FontWeight.Bold)
                }
            }
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Title Input
            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                placeholder = { Text("Judul Jurnal Anda...", color = Color.Gray) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                textStyle = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = Color.Gray,
                    unfocusedBorderColor = Color.LightGray,
                    focusedContainerColor = MaterialTheme.colorScheme.surface,
                    unfocusedContainerColor = MaterialTheme.colorScheme.surface
                ),
                shape = RoundedCornerShape(8.dp)
            )

            // GeoTag Widget
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.08f))
                    .padding(12.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.MyLocation,
                    contentDescription = "Geotag",
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Column {
                    Text(
                        text = "Lokasi Otomatis Aktif",
                        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = currentLocationName,
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.Gray
                    )
                }
            }

            // Mood Selection Row
            Text(
                text = "Bagaimana suasana hati Anda saat ini?",
                style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold)
            )
            LazyRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(moodEmojis) { mood ->
                    val isSel = selectedMood == mood
                    FilterChip(
                        selected = isSel,
                        onClick = { selectedMood = mood },
                        label = { Text(text = mood) },
                        shape = RoundedCornerShape(20.dp),
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                        ),
                        border = if (isSel) null else FilterChipDefaults.filterChipBorder(enabled = true, selected = false)
                    )
                }
            }

            // Formatting Toolbar
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)),
                elevation = CardDefaults.cardElevation(0.dp)
            ) {
                LazyRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val rState = activeTextBlock?.state

                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(fontWeight = FontWeight.Bold)) }) { Icon(Icons.Default.FormatBold, "Bold", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(fontStyle = androidx.compose.ui.text.font.FontStyle.Italic)) }) { Icon(Icons.Default.FormatItalic, "Italic", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(textDecoration = TextDecoration.Underline)) }) { Icon(Icons.Default.FormatUnderlined, "Underline", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(textDecoration = TextDecoration.LineThrough)) }) { Icon(Icons.Default.FormatStrikethrough, "Strikethrough", tint = Color.DarkGray) } }
                    
                    item { Spacer(modifier = Modifier.width(8.dp)) }
                    item { Divider(modifier = Modifier.height(24.dp).width(1.dp), color = Color.Gray) }
                    item { Spacer(modifier = Modifier.width(8.dp)) }

                    item { IconButton(onClick = { rState?.toggleParagraphStyle(androidx.compose.ui.text.ParagraphStyle(textAlign = TextAlign.Left)) }) { Icon(Icons.Default.FormatAlignLeft, "Align Left", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleParagraphStyle(androidx.compose.ui.text.ParagraphStyle(textAlign = TextAlign.Center)) }) { Icon(Icons.Default.FormatAlignCenter, "Align Center", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleParagraphStyle(androidx.compose.ui.text.ParagraphStyle(textAlign = TextAlign.Right)) }) { Icon(Icons.Default.FormatAlignRight, "Align Right", tint = Color.DarkGray) } }

                    item { Spacer(modifier = Modifier.width(8.dp)) }
                    item { Divider(modifier = Modifier.height(24.dp).width(1.dp), color = Color.Gray) }
                    item { Spacer(modifier = Modifier.width(8.dp)) }

                    item { IconButton(onClick = { rState?.toggleUnorderedList() }) { Icon(Icons.Default.FormatListBulleted, "Bullets", tint = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleOrderedList() }) { Icon(Icons.Default.FormatListNumbered, "Numbers", tint = Color.DarkGray) } }

                    item { Spacer(modifier = Modifier.width(8.dp)) }
                    item { Divider(modifier = Modifier.height(24.dp).width(1.dp), color = Color.Gray) }
                    item { Spacer(modifier = Modifier.width(8.dp)) }
                    
                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(fontSize = 24.sp, fontWeight = FontWeight.Bold)) }) { Text("H1", fontWeight = FontWeight.Bold, color = Color.DarkGray) } }
                    item { IconButton(onClick = { rState?.toggleSpanStyle(androidx.compose.ui.text.SpanStyle(fontSize = 20.sp, fontWeight = FontWeight.Bold)) }) { Text("H2", fontWeight = FontWeight.Bold, color = Color.DarkGray) } }
                    
                    item { Spacer(modifier = Modifier.width(8.dp)) }
                    item { Divider(modifier = Modifier.height(24.dp).width(1.dp), color = Color.Gray) }
                    item { Spacer(modifier = Modifier.width(8.dp)) }

                    item { 
                        Box {
                            IconButton(onClick = { showMediaDropdown = true }) { 
                                Icon(Icons.Default.Image, "Insert Image", tint = MaterialTheme.colorScheme.primary) 
                            }
                            DropdownMenu(
                                expanded = showMediaDropdown,
                                onDismissRequest = { showMediaDropdown = false }
                            ) {
                                DropdownMenuItem(
                                    text = { Text("Pilih dari Galeri") },
                                    leadingIcon = { Icon(Icons.Default.PhotoLibrary, "Gallery") },
                                    onClick = {
                                        showMediaDropdown = false
                                        galleryLauncher.launch(androidx.activity.result.PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                                    }
                                )
                                DropdownMenuItem(
                                    text = { Text("Buka Kamera") },
                                    leadingIcon = { Icon(Icons.Default.CameraAlt, "Camera") },
                                    onClick = {
                                        showMediaDropdown = false
                                        val imagePath = File(context.cacheDir, "images")
                                        imagePath.mkdirs()
                                        val tempFile = File.createTempFile("journal_cam_", ".jpg", imagePath)
                                        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", tempFile)
                                        cameraTempUri = uri
                                        cameraLauncher.launch(uri)
                                    }
                                )
                            }
                        }
                    }
                    item { 
                        IconButton(onClick = { 
                            val insertIdx = (activeBlockIndex + 1).coerceIn(0, blocks.size)
                            blocks.add(insertIdx, JournalBlock.ChecklistBlock())
                            blocks.add(insertIdx + 1, JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
                            activeBlockIndex = insertIdx + 1
                        }) { Icon(Icons.Default.CheckBox, "Insert Checklist", tint = MaterialTheme.colorScheme.primary) } 
                    }
                    item { 
                        IconButton(onClick = { 
                            val insertIdx = (activeBlockIndex + 1).coerceIn(0, blocks.size)
                            blocks.add(insertIdx, JournalBlock.DividerBlock())
                            blocks.add(insertIdx + 1, JournalBlock.TextBlock(com.mohamedrejeb.richeditor.model.RichTextState()))
                            activeBlockIndex = insertIdx + 1
                        }) { Icon(Icons.Default.HorizontalRule, "Insert Divider", tint = MaterialTheme.colorScheme.primary) } 
                    }
                }
            }

            // Editor Area with Floating Side Toolbar
            Box(modifier = Modifier.fillMaxWidth()) {
                // Editor Core
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 250.dp)
                        .border(2.dp, MaterialTheme.colorScheme.primary, RoundedCornerShape(12.dp))
                        .padding(16.dp)
                        .padding(end = 40.dp) // Space for floating toolbar
                ) {
                    blocks.forEachIndexed { index, block ->
                        when (block) {
                            is JournalBlock.TextBlock -> {
                                com.mohamedrejeb.richeditor.ui.material3.RichTextEditor(
                                    state = block.state,
                                    modifier = Modifier.fillMaxWidth().onFocusChanged { state ->
                                        if (state.isFocused) activeBlockIndex = index
                                    },
                                    placeholder = {
                                        if (index == 0 && blocks.size == 1) {
                                            Text("Tuliskan perasaan atau kejadian menarik hari ini secara luwes...", color = Color.Gray)
                                        }
                                    },
                                    colors = com.mohamedrejeb.richeditor.ui.material3.RichTextEditorDefaults.richTextEditorColors(
                                        containerColor = Color.Transparent,
                                        focusedIndicatorColor = Color.Transparent,
                                        unfocusedIndicatorColor = Color.Transparent
                                    )
                                )
                            }
                            is JournalBlock.ImageBlock -> {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(180.dp)
                                        .padding(vertical = 8.dp)
                                        .clip(RoundedCornerShape(12.dp))
                                ) {
                                    AsyncImage(
                                        model = block.uri,
                                        contentDescription = "Inline attachment",
                                        modifier = Modifier.fillMaxSize(),
                                        contentScale = ContentScale.Crop
                                    )
                                    IconButton(
                                        onClick = { blocks.removeAt(index) },
                                        modifier = Modifier.align(Alignment.TopEnd).padding(4.dp).background(Color.Black.copy(alpha = 0.5f), CircleShape)
                                    ) {
                                        Icon(Icons.Default.Clear, "Remove", tint = Color.White, modifier = Modifier.size(16.dp))
                                    }
                                }
                            }
                            is JournalBlock.DividerBlock -> {
                                Box(modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
                                    Divider(color = MaterialTheme.colorScheme.outlineVariant)
                                    IconButton(
                                        onClick = { blocks.removeAt(index) },
                                        modifier = Modifier.align(Alignment.TopEnd).size(24.dp)
                                    ) {
                                        Icon(Icons.Default.Clear, "Remove", tint = Color.Gray)
                                    }
                                }
                            }
                                is JournalBlock.ChecklistBlock -> {
                                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                                        Checkbox(checked = block.isChecked, onCheckedChange = { 
                                            blocks[index] = block.copy(isChecked = it)
                                        })
                                        OutlinedTextField(
                                            value = block.text,
                                            onValueChange = { 
                                                blocks[index] = block.copy(text = it)
                                            },
                                            modifier = Modifier.fillMaxWidth().weight(1f),
                                            colors = OutlinedTextFieldDefaults.colors(
                                                focusedBorderColor = Color.Transparent,
                                                unfocusedBorderColor = Color.Transparent
                                            ),
                                            textStyle = MaterialTheme.typography.bodyLarge.copy(
                                                textDecoration = if (block.isChecked) TextDecoration.LineThrough else TextDecoration.None
                                            ),
                                            placeholder = { Text("Tugas...") },
                                            trailingIcon = {
                                                IconButton(onClick = { blocks.removeAt(index) }) {
                                                    Icon(Icons.Default.Clear, "Remove", tint = Color.Gray)
                                                }
                                            }
                                        )
                                    }
                                }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}
