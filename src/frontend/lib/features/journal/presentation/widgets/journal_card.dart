import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../data/models/journal_model.dart';
import '../screens/journal_viewer_screen.dart';

class JournalCard extends StatelessWidget {
  final JournalModel journal;

  const JournalCard({super.key, required this.journal});

  String _getPreviewText() {
    try {
      final List<dynamic> ops = jsonDecode(journal.content);
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }
      final text = buffer.toString().trim();
      return text.isNotEmpty ? text : 'Teks kosong...';
    } catch (e) {
      // Fallback untuk data lama
      return journal.content;
    }
  }

  // Dihapus: String? _getThumbnailUrl() karena sekarang menggunakan field `imageUrl` langsung

  String _getMoodEmoji(String mood) {
    if (mood.isEmpty) return '📝';
    final parts = mood.trim().split(' ');
    if (parts.isEmpty) return '📝';
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final String formattedDate = DateFormat('dd MMM yyyy').format(journal.createdAt);
    final String snippet = _getPreviewText();
    final String? thumbnailUrl = journal.imageUrl;
    
    // Fallback ke data default jika string kosong.
    final String location = journal.location.isNotEmpty ? journal.location : 'Belum ada lokasi';
    
    // Ambil emoji dan teks mood
    final moodEmoji = _getMoodEmoji(journal.mood);
    final moodText = journal.mood.replaceAll(moodEmoji, '').trim();
    final displayMoodText = moodText.isNotEmpty ? moodText : 'Netral';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JournalViewerScreen(journal: journal),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.lightBlueAccent.withValues(alpha: 0.1) : Colors.lightBlue.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: themeProvider.isDarkMode ? Colors.lightBlueAccent.withValues(alpha: 0.2) : Colors.lightBlue.shade200),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Date & Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedDate, style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.location_on, color: themeProvider.isDarkMode ? Colors.blueAccent : Colors.blue.shade700, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          location,
                          style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              journal.title,
              style: GoogleFonts.inter(
                color: themeProvider.primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Snippet
            Text(
              snippet,
              style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 14, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Image Thumbnail (If any)
            if (thumbnailUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  thumbnailUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Footer: Mood Badge
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? Colors.purpleAccent.withValues(alpha: 0.15) : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeProvider.isDarkMode ? Colors.transparent : Colors.purple.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(moodEmoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      displayMoodText,
                      style: GoogleFonts.inter(color: themeProvider.isDarkMode ? Colors.purpleAccent.shade100 : Colors.purple.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
