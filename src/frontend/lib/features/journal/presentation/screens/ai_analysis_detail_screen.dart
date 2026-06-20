import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/journal_model.dart';
import '../../../../shared/providers/theme_provider.dart';

class AIAnalysisDetailScreen extends StatelessWidget {
  final JournalModel journal;

  const AIAnalysisDetailScreen({super.key, required this.journal});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text('Detail Analisis AI', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.primaryTextColor),
      ),
      body: Stack(
        children: [
          // Background accents (Circles for glassmorphism effect)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.2),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mood Section
                  _buildGlassCard(
                    themeProvider,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: themeProvider.isDarkMode ? Colors.lightBlueAccent : Colors.blue.shade700, size: 32),
                        const SizedBox(height: 12),
                        Text('Mood Terdeteksi', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          journal.mood.isNotEmpty ? journal.mood : 'Belum Dianalisis',
                          style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Levels Section
                  _buildGlassCard(
                    themeProvider,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMeter('Kebahagiaan', journal.happinessLevel ?? 50, themeProvider.isDarkMode ? Colors.blueAccent : Colors.blue.shade600, themeProvider),
                        const SizedBox(height: 16),
                        _buildMeter('Tingkat Stres', journal.stressLevel ?? 50, themeProvider.isDarkMode ? Colors.redAccent : Colors.red.shade600, themeProvider),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary Section
                  _buildGlassCard(
                    themeProvider,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology, color: themeProvider.isDarkMode ? Colors.purpleAccent : Colors.purple.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text('Analisis Emosional', style: GoogleFonts.inter(color: themeProvider.isDarkMode ? Colors.purpleAccent.shade100 : Colors.purple.shade800, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          journal.emotionSummary != null && journal.emotionSummary!.isNotEmpty 
                            ? journal.emotionSummary! 
                            : 'Tidak ada ringkasan emosional.',
                          style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 14, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recommendations Section
                  _buildGlassCard(
                    themeProvider,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: themeProvider.isDarkMode ? Colors.amberAccent : Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text('Rekomendasi Tindakan', style: GoogleFonts.inter(color: themeProvider.isDarkMode ? Colors.amberAccent.shade100 : Colors.orange.shade800, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (journal.recommendations != null && journal.recommendations!.isNotEmpty)
                          ...journal.recommendations!.map((rec) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('💡', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        rec,
                                        style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 14, height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                        else
                          Text('Belum ada rekomendasi.', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(ThemeProvider themeProvider, {required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: themeProvider.glassBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: themeProvider.glassBorderColor),
          ),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMeter(String label, int score, Color color, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 14)),
            Text('$score%', style: GoogleFonts.inter(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
