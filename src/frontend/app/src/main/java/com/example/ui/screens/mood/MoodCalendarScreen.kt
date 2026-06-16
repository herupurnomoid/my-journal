package com.example.ui.screens.mood

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.viewmodel.JournalViewModel

@Composable
fun MoodCalendarScreen(
    viewModel: JournalViewModel,
    modifier: Modifier = Modifier
) {
    val journals by viewModel.allJournals.collectAsState()

    val calendar = remember { java.util.Calendar.getInstance() }
    val monthSdf = java.text.SimpleDateFormat("MMMM yyyy", java.util.Locale("id", "ID"))
    var selectedMonth by remember { mutableStateOf(monthSdf.format(calendar.time)) }
    var selectedDayLog by remember { mutableStateOf<String?>(null) }

    // Color definitions for calendar
    val colorGreen = Color(0xFF81C784)  // Bahagia
    val colorBlue = Color(0xFF64B5F6)   // Tenang
    val colorYellow = Color(0xFFFFD54F) // Netral
    val colorOrange = Color(0xFFFFB74D) // Cemas
    val colorRed = Color(0xFFE57373)    // Sedih

    val daysInMonth = calendar.getActualMaximum(java.util.Calendar.DAY_OF_MONTH)
    val currentMonth = calendar.get(java.util.Calendar.MONTH)
    val currentYear = calendar.get(java.util.Calendar.YEAR)

    // Map journals to days of current month
    val dayMoods = remember(journals) {
        val map = mutableMapOf<Int, Pair<Color, String>>()
        for (j in journals) {
            val jCal = java.util.Calendar.getInstance()
            jCal.timeInMillis = j.timestamp
            if (jCal.get(java.util.Calendar.MONTH) == currentMonth && jCal.get(java.util.Calendar.YEAR) == currentYear) {
                val day = jCal.get(java.util.Calendar.DAY_OF_MONTH)
                val m = j.userMood.lowercase()
                val col = if (m.contains("bahagia") || m.contains("senang") || m.contains("\uD83D\uDE00")) colorGreen
                else if (m.contains("tenang") || m.contains("damai") || m.contains("\uD83D\uDE0C")) colorBlue
                else if (m.contains("netral") || m.contains("lempeng") || m.contains("\uD83D\uDE10")) colorYellow
                else if (m.contains("cemas") || m.contains("panik") || m.contains("\uD83D\uDE30") || m.contains("anxious")) colorOrange
                else if (m.contains("sedih") || m.contains("murung") || m.contains("\uD83D\uDE22")) colorRed
                else colorYellow
                
                map[day] = Pair(col, "${j.title} (${j.userMood})")
            }
        }
        map
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Month Selector Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Kalender Mood Tracker",
                style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.ExtraBold),
                color = MaterialTheme.colorScheme.primary
            )
            IconButton(onClick = {}) {
                Icon(imageVector = Icons.Default.CalendarToday, contentDescription = "Select Date")
            }
        }

        Text(
            text = "Setiap tanggal diisi dengan penanda warna emosional jurnal harian Anda.",
            style = MaterialTheme.typography.bodyMedium,
            color = Color.Gray
        )

        // Month selector slide
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = {}) { Icon(imageVector = Icons.Default.ChevronLeft, contentDescription = "Prev") }
                Text(text = selectedMonth, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                IconButton(onClick = {}) { Icon(imageVector = Icons.Default.ChevronRight, contentDescription = "Next") }
            }
        }

        // Days Grid (Traditional 5x6 grid)
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                // Calendar Weekday labels
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    val daysLabels = listOf("S", "S", "R", "K", "J", "S", "M")
                    for (day in daysLabels) {
                        Text(
                            text = day,
                            modifier = Modifier.weight(1f),
                            textAlign = TextAlign.Center,
                            style = MaterialTheme.typography.labelSmall,
                            color = Color.Gray,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                // Grid Cells
                var dayCounter = 1
                for (row in 0 until 5) {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        for (col in 0 until 7) {
                            if (dayCounter <= daysInMonth) {
                                val currentDay = dayCounter
                                val moodData = dayMoods[currentDay]
                                
                                val cellBgColor = moodData?.first?.copy(alpha = 0.15f) ?: Color.LightGray.copy(alpha = 0.1f)
                                val cellBorderColor = moodData?.first ?: Color.Transparent
                                val textColor = moodData?.first ?: Color.Gray
                                
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .aspectRatio(1f)
                                        .padding(4.dp)
                                        .clip(CircleShape)
                                        .background(cellBgColor)
                                        .border(BorderStroke(if (moodData != null) 2.dp else 0.dp, cellBorderColor), CircleShape)
                                        .clickable(enabled = moodData != null) {
                                            if (moodData != null) {
                                                selectedDayLog = "Log Hari $currentDay: ${moodData.second}"
                                            }
                                        },
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = "$currentDay",
                                        fontWeight = FontWeight.Bold,
                                        color = textColor,
                                        fontSize = 14.sp
                                    )
                                }
                                dayCounter++
                            } else {
                                Spacer(modifier = Modifier.weight(1f))
                            }
                        }
                    }
                }
            }
        }

        // Color Legend keys description block
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                val moodsLegend = listOf(
                    Pair(colorGreen, "Bahagia"),
                    Pair(colorBlue, "Tenang"),
                    Pair(colorYellow, "Netral"),
                    Pair(colorOrange, "Cemas"),
                    Pair(colorRed, "Sedih")
                )
                for ((col, lbl) in moodsLegend) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        Box(modifier = Modifier.size(10.dp).clip(CircleShape).background(col))
                        Text(text = lbl, fontSize = 11.sp, color = Color.Gray, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        // Clicked Interactive log detail drawer
        if (selectedDayLog != null) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.4f))
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(text = selectedDayLog!!, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.secondary)
                    IconButton(onClick = { selectedDayLog = null }) {
                        Icon(imageVector = Icons.Default.Close, contentDescription = "Close")
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(32.dp))
    }
}
