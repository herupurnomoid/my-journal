import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../journal/data/models/journal_model.dart';
import '../../../journal/data/services/journal_firestore_service.dart';
import '../../../journal/presentation/widgets/journal_card.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';

class DailyJournalListScreen extends StatelessWidget {
  final DateTime date;
  
  const DailyJournalListScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final journalService = JournalFirestoreService();
    final dateStr = DateFormat('dd MMM yyyy').format(date);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Jurnal: $dateStr',
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
        stream: journalService.getJournalsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allJournals = snapshot.data ?? [];
          final dailyJournals = allJournals.where((j) => 
            j.createdAt.year == date.year && 
            j.createdAt.month == date.month && 
            j.createdAt.day == date.day
          ).toList();

          if (dailyJournals.isEmpty) {
            return Center(
              child: Text(
                'Belum ada jurnal untuk tanggal ini.',
                style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: dailyJournals.length,
            itemBuilder: (context, index) {
              return JournalCard(journal: dailyJournals[index]);
            },
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}
