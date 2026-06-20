import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../journal/data/models/journal_model.dart';
import '../../../journal/data/services/journal_firestore_service.dart';
import '../../../journal/presentation/widgets/journal_card.dart';
import '../../../../shared/widgets/glassmorphism_container.dart';
import '../../../../shared/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/push_notification_service.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final JournalFirestoreService _journalService = JournalFirestoreService();
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _selectedMood = 'Semua'; // 'Semua', 'Bahagia', 'Tenang', 'Netral'

  @override
  void initState() {
    super.initState();
    PushNotificationService().init();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Jurnal Saya',
          style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.primaryTextColor),
      ),
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
            bottom: false, // Konten mengalir sampai ke dasar layar
            child: StreamBuilder<List<JournalModel>>(
              stream: _journalService.getJournalsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: themeProvider.primaryTextColor));
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}', style: TextStyle(color: themeProvider.primaryTextColor)));
                }
                
                final allJournals = snapshot.data ?? [];
                
                // Get unique moods dynamically from journals
                Set<String> uniqueMoods = {};
                for(var j in allJournals) {
                   if (j.mood.isNotEmpty) {
                      uniqueMoods.add(j.mood.trim());
                   }
                }
                List<String> moodList = ['Semua', ...uniqueMoods.toList()..sort()];

                final journals = allJournals.where((journal) {
                  // 1. Filter Tanggal
                  if (_selectedDate != null) {
                    if (journal.createdAt.year != _selectedDate!.year ||
                        journal.createdAt.month != _selectedDate!.month ||
                        journal.createdAt.day != _selectedDate!.day) {
                      return false;
                    }
                  }
                  
                  // 2. Filter Teks Pencarian
                  if (_searchQuery.isNotEmpty) {
                    final titleMatch = journal.title.toLowerCase().contains(_searchQuery);
                    final contentMatch = journal.content.toLowerCase().contains(_searchQuery);
                    if (!titleMatch && !contentMatch) {
                      return false;
                    }
                  }
                  // 3. Filter Mood
                  if (_selectedMood != 'Semua') {
                    if (!journal.mood.contains(_selectedMood)) return false;
                  }
                  
                  return true;
                }).toList();

                return Column(
                  children: [
                    // Top Area: Search & Filter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1)),
                                  ),
                                  child: TextField(
                                    style: TextStyle(color: themeProvider.primaryTextColor),
                                    onChanged: (value) => setState(() => _searchQuery = value),
                                    decoration: InputDecoration(
                                      hintText: 'Cari judul atau isi jurnal...',
                                      hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
                                      prefixIcon: Icon(Icons.search, color: themeProvider.secondaryTextColor),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GlassmorphismContainer(
                                borderRadius: 20,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _selectedDate != null ? Icons.filter_alt : Icons.filter_list,
                                        color: _selectedDate != null ? Colors.greenAccent : themeProvider.primaryTextColor,
                                      ),
                                      onPressed: () async {
                                        final DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDate ?? DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now(),
                                          builder: (context, child) {
                                            return BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                              child: Theme(
                                                data: themeProvider.isDarkMode ? ThemeData.dark().copyWith(
                                                  colorScheme: const ColorScheme.dark(
                                                    primary: Colors.greenAccent,
                                                  ),
                                                ) : ThemeData.light().copyWith(
                                                  colorScheme: const ColorScheme.light(
                                                    primary: Colors.blueAccent,
                                                  ),
                                                ),
                                                child: child!,
                                              ),
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            _selectedDate = picked;
                                          });
                                        }
                                      },
                                    ),
                                    if (_selectedDate != null)
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.only(right: 8),
                                        onPressed: () {
                                          setState(() {
                                            _selectedDate = null;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Mood Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Row(
                        children: moodList.map((mood) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildMoodChip(mood),
                        )).toList(),
                      ),
                    ),
                    
                    // Main Body: List of Journals
                    Expanded(
                      child: journals.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isNotEmpty || _selectedDate != null || _selectedMood != 'Semua'
                                  ? 'Tidak ada jurnal yang cocok dengan filter.'
                                  : 'Belum ada jurnal.',
                                style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 180.0), // Padding ekstra untuk navbar
                              itemCount: journals.length,
                              itemBuilder: (context, index) {
                                return JournalCard(journal: journals[index]);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(String fullMood) {
    final isSelected = _selectedMood == fullMood;
    
    String displayText = fullMood;
    if (fullMood != 'Semua') {
      final parts = fullMood.trim().split(' ');
      if (parts.isNotEmpty) displayText = parts.first;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = fullMood;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : (Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white24 : Colors.black12),
          ),
        ),
        child: Text(
          displayText,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Provider.of<ThemeProvider>(context).secondaryTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
