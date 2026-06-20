import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../journal/data/models/journal_model.dart';
import '../../../journal/data/services/journal_firestore_service.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import 'daily_journal_list_screen.dart';

class FullCalendarScreen extends StatefulWidget {
  const FullCalendarScreen({super.key});

  @override
  State<FullCalendarScreen> createState() => _FullCalendarScreenState();
}

class _FullCalendarScreenState extends State<FullCalendarScreen> {
  final JournalFirestoreService _journalService = JournalFirestoreService();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Color _getMoodColor(List<JournalModel> journalsOnDate) {
    if (journalsOnDate.isEmpty) return Colors.transparent;
    
    // Rata-rata happiness level jika lebih dari 1 jurnal
    int totalHappiness = 0;
    for (var j in journalsOnDate) {
      totalHappiness += (j.happinessLevel ?? 50);
    }
    int avgHappiness = totalHappiness ~/ journalsOnDate.length;

    if (avgHappiness >= 75) return Colors.greenAccent;
    if (avgHappiness >= 50) return Colors.blueAccent;
    if (avgHappiness >= 25) return Colors.amberAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Kalender Mood',
          style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: themeProvider.primaryTextColor),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeProvider.backgroundGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: StreamBuilder<List<JournalModel>>(
              stream: _journalService.getJournalsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

          final allJournals = snapshot.data ?? [];

          // Kelompokkan jurnal berdasarkan tanggal untuk memudahkan pencarian
          Map<DateTime, List<JournalModel>> journalsMap = {};
          for (var j in allJournals) {
            final dateKey = DateTime(j.createdAt.year, j.createdAt.month, j.createdAt.day);
            if (journalsMap[dateKey] == null) {
              journalsMap[dateKey] = [];
            }
            journalsMap[dateKey]!.add(j);
          }

          // Hitung warna untuk setiap mood yang ada
          Map<String, List<int>> moodHappinessLevels = {};
          for (var j in allJournals) {
            if (j.mood.isNotEmpty) {
              final mood = j.mood.trim();
              if (!moodHappinessLevels.containsKey(mood)) {
                moodHappinessLevels[mood] = [];
              }
              moodHappinessLevels[mood]!.add(j.happinessLevel ?? 50);
            }
          }

          List<Widget> legendItems = [];
          moodHappinessLevels.forEach((mood, levels) {
            int avgHappiness = levels.reduce((a, b) => a + b) ~/ levels.length;
            Color color;
            if (avgHappiness >= 75) {
              color = Colors.greenAccent;
            } else if (avgHappiness >= 50) {
              color = Colors.blueAccent;
            } else if (avgHappiness >= 25) {
              color = Colors.amberAccent;
            } else {
              color = Colors.redAccent;
            }
            legendItems.add(_buildLegendItem(color, mood, context));
          });

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: themeProvider.glassBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: themeProvider.glassBorderColor),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    headerStyle: HeaderStyle(
                      titleTextStyle: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
                      formatButtonVisible: false,
                      leftChevronIcon: Icon(Icons.chevron_left, color: themeProvider.primaryTextColor),
                      rightChevronIcon: Icon(Icons.chevron_right, color: themeProvider.primaryTextColor),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: GoogleFonts.inter(color: themeProvider.secondaryTextColor),
                      weekendStyle: GoogleFonts.inter(color: Colors.redAccent),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: GoogleFonts.inter(color: themeProvider.primaryTextColor),
                      weekendTextStyle: GoogleFonts.inter(color: Colors.redAccent),
                      outsideTextStyle: GoogleFonts.inter(color: themeProvider.secondaryTextColor.withOpacity(0.5)),
                      todayDecoration: BoxDecoration(
                        color: themeProvider.glassBorderColor,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontWeight: FontWeight.bold),
                    ),
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyJournalListScreen(date: selectedDay),
                        ),
                      );
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarBuilders: CalendarBuilders(
                      prioritizedBuilder: (context, day, focusedDay) {
                        final dateKey = DateTime(day.year, day.month, day.day);
                        final journalsOnDate = journalsMap[dateKey] ?? [];
                        final moodColor = _getMoodColor(journalsOnDate);

                        bool isToday = isSameDay(day, DateTime.now());
                        bool isSelected = isSameDay(day, _selectedDay);
                        bool isOutside = day.month != _focusedDay.month;
                        Color textColor = themeProvider.primaryTextColor;
                        if (day.weekday == DateTime.sunday || day.weekday == DateTime.saturday) {
                          textColor = Colors.redAccent;
                        }
                        if (isOutside) {
                          textColor = themeProvider.secondaryTextColor.withOpacity(0.5);
                        }
                        
                        if (isToday || isSelected) textColor = themeProvider.primaryTextColor;

                        return Container(
                          margin: const EdgeInsets.all(4.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? themeProvider.glassBorderColor.withOpacity(0.5) : (isToday ? themeProvider.glassBorderColor : Colors.transparent),
                            border: Border.all(
                              color: journalsOnDate.isNotEmpty ? moodColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            day.day.toString(),
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Legenda
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeProvider.glassBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: themeProvider.glassBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Legenda Mood', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      if (legendItems.isEmpty)
                        Text('Belum ada data mood', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 14))
                      else
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: legendItems,
                        ),
                    ],
                  ),
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

  Widget _buildLegendItem(Color color, String label, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Provider.of<ThemeProvider>(context).glassBorderColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: Provider.of<ThemeProvider>(context).secondaryTextColor, fontSize: 12)),
      ],
    );
  }
}
