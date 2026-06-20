import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../../shared/widgets/glassmorphism_container.dart';
import '../../../journal/data/models/journal_model.dart';
import '../../../journal/data/services/journal_firestore_service.dart';
import '../../../journal/presentation/screens/journal_viewer_screen.dart';
import '../../../journal/presentation/screens/journal_editor_screen.dart';
import '../../../journal/presentation/screens/ai_analysis_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import 'daily_journal_list_screen.dart';
import 'full_calendar_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final JournalFirestoreService _journalService = JournalFirestoreService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.split(' ').first ?? 'Reflektor';

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.backgroundGradient,
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: StreamBuilder<List<JournalModel>>(
              stream: _journalService.getJournalsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allJournals = snapshot.data ?? [];
                
                final now = DateTime.now();
                final todayStr = DateFormat('yyyy-MM-dd').format(now);
                final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
                
                final journalDates = allJournals.map((j) => DateFormat('yyyy-MM-dd').format(j.createdAt)).toSet();
                
                int streak = 0;
                DateTime checkDate = now;
                if (!journalDates.contains(todayStr)) {
                  if (journalDates.contains(yesterdayStr)) {
                    checkDate = now.subtract(const Duration(days: 1));
                  } else {
                    // Start checking backwards if we want, but basically streak is 0
                  }
                }
                
                while (journalDates.contains(DateFormat('yyyy-MM-dd').format(checkDate))) {
                  streak++;
                  checkDate = checkDate.subtract(const Duration(days: 1));
                }

                final todayJournals = allJournals.where((j) => DateFormat('yyyy-MM-dd').format(j.createdAt) == todayStr).toList();
                final todayJournal = todayJournals.isNotEmpty ? todayJournals.first : null;

                final yesterdayJournals = allJournals.where((j) => DateFormat('yyyy-MM-dd').format(j.createdAt) == yesterdayStr).toList();
                final yesterdayJournal = yesterdayJournals.isNotEmpty ? yesterdayJournals.first : null;
                final latestJournal = allJournals.isNotEmpty ? allJournals.first : null;
                
                final journalsThisMonth = allJournals.where((j) => j.createdAt.year == now.year && j.createdAt.month == now.month).length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 120.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, $userName',
                                  style: GoogleFonts.inter(
                                    color: themeProvider.isDarkMode ? Colors.blueAccent.shade100 : Colors.blue.shade800,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Semoga jiwa Anda tenteram hari ini.',
                                  style: GoogleFonts.inter(
                                    color: themeProvider.secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GlassmorphismContainer(
                            borderRadius: 20,
                            child: InkWell(
                              onTap: () {
                                // TODO: Navigate to profile/settings
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                  child: user?.photoURL != null
                                      ? CircleAvatar(
                                          radius: 16,
                                          backgroundImage: NetworkImage(user!.photoURL!),
                                        )
                                      : Icon(Icons.person_rounded, color: themeProvider.isDarkMode ? Colors.blueAccent : Colors.blue.shade700, size: 28),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildMoodCard(todayJournal, yesterdayJournal, themeProvider),
                      const SizedBox(height: 16),

                      _buildAIBanner(context, todayJournal, themeProvider),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(child: _buildStatCard('JURNAL', '${allJournals.length}', '+$journalsThisMonth Bulan Ini', themeProvider.isDarkMode ? Colors.greenAccent : Colors.green.shade700, themeProvider)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard(
                            'STREAK', 
                            streak > 0 ? '$streak 🔥' : '0 ❄️', 
                            streak > 0 ? 'Hari berturut-turut' : 'Yuk mulai lagi!', 
                            themeProvider.secondaryTextColor,
                            themeProvider
                          )),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FullCalendarScreen()),
                            );
                          },
                          child: Text('Lihat Semua', style: GoogleFonts.inter(color: themeProvider.isDarkMode ? Colors.blueAccent : Colors.blue.shade700)),
                        ),
                      ),
                      
                      _buildWeeklyCalendar(context, journalDates, themeProvider),
                      const SizedBox(height: 24),

                      Text('Catatan Jurnal Terbaru', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildRecentJournals(allJournals, context, themeProvider),
                    ],
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard(JournalModel? todayJournal, JournalModel? yesterdayJournal, ThemeProvider themeProvider) {
    String mood = todayJournal?.moodEmoji ?? '❓';
    String message = todayJournal != null ? 'Anda sudah menulis jurnal hari ini!' : 'Bagaimana perasaan Anda hari ini?';
    String subtitle = 'Yuk catat momen berharga Anda.';
    
    if (todayJournal != null && yesterdayJournal != null && todayJournal.mood == yesterdayJournal.mood) {
      subtitle = 'Wah, mood Anda konsisten dari kemarin!';
    } else if (todayJournal == null) {
      subtitle = 'Jangan lewatkan hari ini tanpa cerita.';
    }

    return GlassmorphismContainer(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: themeProvider.glassBorderColor),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.glassBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Text(mood, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MOOD HARI INI', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(message, style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBanner(BuildContext context, JournalModel? todayJournal, ThemeProvider themeProvider) {
    if (todayJournal != null) {
      String recommendation = todayJournal.recommendations?.first ?? 'Lihat analisis AI untuk hari ini.';
      return GlassmorphismContainer(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIAnalysisDetailScreen(journal: todayJournal),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: themeProvider.glassBorderColor),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeProvider.glassBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: themeProvider.isDarkMode ? Colors.blueAccent : Colors.blue.shade700, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('REKOMENDASI GEMINI AI', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          Icon(Icons.arrow_outward_rounded, color: themeProvider.secondaryTextColor, size: 18),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(recommendation, style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 14, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, ThemeProvider themeProvider) {
    return GlassmorphismContainer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: themeProvider.glassBorderColor),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCalendar(BuildContext context, Set<String> journalDates, ThemeProvider themeProvider) {
    final now = DateTime.now();
    final sundayDate = now.subtract(Duration(days: now.weekday % 7));
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = sundayDate.add(Duration(days: index));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        bool isToday = DateFormat('yyyy-MM-dd').format(now) == dateStr;
        bool hasJournal = journalDates.contains(dateStr);
        
        Color ringColor = themeProvider.glassBorderColor;
        if (hasJournal) {
          ringColor = themeProvider.isDarkMode ? Colors.greenAccent : Colors.green.shade600;
        } else if (isToday) {
          ringColor = themeProvider.isDarkMode ? Colors.blueAccent : Colors.blue.shade600;
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DailyJournalListScreen(date: date),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2),
                    color: hasJournal 
                        ? (themeProvider.isDarkMode ? Colors.greenAccent.withOpacity(0.2) : Colors.green.shade100) 
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(date.day.toString(), style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(days[index], style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRecentJournals(List<JournalModel> journals, BuildContext context, ThemeProvider themeProvider) {
    if (journals.isEmpty) {
      return GlassmorphismContainer(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(child: Text('Belum ada jurnal.', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor))),
        ),
      );
    }

    final latestJournal = journals.first;
    final date = DateFormat('dd MMM yyyy').format(latestJournal.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassmorphismContainer(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JournalViewerScreen(journal: latestJournal),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: themeProvider.glassBorderColor),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Text(latestJournal.moodEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date, style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(latestJournal.title, style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (latestJournal.emotionSummary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          latestJournal.emotionSummary!,
                          style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (latestJournal.imageUrl != null) ...[
                  const SizedBox(width: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      latestJournal.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
