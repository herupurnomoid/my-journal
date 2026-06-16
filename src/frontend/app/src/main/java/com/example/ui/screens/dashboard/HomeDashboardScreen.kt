package com.example.ui.screens.dashboard

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
import coil.compose.AsyncImage
import androidx.compose.ui.layout.ContentScale

@Composable
fun HomeDashboardScreen(
    viewModel: JournalViewModel,
    onWriteQuickJournal: () -> Unit,
    onNavigateToMoodCalendar: () -> Unit,
    onNavigateToRecommendations: () -> Unit,
    onJournalSelected: (JournalEntry) -> Unit,
    modifier: Modifier = Modifier
) {
    val journals by viewModel.allJournals.collectAsState()
    val journalCountVal by viewModel.journalCount.collectAsState()
    val userProfile by viewModel.userProfile.collectAsState()
    
    // Quick calculations for statistics
    val todayMood = journals.firstOrNull()?.userMood ?: "Belum Menulis Jurnal"
    val avgStress = if (journals.isNotEmpty()) journals.map { it.aiStressLevel ?: 30 }.average().toInt() else 0
    val avgHappiness = if (journals.isNotEmpty()) journals.map { it.aiHappinessLevel ?: 70 }.average().toInt() else 0

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Greeting & UTC
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                val firstName = userProfile?.name?.split(" ")?.firstOrNull() ?: "Reflektor"
                Text(
                    text = "Halo, $firstName",
                    style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.ExtraBold),
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = "Semoga jiwa Anda tenteram hari ini.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )
            }
            val avatarUrl = userProfile?.avatarUrl
            if (avatarUrl != null && avatarUrl.isNotEmpty()) {
                AsyncImage(
                    model = avatarUrl,
                    contentDescription = "Foto Profil",
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape),
                    contentScale = ContentScale.Crop
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.secondary.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = "Profile",
                        tint = MaterialTheme.colorScheme.secondary
                    )
                }
            }
        }

        // Today's Mood Ring Card
        // Today's Mood Ring Card (Sleek Blue container)
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(28.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            ),
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "MOOD HARI INI",
                            style = MaterialTheme.typography.labelSmall.copy(
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 1.sp
                            ),
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(bottom = 2.dp)
                        )
                        Text(
                            text = if (todayMood == "Belum Menulis Jurnal") "Belum Menulis Jurnal" else "\"$todayMood\"",
                            style = MaterialTheme.typography.titleLarge.copy(
                                fontWeight = FontWeight.ExtraBold,
                                fontFamily = FontFamily.SansSerif
                            ),
                            color = MaterialTheme.colorScheme.primary
                        )
                    }

                    Text(
                        text = if (todayMood.contains("Bahagia") || todayMood.contains("Senang")) "😌" else "😌",
                        style = MaterialTheme.typography.headlineLarge,
                        fontSize = 36.sp
                    )
                }

                // Progress Bar (Sleek capsule design)
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(6.dp)
                        .clip(RoundedCornerShape(3.dp))
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.2f))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .fillMaxWidth(0.75f)
                            .background(MaterialTheme.colorScheme.primary)
                    )
                }

                Text(
                    text = "Kamu merasa lebih stabil dibanding kemarin.",
                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.8f)
                )
            }
        }

        // AI Recommendation card (Sleek Purple container matching Gemini suggestion aesthetics)
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onNavigateToRecommendations() },
            shape = RoundedCornerShape(28.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.secondaryContainer
            ),
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.secondary.copy(alpha = 0.2f)),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(MaterialTheme.colorScheme.secondary)
                                .padding(6.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.AutoAwesome,
                                contentDescription = "Gemini Icon",
                                tint = Color.White,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                        Text(
                            text = "REKOMENDASI GEMINI AI",
                            style = MaterialTheme.typography.labelSmall.copy(
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 1.sp
                            ),
                            color = MaterialTheme.colorScheme.secondary
                        )
                    }
                    Icon(
                        imageVector = Icons.Default.ArrowOutward,
                        contentDescription = "Open suggestions",
                        tint = MaterialTheme.colorScheme.secondary,
                        modifier = Modifier.size(16.dp)
                    )
                }
                
                val latestRec = journals.firstOrNull()?.aiRecommendations?.split("|")?.firstOrNull() ?: "Mulailah menulis kisah reflektif hari ini agar Gemini AI dapat memberikan insight kebahagiaan mental untuk Anda."
                
                Text(
                    text = latestRec,
                    style = MaterialTheme.typography.bodyMedium.copy(lineHeight = 20.sp),
                    color = MaterialTheme.colorScheme.secondary,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }

        // Quick Stats Grid Cards (Tailwind card border border-slate-100 shadow-sm rounded-3xl)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Stat 1: Total Entries (Jurnal)
            Card(
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.05f)),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "JURNAL",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, letterSpacing = 0.5.sp),
                        color = Color.Gray
                    )
                    Text(
                        text = "$journalCountVal",
                        style = MaterialTheme.typography.headlineLarge.copy(fontWeight = FontWeight.ExtraBold),
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "+5 Bulan Ini",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = Color(0xFF16A34A) // tailwind green-600
                    )
                }
            }

            // Stat 2: Streak (Active hot streak)
            Card(
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.05f)),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "STREAK",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, letterSpacing = 0.5.sp),
                        color = Color.Gray
                    )
                    Text(
                        text = "${if (journalCountVal > 0) (journalCountVal * 2 + 2) else 0} 🔥",
                        style = MaterialTheme.typography.headlineLarge.copy(fontWeight = FontWeight.ExtraBold),
                        color = MaterialTheme.colorScheme.tertiary
                    )
                    Text(
                        text = "Hari berturut-turut",
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.Gray
                    )
                }
            }
        }

        // Mini Calendar mood tracker header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Mood Tracker Kalender",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
            )
            TextButton(onClick = onNavigateToMoodCalendar) {
                Text(text = "Buka Kalender")
            }
        }

        // Mini calendar (Last 7 days)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            val last7Days = mutableListOf<java.util.Calendar>()
            for (i in 6 downTo 0) {
                val dayCal = java.util.Calendar.getInstance()
                dayCal.add(java.util.Calendar.DAY_OF_YEAR, -i)
                last7Days.add(dayCal)
            }

            val dayLabels = listOf("Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab")

            val colorGreen = Color(0xFF81C784)
            val colorBlue = Color(0xFF64B5F6)
            val colorYellow = Color(0xFFFFD54F)
            val colorOrange = Color(0xFFFFB74D)
            val colorRed = Color(0xFFE57373)

            for (idx in 0 until 7) {
                val dayCal = last7Days[idx]
                val dayOfWeek = dayCal.get(java.util.Calendar.DAY_OF_WEEK)
                val dayNum = dayCal.get(java.util.Calendar.DAY_OF_MONTH)
                val dayLabelStr = dayLabels[dayOfWeek - 1]

                // Find journal for this day
                val matchedJournal = journals.firstOrNull { j ->
                    val jCal = java.util.Calendar.getInstance()
                    jCal.timeInMillis = j.timestamp
                    jCal.get(java.util.Calendar.YEAR) == dayCal.get(java.util.Calendar.YEAR) &&
                    jCal.get(java.util.Calendar.DAY_OF_YEAR) == dayCal.get(java.util.Calendar.DAY_OF_YEAR)
                }

                val col = if (matchedJournal != null) {
                    val m = matchedJournal.userMood.lowercase()
                    if (m.contains("bahagia") || m.contains("senang") || m.contains("\uD83D\uDE00")) colorGreen
                    else if (m.contains("tenang") || m.contains("damai") || m.contains("\uD83D\uDE0C")) colorBlue
                    else if (m.contains("netral") || m.contains("lempeng") || m.contains("\uD83D\uDE10")) colorYellow
                    else if (m.contains("cemas") || m.contains("panik") || m.contains("\uD83D\uDE30") || m.contains("anxious")) colorOrange
                    else if (m.contains("sedih") || m.contains("murung") || m.contains("\uD83D\uDE22")) colorRed
                    else colorYellow
                } else {
                    Color.LightGray
                }

                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(text = dayLabelStr, style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(if (matchedJournal != null) col.copy(alpha = 0.2f) else Color.Transparent)
                            .border(BorderStroke(if (matchedJournal != null) 2.dp else 1.dp, col), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "$dayNum",
                            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                            color = col
                        )
                    }
                }
            }
        }

        // Recent Entries list
        Text(
            text = "Catatan Jurnal Terbaru",
            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
            modifier = Modifier.padding(top = 8.dp)
        )

        if (journals.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "Belum ada tulisan jurnal. Sentuh tombol di kanan bawah.", color = Color.Gray)
            }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                for (j in journals.take(2)) {
                    Card(
                        onClick = { onJournalSelected(j) },
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            val parts = if (j.content.contains("<!--BLOCK_DELIMITER-->")) {
                                j.content.split("<!--BLOCK_DELIMITER-->")
                            } else {
                                j.content.split("<!--IMAGE_DELIMITER-->")
                            }
                            val firstText = parts.firstOrNull { 
                                !it.startsWith("IMAGE:") && !it.startsWith("DIVIDER:") && !it.startsWith("CHECKLIST:") 
                            } ?: ""
                            val firstImage = parts.firstOrNull { it.startsWith("IMAGE:") }?.removePrefix("IMAGE:") ?: j.photoUri
                            
                            Column(modifier = Modifier.weight(1f)) {
                                Text(text = j.date, style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(text = j.title, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                Spacer(modifier = Modifier.height(4.dp))
                                
                                val richTextState = com.mohamedrejeb.richeditor.model.rememberRichTextState()
                                LaunchedEffect(firstText) {
                                    richTextState.setHtml(firstText)
                                }
                                com.mohamedrejeb.richeditor.ui.material3.RichText(
                                    state = richTextState,
                                    style = MaterialTheme.typography.bodySmall,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            if (firstImage != null && firstImage.isNotBlank()) {
                                coil.compose.AsyncImage(
                                    model = firstImage,
                                    contentDescription = "Thumbnail",
                                    modifier = Modifier
                                        .size(48.dp)
                                        .clip(RoundedCornerShape(8.dp)),
                                    contentScale = androidx.compose.ui.layout.ContentScale.Crop
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                            }
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(MaterialTheme.colorScheme.primaryContainer)
                                    .padding(8.dp)
                            ) {
                                Text(text = j.userMood.split(" ").firstOrNull() ?: "📝")
                            }
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(48.dp)) // padding for floating button
    }
}

