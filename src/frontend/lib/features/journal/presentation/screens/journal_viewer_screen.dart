import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import '../../data/models/journal_model.dart';
import '../../data/services/ai_api_service.dart';
import '../../data/services/journal_firestore_service.dart';
import 'journal_editor_screen.dart';
import '../../../../shared/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class JournalViewerScreen extends StatefulWidget {
  final JournalModel journal;

  const JournalViewerScreen({super.key, required this.journal});

  @override
  State<JournalViewerScreen> createState() => _JournalViewerScreenState();
}

class _JournalViewerScreenState extends State<JournalViewerScreen> {
  late QuillController _quillController;
  late JournalModel _currentJournal;
  final AIApiService _aiApiService = AIApiService();
  final JournalFirestoreService _journalService = JournalFirestoreService();
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _currentJournal = widget.journal;
    try {
      final jsonDelta = jsonDecode(widget.journal.content);
      _quillController = QuillController(
        document: Document.fromJson(jsonDelta),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (e) {
      _quillController = QuillController.basic();
    }
  }

  Future<void> _runAnalysisInViewer() async {
    setState(() { _isAnalyzing = true; });
    try {
      final plainContent = _quillController.document.toPlainText().trim();
      if (plainContent.isEmpty || plainContent == '\n') {
        throw Exception('Konten jurnal kosong.');
      }
      
      final result = await _aiApiService.analyzeMood(_currentJournal.title, plainContent);
      
      // Update local state
      setState(() {
        _currentJournal = JournalModel(
          id: _currentJournal.id,
          title: _currentJournal.title,
          content: _currentJournal.content,
          location: _currentJournal.location,
          status: _currentJournal.status,
          mood: result.primaryMood,
          imageUrl: _currentJournal.imageUrl,
          createdAt: _currentJournal.createdAt,
          stressLevel: result.stressLevel,
          happinessLevel: result.happinessLevel,
          emotionSummary: result.emotionSummary,
          recommendations: result.recommendations,
        );
      });

      // Update Firestore
      await _journalService.updateJournal(_currentJournal.id, {
        'mood': result.primaryMood,
        'stressLevel': result.stressLevel,
        'happinessLevel': result.happinessLevel,
        'emotionSummary': result.emotionSummary,
        'recommendations': result.recommendations,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analisis AI berhasil!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menganalisis AI: $e')),
      );
    } finally {
      if (mounted) setState(() { _isAnalyzing = false; });
    }
  }

  Future<void> _deleteJournal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        return AlertDialog(
          backgroundColor: themeProvider.glassBackgroundColor,
          title: Text('Hapus Jurnal', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
          content: Text('Apakah Anda yakin ingin menghapus jurnal ini secara permanen?', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text('Hapus', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _journalService.deleteJournal(_currentJournal.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jurnal berhasil dihapus')),
        );
        Navigator.pop(context); // Kembali ke Beranda
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus jurnal: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isAnalyzed = _currentJournal.emotionSummary != null;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text('Isi Jurnal', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.primaryTextColor),
        actions: [
          IconButton(
            onPressed: () async {
              final updatedJournal = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalEditorScreen(existingJournal: _currentJournal),
                ),
              );
              if (updatedJournal != null && updatedJournal is JournalModel) {
                setState(() {
                  _currentJournal = updatedJournal;
                  try {
                    final jsonDelta = jsonDecode(_currentJournal.content);
                    _quillController = QuillController(
                      document: Document.fromJson(jsonDelta),
                      selection: const TextSelection.collapsed(offset: 0),
                      readOnly: true,
                    );
                  } catch (e) {
                    _quillController = QuillController.basic();
                  }
                });
              }
            },
            icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
            tooltip: 'Ubah',
          ),
          IconButton(
            onPressed: _deleteJournal,
            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
            tooltip: 'Hapus',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Date & Location
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(_currentJournal.createdAt),
                    style: GoogleFonts.inter(color: Colors.lightBlueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.purpleAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(_currentJournal.location, style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Cover Image (Thumbnail)
              if (_currentJournal.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    _currentJournal.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. AI Mood Card (Only if analyzed)
              if (isAnalyzed) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? const Color(0xFF1E3A8A).withValues(alpha: 0.6) : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: themeProvider.isDarkMode ? Colors.lightBlueAccent : Colors.blueAccent, size: 14),
                          const SizedBox(width: 6),
                          Text('Analisis Gemini AI', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentJournal.moodEmoji,
                        style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 4. Title
              Text(
                _currentJournal.title,
                style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Divider(color: themeProvider.glassBorderColor, height: 1),
              const SizedBox(height: 16),

              // 5. Rich Text Content
              QuillEditor.basic(
                controller: _quillController,
                config: QuillEditorConfig(
                  customStyles: DefaultStyles(
                    paragraph: DefaultTextBlockStyle(
                      GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 16, height: 1.6),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 6. Bottom Action / Results
              if (!isAnalyzed)
                // Bottom Button if not analyzed
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _runAnalysisInViewer,
                    icon: _isAnalyzing 
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: themeProvider.backgroundColor, strokeWidth: 2))
                      : Icon(Icons.auto_awesome, color: themeProvider.backgroundColor, size: 18),
                    label: Text(_isAnalyzing ? 'Menganalisis...' : 'Tinjau Ruang Suasana Hati AI', style: GoogleFonts.inter(color: themeProvider.backgroundColor, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: themeProvider.backgroundColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                )
              else
                // Full AI Analysis Cards if already analyzed
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeProvider.glassBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: themeProvider.glassBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.purpleAccent.shade100, size: 20),
                          const SizedBox(width: 8),
                          Text('Hasil Tinjauan Suasana Hati AI', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Sentiment Scores
                      _buildScoreMeter('Happiness Level', _currentJournal.happinessLevel ?? 0, Colors.greenAccent, themeProvider),
                      const SizedBox(height: 12),
                      _buildScoreMeter('Stress Level', _currentJournal.stressLevel ?? 0, Colors.redAccent, themeProvider),
                      const SizedBox(height: 20),

                      // Emotion Summary
                      if (_currentJournal.emotionSummary != null && _currentJournal.emotionSummary!.isNotEmpty) ...[
                        Text('Emotion Summary', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: themeProvider.glassBorderColor),
                          ),
                          child: Text(
                            '"${_currentJournal.emotionSummary}"',
                            style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 14, fontStyle: FontStyle.italic),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Recommendations
                      if (_currentJournal.recommendations != null && _currentJournal.recommendations!.isNotEmpty) ...[
                        Text('Rekomendasi Aktivitas', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
                        const SizedBox(height: 8),
                        ..._currentJournal.recommendations!.map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
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
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
