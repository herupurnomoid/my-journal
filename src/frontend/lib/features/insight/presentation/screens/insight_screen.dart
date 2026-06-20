import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../journal/data/models/journal_model.dart';
import '../../../journal/data/services/journal_firestore_service.dart';
import '../../../journal/data/services/ai_api_service.dart';
import '../../../../shared/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  final JournalFirestoreService _journalService = JournalFirestoreService();
  final AIApiService _aiApiService = AIApiService();

  static String? _cachedAiInsightText;
  static DateTime _cachedLastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);

  String? _aiInsightText;
  bool _isLoadingAi = false;

  @override
  void initState() {
    super.initState();
    _aiInsightText = _cachedAiInsightText;
  }

  // Map untuk menentukan warna mood
  Color _getMoodColor(String mood) {
    final m = mood.toLowerCase();
    if (m.contains('bahagia') || m.contains('senang') || m.contains('gembira'))
      return Colors.greenAccent;
    if (m.contains('tenang') || m.contains('damai') || m.contains('netral'))
      return Colors.blueAccent;
    if (m.contains('cemas') || m.contains('gugup')) return Colors.orangeAccent;
    if (m.contains('sedih') ||
        m.contains('kecewa') ||
        m.contains('marah') ||
        m.contains('stres'))
      return Colors.redAccent;
    return Colors.amberAccent; // Default fallback
  }

  String _extractText(String content) {
    try {
      final ops = jsonDecode(content) as List;
      return ops.map((op) => op['insert']?.toString() ?? '').join('').trim();
    } catch (e) {
      return content.trim();
    }
  }

  void _fetchAiInsightIfNeeded(List<JournalModel> journals) async {
    if (journals.isEmpty) return;

    // Cegah spam API (hanya fetch jika sudah lebih dari 1 jam sejak fetch terakhir)
    if (DateTime.now().difference(_cachedLastFetchTime).inHours < 1 &&
        _cachedAiInsightText != null) {
      if (mounted) {
        setState(() {
          _aiInsightText = _cachedAiInsightText;
        });
      }
      return;
    }

    // Cegah spam berulang jika gagal beruntun
    if (DateTime.now().difference(_cachedLastFetchTime).inSeconds < 10) return;

    setState(() {
      _isLoadingAi = true;
      _cachedLastFetchTime = DateTime.now();
    });

    try {
      final recentJournals = journals
          .take(7)
          .map((j) => {'title': j.title, 'content': _extractText(j.content)})
          .toList();

      final insight = await _aiApiService.getWeeklyInsights(recentJournals);
      _cachedAiInsightText = insight;

      if (mounted) {
        setState(() {
          _aiInsightText = insight;
          _isLoadingAi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiInsightText = 'Gagal memuat insight AI mingguan. Coba lagi nanti.';
          _isLoadingAi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Insight & Analitik',
          style: GoogleFonts.inter(
            color: themeProvider.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.primaryTextColor),
      ),
      body: Stack(
        children: [
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
            child: StreamBuilder<List<JournalModel>>(
              stream: _journalService.getJournalsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: themeProvider.primaryTextColor,
                    ),
                  );
                }

                final allJournals = snapshot.data ?? [];
                final now = DateTime.now();

                // Data untuk kalender
                Map<DateTime, List<JournalModel>> events = {};
                for (var j in allJournals) {
                  final date = DateTime(
                    j.createdAt.year,
                    j.createdAt.month,
                    j.createdAt.day,
                  );
                  if (events[date] == null) events[date] = [];
                  events[date]!.add(j);
                }

                // Data untuk Insight 7 hari terakhir
                final weeklyJournals = allJournals
                    .where(
                      (j) => j.createdAt.isAfter(
                        now.subtract(const Duration(days: 7)),
                      ),
                    )
                    .toList();
                if (_aiInsightText == null &&
                    !_isLoadingAi &&
                    weeklyJournals.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _fetchAiInsightIfNeeded(weeklyJournals);
                  });
                }

                // Data untuk Daftar Persentase
                Map<String, int> moodCounts = {};
                int totalMoods = 0;
                for (var j in allJournals) {
                  if (j.mood.isNotEmpty) {
                    final moodName = j.mood.trim();
                    moodCounts[moodName] = (moodCounts[moodName] ?? 0) + 1;
                    totalMoods++;
                  }
                }
                final sortedMoods = moodCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                // Data untuk grafik garis (Minggu ini: Minggu - Sabtu)
                final currentWeekday = now.weekday; // 1 = Sen, 7 = Min
                final lastSunday = currentWeekday == 7
                    ? now
                    : now.subtract(Duration(days: currentWeekday));

                List<FlSpot> happinessSpots = [];
                List<FlSpot> stressSpots = [];
                for (int i = 0; i <= 6; i++) {
                  final date = lastSunday.add(Duration(days: i));
                  final dailyJournals = allJournals
                      .where(
                        (j) =>
                            j.createdAt.day == date.day &&
                            j.createdAt.month == date.month &&
                            j.createdAt.year == date.year,
                      )
                      .toList();

                  double hap = 5.0; // default middle
                  double str = 5.0;
                  if (dailyJournals.isNotEmpty) {
                    hap =
                        dailyJournals
                            .map((j) => (j.happinessLevel ?? 5.0))
                            .reduce((a, b) => a + b) /
                        dailyJournals.length;
                    str =
                        dailyJournals
                            .map((j) => (j.stressLevel ?? 5.0))
                            .reduce((a, b) => a + b) /
                        dailyJournals.length;
                    happinessSpots.add(FlSpot(i.toDouble(), hap));
                    stressSpots.add(FlSpot(i.toDouble(), str));
                  } else {
                    // Interpolation for empty days
                    if (happinessSpots.isNotEmpty) {
                      hap = happinessSpots.last.y;
                      str = stressSpots.last.y;
                    }
                    // Add only if the day is not in the future
                    if (date.isBefore(now) ||
                        (date.day == now.day && date.month == now.month)) {
                      happinessSpots.add(FlSpot(i.toDouble(), hap));
                      stressSpots.add(FlSpot(i.toDouble(), str));
                    }
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Kalender Mood Cincin
                      _buildCalendarCard(events, sortedMoods, themeProvider),
                      const SizedBox(height: 24),

                      // 2. Analisis Keseimbangan Emosional
                      _buildAIInsightCard(themeProvider),
                      const SizedBox(height: 24),

                      // 3. Grafik Garis Kestabilan
                      _buildTrendChartCard(
                        happinessSpots,
                        stressSpots,
                        now,
                        themeProvider,
                      ),
                      const SizedBox(height: 24),

                      // 4. Daftar Persentase Emosi
                      _buildEmotionPercentagesCard(
                        sortedMoods,
                        totalMoods,
                        themeProvider,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(
    Map<DateTime, List<JournalModel>> events,
    List<MapEntry<String, int>> sortedMoods,
    ThemeProvider themeProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.glassBackgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.now(),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: themeProvider.primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: themeProvider.primaryTextColor,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: themeProvider.primaryTextColor,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: themeProvider.secondaryTextColor),
              weekendStyle: TextStyle(color: themeProvider.secondaryTextColor),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(
                color: themeProvider.primaryTextColor,
              ),
              weekendTextStyle: TextStyle(
                color: themeProvider.primaryTextColor,
              ),
              outsideTextStyle: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.white30
                    : Colors.black38,
              ),
              todayDecoration: const BoxDecoration(color: Colors.transparent),
              todayTextStyle: TextStyle(
                color: themeProvider.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            eventLoader: (day) {
              final date = DateTime(day.year, day.month, day.day);
              return events[date] ?? [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, eventsList) {
                if (eventsList.isEmpty) return const SizedBox();
                final j =
                    eventsList.last
                        as JournalModel; // Get the latest mood of the day
                return Positioned(
                  top: 4,
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getMoodColor(j.mood),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: sortedMoods.take(5).map((entry) {
              return _buildLegendItem(
                _getMoodColor(entry.key),
                entry.key,
                themeProvider,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label,
    ThemeProvider themeProvider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: themeProvider.secondaryTextColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsightCard(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
            : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? const Color(0xFF1E3A8A).withValues(alpha: 0.8)
              : Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Analisis Keseimbangan Emosional',
                style: GoogleFonts.inter(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingAi)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            )
          else if (_aiInsightText != null)
            Text(
              _aiInsightText!,
              style: GoogleFonts.inter(
                color: themeProvider.primaryTextColor,
                fontSize: 14,
                height: 1.5,
              ),
            )
          else
            Text(
              'Belum ada data jurnal minggu ini untuk dianalisis.',
              style: GoogleFonts.inter(
                color: themeProvider.secondaryTextColor,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendChartCard(
    List<FlSpot> happinessSpots,
    List<FlSpot> stressSpots,
    DateTime now,
    ThemeProvider themeProvider,
  ) {
    final xLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.glassBackgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren Kestabilan Suasana Hati (Mingguan)',
            style: GoogleFonts.inter(
              color: themeProvider.primaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grafik korelasi kebahagiaan (garis biru) vs stres (garis merah)',
            style: GoogleFonts.inter(
              color: themeProvider.secondaryTextColor,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                minX: 0,
                maxX: 6,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: themeProvider.isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black12,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1, // Fixed to prevent repeated titles
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < 7) {
                          return Text(
                            xLabels[idx],
                            style: GoogleFonts.inter(
                              color: themeProvider.secondaryTextColor,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: happinessSpots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: stressSpots,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionPercentagesCard(
    List<MapEntry<String, int>> sortedMoods,
    int totalMoods,
    ThemeProvider themeProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.glassBackgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar Persentase Emosi',
            style: GoogleFonts.inter(
              color: themeProvider.primaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (totalMoods == 0)
            Text(
              'Belum ada data emosi.',
              style: GoogleFonts.inter(
                color: themeProvider.secondaryTextColor,
                fontSize: 12,
              ),
            )
          else
            ...sortedMoods.take(5).map((entry) {
              final percentage = (entry.value / totalMoods) * 100;
              final color = _getMoodColor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key,
                              style: GoogleFonts.inter(
                                color: themeProvider.primaryTextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${percentage.toInt()}%',
                          style: GoogleFonts.inter(
                            color: themeProvider.primaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: themeProvider.isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
