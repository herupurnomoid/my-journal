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

@Composable
fun MoodInsightDashboardScreen(
    viewModel: JournalViewModel,
    modifier: Modifier = Modifier
) {
    val journals by viewModel.allJournals.collectAsState()
    val weeklyInsights by viewModel.weeklyInsights.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.fetchWeeklyInsights()
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Title block
        Column {
            Text(
                text = "Dashboard Analisis Mood",
                style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.ExtraBold),
                color = MaterialTheme.colorScheme.primary
            )
            Text(
                text = "Statistik akurat kestabilan mental Anda oleh Gemini AI.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
            )
        }

        // Gemini AI Insight Summary Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f)),
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.2f))
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.AutoAwesome,
                        contentDescription = "Gemini",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Analisis Keseimbangan Emosional",
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.primary
                    )
                }
                Spacer(modifier = Modifier.height(12.dp))
                val summaryText = if (journals.isNotEmpty()) {
                    weeklyInsights ?: "Memuat ringkasan insight mingguan dari AI..."
                } else {
                    "Tulis jurnal pertama Anda esok hari agar Gemini AI dapat merangkum visualisasi emosional bulanan disini secara detail."
                }
                Text(
                    text = summaryText,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }

        // Graphic chart 1: Weekly Mood Trend (Custom Canvas Draw)
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text(
                    text = "Tren Kestabilan Suasana Hati (Mingguan)",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                )
                Text(
                    text = "Grafik korelasi kebahagiaan (garis biru) vs stres (garis merah)",
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.Gray
                )
                
                // Dynamic data coordinates
                val steps = 6
                val recentJournals = journals.take(steps).reversed()
                
                val happyPoints = mutableListOf<Float>()
                val stressPoints = mutableListOf<Float>()
                val dynamicLabels = mutableListOf<String>()
                val sdf = java.text.SimpleDateFormat("EEE", java.util.Locale("id", "ID"))
                
                for (j in recentJournals) {
                    happyPoints.add(j.aiHappinessLevel?.toFloat() ?: 50f)
                    stressPoints.add(j.aiStressLevel?.toFloat() ?: 50f)
                    dynamicLabels.add(sdf.format(java.util.Date(j.timestamp)))
                }
                
                // Pad if less than 6
                while (happyPoints.size < steps) {
                    happyPoints.add(0, 50f)
                    stressPoints.add(0, 50f)
                    dynamicLabels.add(0, "-")
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Canvas line graph simulation
                val primaryColor = MaterialTheme.colorScheme.primary
                Canvas(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(150.dp)
                ) {
                    val width = size.width
                    val height = size.height

                    // Draw grid lines
                    for (i in 1..4) {
                        val y = height * i / 5
                        drawLine(
                            color = Color.LightGray.copy(alpha = 0.4f),
                            start = androidx.compose.ui.geometry.Offset(0f, y),
                            end = androidx.compose.ui.geometry.Offset(width, y),
                            strokeWidth = 2f
                        )
                    }

                    val happyPath = Path()
                    val stressPath = Path()

                    for (idx in 0 until steps) {
                        val x = width * idx / (steps - 1)
                        // invert percentage since y is downward in canvas coordinates
                        val yHappy = height * (100f - happyPoints[idx]) / 100f
                        val yStress = height * (100f - stressPoints[idx]) / 100f

                        if (idx == 0) {
                            happyPath.moveTo(x, yHappy)
                            stressPath.moveTo(x, yStress)
                        } else {
                            happyPath.lineTo(x, yHappy)
                            stressPath.lineTo(x, yStress)
                        }
                    }

                    // Draw Happy Line (Blue/Primary)
                    drawPath(
                        path = happyPath,
                        color = primaryColor,
                        style = Stroke(width = 6f)
                    )

                    // Draw Stress Line (Red)
                    drawPath(
                        path = stressPath,
                        color = Color(0xFFE57373),
                        style = Stroke(width = 4f)
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    for (lbl in dynamicLabels) {
                        Text(text = lbl, style = MaterialTheme.typography.labelMedium, color = Color.Gray)
                    }
                }
            }
        }

        // Percentage distribution card (Monthly Pie Chart simulator)
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = "Daftar Persentase Emosi",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                )

                // Dynamic distribution bars
                val totalJournals = journals.size.toFloat()
                
                var countBahagia = 0
                var countTenang = 0
                var countNetral = 0
                var countCemas = 0
                var countSedih = 0

                for (j in journals) {
                    val m = j.userMood.lowercase()
                    if (m.contains("bahagia") || m.contains("senang") || m.contains("\uD83D\uDE00")) countBahagia++
                    else if (m.contains("tenang") || m.contains("damai") || m.contains("\uD83D\uDE0C")) countTenang++
                    else if (m.contains("netral") || m.contains("lempeng") || m.contains("\uD83D\uDE10")) countNetral++
                    else if (m.contains("cemas") || m.contains("panik") || m.contains("\uD83D\uDE30") || m.contains("anxious")) countCemas++
                    else if (m.contains("sedih") || m.contains("murung") || m.contains("\uD83D\uDE22")) countSedih++
                    else countNetral++
                }

                val safeTotal = if (totalJournals > 0) totalJournals else 1f

                val moods = listOf(
                    Triple("Bahagia (Senang)", countBahagia / safeTotal, Color(0xFF81C784)),
                    Triple("Tenang (Berdamai)", countTenang / safeTotal, Color(0xFF64B5F6)),
                    Triple("Netral (Lempeng)", countNetral / safeTotal, Color(0xFFFFD54F)),
                    Triple("Anxious (Cemas)", countCemas / safeTotal, Color(0xFFFFB74D)),
                    Triple("Sedih (Murung)", countSedih / safeTotal, Color(0xFFE57373))
                ).sortedByDescending { it.second }

                for ((label, fraction, color) in moods) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(modifier = Modifier.size(10.dp).clip(CircleShape).background(color))
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(text = label, style = MaterialTheme.typography.bodyMedium)
                            }
                            Text(text = "${(fraction * 100).toInt()}%", style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold))
                        }
                        
                        // Linear gauge
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(8.dp)
                                .clip(RoundedCornerShape(4.dp))
                                .background(MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth(fraction)
                                    .fillMaxHeight()
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(color)
                            )
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(48.dp))
    }
}
