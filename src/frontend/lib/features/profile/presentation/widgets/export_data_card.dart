import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/glassmorphism_container.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../journal/data/services/journal_firestore_service.dart';

class ExportDataCard extends StatefulWidget {
  const ExportDataCard({super.key});

  @override
  State<ExportDataCard> createState() => _ExportDataCardState();
}

class _ExportDataCardState extends State<ExportDataCard> {
  final JournalFirestoreService _journalService = JournalFirestoreService();
  bool _isExporting = false;
  DateTimeRange? _exportDateRange;
  String _exportFormat = 'PDF';
  static const String _baseUrl = 'https://api-mxoqac2vyq-et.a.run.app/v1';

  @override
  void initState() {
    super.initState();
    _exportDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  Future<void> _pickDateRange() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _exportDateRange,
      builder: (context, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Theme(
            data: ThemeData(
              brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
              colorScheme: ColorScheme(
                brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
                primary: const Color(0xFF7C4DFF),
                onPrimary: Colors.white,
                secondary: const Color(0xFF448AFF),
                onSecondary: Colors.white,
                error: Colors.redAccent,
                onError: Colors.white,
                surface: themeProvider.glassBackgroundColor,
                onSurface: themeProvider.primaryTextColor,
              ),
              scaffoldBackgroundColor: Colors.transparent,
              dialogTheme: DialogThemeData(
                backgroundColor: themeProvider.glassBackgroundColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: themeProvider.glassBorderColor, width: 1.5),
                ),
              ),
              datePickerTheme: DatePickerThemeData(
                backgroundColor: themeProvider.glassBackgroundColor,
                headerBackgroundColor: Colors.transparent,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _exportDateRange = picked);
    }
  }

  String _extractPlainText(String content) {
    try {
      final ops = jsonDecode(content) as List;
      return ops.map((op) => op['insert']?.toString() ?? '').join('').trim();
    } catch (e) {
      return content.trim();
    }
  }

  Future<void> _exportData() async {
    if (_exportDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih rentang tanggal terlebih dahulu.', style: GoogleFonts.inter()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final allJournals = await _journalService.getJournalsStream().first;
      final filtered = allJournals.where((j) {
        return j.createdAt.isAfter(_exportDateRange!.start.subtract(const Duration(days: 1))) &&
            j.createdAt.isBefore(_exportDateRange!.end.add(const Duration(days: 1)));
      }).toList();

      if (filtered.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak ada jurnal dalam rentang tanggal ini.', style: GoogleFonts.inter()),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        setState(() => _isExporting = false);
        return;
      }

      final dateFormatter = DateFormat('dd MMMM yyyy');
      final journalEntries = filtered.map((j) => {
        'title': j.title,
        'content': _extractPlainText(j.content),
        'date': dateFormatter.format(j.createdAt),
        'userMood': j.mood,
      }).toList();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final idToken = await user.getIdToken();
      final url = Uri.parse('$_baseUrl/journals/export');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'journals': journalEntries}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'] ?? jsonResponse;
        final downloadUrl = data['downloadUrl'] as String;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ekspor disiapkan! Mengunduh file...', style: GoogleFonts.inter()),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }

        final fileName = 'MyJournal_Export_${DateTime.now().millisecondsSinceEpoch}.${_exportFormat.toLowerCase()}';

        FileDownloader.downloadFile(
          url: downloadUrl,
          name: fileName,
          onDownloadCompleted: (path) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Berhasil! File tersimpan di: $path', style: GoogleFonts.inter()),
                  backgroundColor: Colors.greenAccent.shade700,
                  duration: const Duration(seconds: 4),
                ),
              );
              setState(() => _isExporting = false);
            }
          },
          onDownloadError: (errorMessage) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal menyimpan file: $errorMessage', style: GoogleFonts.inter()),
                  backgroundColor: Colors.redAccent,
                ),
              );
              setState(() => _isExporting = false);
            }
          },
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dateFormatter = DateFormat('dd MMM yyyy');

    return GlassmorphismContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rentang Tanggal', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: themeProvider.glassBorderColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: themeProvider.glassBorderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: themeProvider.secondaryTextColor, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _exportDateRange != null
                            ? '${dateFormatter.format(_exportDateRange!.start)} — ${dateFormatter.format(_exportDateRange!.end)}'
                            : 'Pilih rentang tanggal...',
                        style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 14),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down_rounded, color: themeProvider.secondaryTextColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Format Ekspor', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: themeProvider.glassBorderColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: themeProvider.glassBorderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _exportFormat,
                  isExpanded: true,
                  dropdownColor: themeProvider.glassBackgroundColor,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: themeProvider.secondaryTextColor),
                  style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 14),
                  items: [
                    DropdownMenuItem(
                      value: 'PDF',
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 12),
                          Text('PDF', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Markdown',
                      child: Row(
                        children: [
                          const Icon(Icons.code_rounded, color: Colors.cyanAccent, size: 20),
                          const SizedBox(width: 12),
                          Text('Markdown', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _exportFormat = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _isExporting ? null : _exportData,
              child: GlassmorphismContainer(
                borderRadius: 14,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isExporting ? Colors.black.withOpacity(0.1) : Colors.transparent,
                  ),
                  child: _isExporting
                      ? Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: themeProvider.primaryTextColor, strokeWidth: 2.5)))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download_rounded, color: themeProvider.primaryTextColor, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Ekspor Data',
                              style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

