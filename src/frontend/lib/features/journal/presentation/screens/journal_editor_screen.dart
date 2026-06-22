import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/widgets/glassmorphism_container.dart';
import '../../data/models/journal_model.dart';
import '../../data/models/mood_analysis_model.dart';
import '../../data/services/journal_firestore_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/ai_api_service.dart';
import '../../../../shared/services/location_service.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';

class JournalEditorScreen extends StatefulWidget {
  final JournalModel? existingJournal;

  const JournalEditorScreen({super.key, this.existingJournal});

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> with WidgetsBindingObserver {
  final TextEditingController _titleController = TextEditingController();
  late QuillController _quillController;
  final JournalFirestoreService _journalService = JournalFirestoreService();
  final StorageService _storageService = StorageService();
  final AIApiService _aiApiService = AIApiService();
  
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isFetchingLocation = false;
  String _currentLocation = '';
  String? _currentDraftId;
  
  File? _coverImageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.existingJournal != null) {
      _titleController.text = widget.existingJournal!.title;
      _existingImageUrl = widget.existingJournal!.imageUrl;
      _currentLocation = widget.existingJournal!.location;
      try {
        final jsonDelta = jsonDecode(widget.existingJournal!.content);
        _quillController = QuillController(
          document: Document.fromJson(jsonDelta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _quillController = QuillController.basic();
      }
    } else {
      _quillController = QuillController.basic();
      _fetchLocation(); // Auto-tag location for new journals
    }
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    final loc = await LocationService().getCurrentAccurateLocation();
    if (mounted) {
      setState(() {
        _isFetchingLocation = false;
        if (loc != null) {
          _currentLocation = loc;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mendapatkan lokasi akurat.')),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _autoSaveDraft();
    }
  }

  Future<void> _autoSaveDraft() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final plainContent = _quillController.document.toPlainText().trim();
    
    if (title.isEmpty && plainContent.isEmpty && _coverImageFile == null && _existingImageUrl == null) return;

    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

    try {
      final isNew = widget.existingJournal == null && _currentDraftId == null;
      
      final newJournal = JournalModel(
        id: widget.existingJournal?.id ?? _currentDraftId ?? '',
        title: title.isEmpty ? 'Jurnal Tanpa Judul' : title,
        content: contentJson,
        location: _currentLocation.isEmpty ? 'Jakarta, ID' : _currentLocation,
        status: widget.existingJournal?.status ?? 'Draft',
        mood: widget.existingJournal?.mood ?? '📝',
        imageUrl: _existingImageUrl, // Only save existing URL in background. Cover changes wait for manual save.
        createdAt: widget.existingJournal?.createdAt ?? DateTime.now(),
      );

      if (isNew) {
        final newId = await _journalService.createJournal(newJournal);
        _currentDraftId = newId;
      } else {
        await _journalService.updateJournal(newJournal.id, newJournal.toMap());
      }
      debugPrint('Auto-saved draft: ${newJournal.id}');
    } catch (e) {
      debugPrint('Failed to auto-save draft: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _coverImageFile = File(pickedFile.path);
        // Clear existing URL if user picks a new photo
        if (_existingImageUrl != null) {
          _existingImageUrl = null;
        }
      });
    }
  }

  void _showImageSourceBottomSheet() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.glassBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Pilih Foto Sampul', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: themeProvider.primaryTextColor),
                title: Text('Kamera', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: themeProvider.primaryTextColor),
                title: Text('Galeri', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_coverImageFile != null || _existingImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: Text('Hapus Foto', style: GoogleFonts.inter(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _coverImageFile = null;
                      _existingImageUrl = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveJournal() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul jurnal tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? finalImageUrl = _existingImageUrl;
      if (_coverImageFile != null) {
        setState(() { _isUploadingImage = true; });
        finalImageUrl = await _storageService.uploadImage(_coverImageFile!);
        setState(() { _isUploadingImage = false; });
      }

      final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

      MoodAnalysisModel? autoAnalysisResult;
      try {
        final plainContent = _quillController.document.toPlainText().trim();
        if (plainContent.isNotEmpty && plainContent != '\n') {
          autoAnalysisResult = await _aiApiService.analyzeMood(title, plainContent);
        }
      } catch (e) {
        debugPrint('Auto AI analysis failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menganalisis AI, menyimpan jurnal tanpa AI...')),
          );
        }
      }

      final newJournal = JournalModel(
        id: widget.existingJournal != null ? widget.existingJournal!.id : (_currentDraftId ?? ''),
        title: title,
        content: contentJson,
        location: _currentLocation.isEmpty ? 'Jakarta, ID' : _currentLocation,
        status: 'Published',
        mood: autoAnalysisResult != null ? autoAnalysisResult.primaryMood : (widget.existingJournal?.mood ?? '😎'),
        imageUrl: finalImageUrl,
        stressLevel: autoAnalysisResult?.stressLevel ?? widget.existingJournal?.stressLevel,
        happinessLevel: autoAnalysisResult?.happinessLevel ?? widget.existingJournal?.happinessLevel,
        emotionSummary: autoAnalysisResult?.emotionSummary ?? widget.existingJournal?.emotionSummary,
        recommendations: autoAnalysisResult?.recommendations ?? widget.existingJournal?.recommendations,
        createdAt: widget.existingJournal != null ? widget.existingJournal!.createdAt : DateTime.now(),
      );

      if (widget.existingJournal != null || _currentDraftId != null) {
        await _journalService.updateJournal(newJournal.id, newJournal.toMap());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jurnal berhasil diperbarui!')),
        );
        
        final isNotifEnabled = await NotificationService().getNotificationToggle();
        if (isNotifEnabled) {
          await NotificationService().scheduleSmartReminders(hasJournalToday: true);
        }

        if (!mounted) return;
        Navigator.of(context).pop(newJournal);
      } else {
        await _journalService.createJournal(newJournal);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jurnal berhasil dipublikasikan!')),
        );
        
        final isNotifEnabled = await NotificationService().getNotificationToggle();
        if (isNotifEnabled) {
          await NotificationService().scheduleSmartReminders(hasJournalToday: true);
        }

        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan jurnal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (!_isSaving) {
          _autoSaveDraft();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('Tulis Jurnal', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: themeProvider.primaryTextColor),
          centerTitle: true,
        ),
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
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Cover Image Picker
                          GestureDetector(
                            onTap: _showImageSourceBottomSheet,
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: themeProvider.glassBackgroundColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: themeProvider.glassBorderColor),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: _coverImageFile != null
                                  ? Image.file(_coverImageFile!, fit: BoxFit.cover)
                                  : (_existingImageUrl != null
                                      ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo, color: themeProvider.secondaryTextColor, size: 40),
                                            const SizedBox(height: 12),
                                            Text('Tambah Foto Sampul', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor)),
                                          ],
                                        )),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title Input
                          GlassmorphismContainer(
                            borderRadius: 16,
                            child: TextField(
                              controller: _titleController,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.primaryTextColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Beri judul ceritamu hari ini...',
                                hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Quill Toolbar
                          GlassmorphismContainer(
                            borderRadius: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: QuillSimpleToolbar(
                                  controller: _quillController,
                                  config: const QuillSimpleToolbarConfig(
                                    showAlignmentButtons: true,
                                    showClearFormat: false,
                                    showCodeBlock: false,
                                    showColorButton: false,
                                    showBackgroundColorButton: false,
                                    showFontFamily: false,
                                    showFontSize: false,
                                    showIndent: false,
                                    showSearchButton: false,
                                    showInlineCode: false,
                                    showSubscript: false,
                                    showSuperscript: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Main Editor
                          GlassmorphismContainer(
                            borderRadius: 20,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: QuillEditor.basic(
                                controller: _quillController,
                                config: QuillEditorConfig(
                                  placeholder: 'Ceritakan hari Anda...',
                                  customStyles: DefaultStyles(
                                    paragraph: DefaultTextBlockStyle(
                                      GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 16, height: 1.5),
                                      const HorizontalSpacing(0, 0),
                                      const VerticalSpacing(0, 0),
                                      const VerticalSpacing(0, 0),
                                      null,
                                    ),
                                    placeHolder: DefaultTextBlockStyle(
                                      GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 16, height: 1.5),
                                      const HorizontalSpacing(0, 0),
                                      const VerticalSpacing(0, 0),
                                      const VerticalSpacing(0, 0),
                                      null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GlassmorphismContainer(
                      borderRadius: 24,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: _fetchLocation,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Row(
                                      children: [
                                        _isFetchingLocation 
                                          ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: themeProvider.secondaryTextColor))
                                          : Icon(Icons.location_on_outlined, color: themeProvider.secondaryTextColor, size: 14),
                                        const SizedBox(width: 6),
                                        Text(_currentLocation.isEmpty ? 'Tag Lokasi' : _currentLocation, style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  'Tersimpan otomatis sebagai Draft',
                                  style: GoogleFonts.inter(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                            Divider(color: themeProvider.glassBorderColor, height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _saveJournal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.8),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : Text(
                                            _isUploadingImage ? 'Mengunggah Foto...' : 'Publikasikan',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
