package com.example.ui.screens.journal

import androidx.compose.animation.*
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

@Composable
fun JournalListScreen(
    viewModel: JournalViewModel,
    onJournalSelected: (JournalEntry) -> Unit,
    onWriteNewClicked: () -> Unit,
    modifier: Modifier = Modifier
) {
    val journals by viewModel.allJournals.collectAsState()
    val drafts by viewModel.allDrafts.collectAsState()
    
    var searchQuery by remember { mutableStateOf("") }
    var selectedMoodFilter by remember { mutableStateOf("Semua") }
    var selectedMonthFilter by remember { mutableStateOf("Semua Bulan") }
    var selectedTabIndex by remember { mutableStateOf(0) } // 0: Jurnal, 1: Draft

    val moodCategories = listOf("Semua", "😀 Bahagia", "😌 Tenang", "😐 Netral", "😰 Cemas", "😢 Sedih")

    val activeList = if (selectedTabIndex == 0) journals else drafts
    
    val monthFormat = remember { java.text.SimpleDateFormat("MMMM yyyy", java.util.Locale("id", "ID")) }
    val availableMonths = remember(activeList) {
        listOf("Semua Bulan") + activeList.map { monthFormat.format(java.util.Date(it.timestamp)) }.distinct()
    }

    val filteredJournals = activeList.filter { journal ->
        val matchesSearch = journal.title.contains(searchQuery, ignoreCase = true) || 
                            journal.content.contains(searchQuery, ignoreCase = true)
        val matchesMood = selectedMoodFilter == "Semua" || journal.userMood == selectedMoodFilter
        val matchesMonth = selectedMonthFilter == "Semua Bulan" || monthFormat.format(java.util.Date(journal.timestamp)) == selectedMonthFilter
        matchesSearch && matchesMood && matchesMonth
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Header with hidden drafts toggle
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = if (selectedTabIndex == 0) "Jurnal Publik" else "Draft Tersimpan",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                color = MaterialTheme.colorScheme.onBackground
            )
            TextButton(
                onClick = { selectedTabIndex = if (selectedTabIndex == 0) 1 else 0 },
                modifier = Modifier.padding(0.dp)
            ) {
                Text(
                    text = if (selectedTabIndex == 0) "Drafts" else "Kembali",
                    style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.7f)
                )
            }
        }

        // Search bar
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { searchQuery = it },
            placeholder = { Text("Cari judul atau isi jurnal...") },
            leadingIcon = { Icon(imageVector = Icons.Default.Search, contentDescription = "Search") },
            trailingIcon = {
                if (searchQuery.isNotEmpty()) {
                    IconButton(onClick = { searchQuery = "" }) {
                        Icon(imageVector = Icons.Default.Clear, contentDescription = "Clear")
                    }
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .testTag("journal_search_input"),
            shape = RoundedCornerShape(16.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = MaterialTheme.colorScheme.surface,
                unfocusedContainerColor = MaterialTheme.colorScheme.surface
            )
        )

        // Filter chips list (Months)
        LazyRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(availableMonths) { month ->
                val isSelected = selectedMonthFilter == month
                FilterChip(
                    selected = isSelected,
                    onClick = { selectedMonthFilter = month },
                    label = { 
                        Text(
                            text = month,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                        ) 
                    },
                    shape = RoundedCornerShape(20.dp)
                )
            }
        }

        // Filter chips list (Mood)
        LazyRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(moodCategories) { filter ->
                val isSelected = selectedMoodFilter == filter
                FilterChip(
                    selected = isSelected,
                    onClick = { selectedMoodFilter = filter },
                    label = { 
                        Text(
                            text = filter,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                        ) 
                    },
                    shape = RoundedCornerShape(20.dp)
                )
            }
        }

        // Journal Cards lists
        if (filteredJournals.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.ImportContacts,
                        contentDescription = "No Journals",
                        tint = Color.Gray,
                        modifier = Modifier.size(64.dp)
                    )
                    Text(
                        text = "Tidak Ada Jurnal Ditemukan",
                        fontWeight = FontWeight.Bold,
                        color = Color.Gray
                    )
                    Text(
                        text = "Tambahkan kisah Anda sekarang untuk memulai rekapitulasi data pemicu stres cerdas.",
                        textAlign = TextAlign.Center,
                        color = Color.Gray.copy(alpha = 0.7f),
                        modifier = Modifier.padding(horizontal = 32.dp),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(filteredJournals) { journal ->
                    JournalCardEntity(
                        journal = journal,
                        onClick = { onJournalSelected(journal) }
                    )
                }
            }
        }
    }
}

@Composable
fun JournalCardEntity(
    journal: JournalEntry,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .testTag("journal_item_${journal.id}"),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = journal.date,
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.Gray
                )
                // Geotag locale
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.LocationOn,
                        contentDescription = "Location",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(12.dp)
                    )
                    Spacer(modifier = Modifier.width(2.dp))
                    Text(
                        text = journal.location,
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.Gray,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            Text(
                text = journal.title,
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.ExtraBold),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            val parts = if (journal.content.contains("<!--BLOCK_DELIMITER-->")) {
                journal.content.split("<!--BLOCK_DELIMITER-->")
            } else {
                journal.content.split("<!--IMAGE_DELIMITER-->")
            }
            val firstText = parts.firstOrNull { 
                !it.startsWith("IMAGE:") && !it.startsWith("DIVIDER:") && !it.startsWith("CHECKLIST:") 
            } ?: ""
            val firstImage = parts.firstOrNull { it.startsWith("IMAGE:") }?.removePrefix("IMAGE:") ?: journal.photoUri
            
            val richTextState = com.mohamedrejeb.richeditor.model.rememberRichTextState()
            LaunchedEffect(firstText) {
                richTextState.setHtml(firstText)
            }
            com.mohamedrejeb.richeditor.ui.material3.RichText(
                state = richTextState,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            // Optional card photo teaser
            if (firstImage != null && firstImage.isNotBlank()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(80.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color.LightGray)
                ) {
                    val finalImage = if (firstImage.startsWith("mock_taman")) {
                        "https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=500&q=80"
                    } else if (firstImage.startsWith("mock_sahabat")) {
                        "https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?auto=format&fit=crop&w=500&q=80"
                    } else {
                        firstImage
                    }

                    coil.compose.AsyncImage(
                        model = finalImage,
                        contentDescription = "Journal Attachment Preview",
                        modifier = Modifier.fillMaxSize(),
                        contentScale = androidx.compose.ui.layout.ContentScale.Crop
                    )
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // User input mood badge
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(50))
                        .background(MaterialTheme.colorScheme.secondary.copy(alpha = 0.15f))
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Text(
                        text = journal.userMood,
                        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.secondary
                    )
                }

                // AI Mood Analysis badge if cached
                if (journal.aiMoodPrimary != null) {
                    val badgeColor = when (journal.aiMoodPrimary) {
                        "Bahagia" -> Color(0xFF81C784)
                        "Tenang" -> Color(0xFF64B5F6)
                        "Netral" -> Color(0xFFFFD54F)
                        "Cemas" -> Color(0xFFFFB74D)
                        "Sedih" -> Color(0xFFE57373)
                        else -> Color.Gray
                    }
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.AutoAwesome,
                            contentDescription = "AI",
                            tint = badgeColor,
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            text = "AI: ${journal.aiMoodPrimary}",
                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                            color = badgeColor
                        )
                    }
                }
            }
        }
    }
}


