import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/mood_analysis_model.dart';
import '../../../../shared/widgets/glassmorphism_container.dart';
import '../../../../shared/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class MoodAnalysisBottomSheet extends StatelessWidget {
  final MoodAnalysisModel analysis;

  const MoodAnalysisBottomSheet({super.key, required this.analysis});

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'angry': return '😠';
      case 'anxious': return '😰';
      case 'neutral': return '😐';
      case 'excited': return '🤩';
      case 'tired': return '😴';
      default: return '😎';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: GlassmorphismContainer(
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kartu Hasil Analisis AI',
                      style: GoogleFonts.inter(
                        color: themeProvider.primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.auto_awesome, color: themeProvider.isDarkMode ? Colors.purpleAccent.shade100 : Colors.purpleAccent),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Primary Mood
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getMoodEmoji(analysis.primaryMood),
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Primary Mood', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
                        Text(
                          analysis.primaryMood,
                          style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sentiment Scores
                _buildScoreMeter('Happiness Level', analysis.happinessLevel, Colors.greenAccent, themeProvider),
                const SizedBox(height: 12),
                _buildScoreMeter('Stress Level', analysis.stressLevel, Colors.redAccent, themeProvider),
                const SizedBox(height: 24),

                // Emotion Summary
                Text('Emotion Summary', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeProvider.glassBorderColor),
                  ),
                  child: Text(
                    '"${analysis.emotionSummary}"',
                    style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 24),

                // Recommendations
                Text('Rekomendasi Aktivitas', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
                const SizedBox(height: 8),
                ...analysis.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, color: themeProvider.isDarkMode ? Colors.white54 : Colors.black54, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                      foregroundColor: themeProvider.primaryTextColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreMeter(String label, int score, Color color, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 14)),
            Text('$score%', style: GoogleFonts.inter(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
