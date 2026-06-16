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
fun AiRecommendationScreen(
    viewModel: JournalViewModel,
    modifier: Modifier = Modifier
) {
    val recommendations = listOf(
        Triple("Napas Kotak (Box Breathing)", "Menyeimbangkan saraf vagus dan mengurangi kecemasan instan dalam 2 menit.", Icons.Default.Spa),
        Triple("Digital Detox 30 Menit", "Matikan seluruh layar gawai untuk membiarkan reseptor dopamin otak Anda beristirahat sejenak.", Icons.Default.PhonelinkOff),
        Triple("Sedotan Teh Chamomile", "Minum secangkir teh hangat beraroma chamomile floral sebagai pelepas penat otot tubuh.", Icons.Default.LocalCafe),
        Triple("Jalan Kaki Lambat", "Berjalan di sekitar taman perumahan tanpa musik untuk menyelaraskan diri kembali dengan semesta.", Icons.Default.DirectionsWalk)
    )

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Column {
            Text(
                text = "Rekomendasi Aktivitas AI",
                style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.ExtraBold),
                color = MaterialTheme.colorScheme.primary
            )
            Text(
                text = "Latihan kustom penyeimbang kondisi emosi Anda hari ini.",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.Gray
            )
        }

        // Motivational Quote Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f))
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(imageVector = Icons.Default.AutoAwesome, contentDescription = "AI", tint = MaterialTheme.colorScheme.primary)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(text = "Motivasi Hari Ini", fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                }
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "\"Tidak apa-apa berjalan lambat, asalkan Anda tidak berhenti menghargai proses tumbuh kembang diri sendiri.\"",
                    fontSize = 16.sp,
                    fontStyle = androidx.compose.ui.text.font.FontStyle.Italic,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }

        // Action Recommendation Cards list
        Text(text = "Direkomendasikan Untuk Anda", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)

        for ((title, desc, icon) in recommendations) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                shape = RoundedCornerShape(20.dp)
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(imageVector = icon, contentDescription = title, tint = MaterialTheme.colorScheme.primary)
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = title, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                        Text(text = desc, style = MaterialTheme.typography.bodyMedium, color = Color.Gray)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(32.dp))
    }
}
