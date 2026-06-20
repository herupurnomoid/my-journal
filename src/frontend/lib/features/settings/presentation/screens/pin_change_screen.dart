import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/glassmorphism_container.dart';
import '../../../auth/presentation/widgets/glassmorphism_textfield.dart';
import '../../../auth/data/services/pin_firestore_service.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';

enum PinChangeMode { create, update, delete }

class PinChangeScreen extends StatefulWidget {
  final PinChangeMode mode;

  const PinChangeScreen({super.key, required this.mode});

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen> {
  final PageController _pageController = PageController();
  final PinFirestoreService _pinFirestoreService = PinFirestoreService();
  
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _verifyOldPin() async {
    final oldPin = _oldPinController.text;
    if (oldPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN harus 4 digit')));
      return;
    }

    setState(() { _isLoading = true; });
    final isValid = await _pinFirestoreService.verifyPin(oldPin);
    setState(() { _isLoading = false; });

    if (isValid) {
      if (widget.mode == PinChangeMode.delete) {
        _deletePin();
      } else {
        _nextPage();
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Lama Salah')));
    }
  }

  void _saveNewPin() async {
    final newPin = _newPinController.text;
    final confirmPin = _confirmPinController.text;

    if (newPin.length != 4 || confirmPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN harus 4 digit')));
      return;
    }
    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi PIN tidak cocok')));
      return;
    }

    setState(() { _isLoading = true; });
    try {
      await _pinFirestoreService.savePin(newPin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN berhasil disimpan!')));
      Navigator.of(context).pop(true); // Return true indicating success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _deletePin() async {
    setState(() { _isLoading = true; });
    try {
      await _pinFirestoreService.deletePin();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN berhasil dinonaktifkan!')));
      Navigator.of(context).pop(true); // Return true indicating success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menonaktifkan: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Widget _buildStepWrapper({required String title, required Widget child}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GlassmorphismContainer(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    String titleText = 'Atur PIN';
    if (widget.mode == PinChangeMode.update) titleText = 'Ubah PIN';
    if (widget.mode == PinChangeMode.delete) titleText = 'Matikan PIN';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(titleText, style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.primaryTextColor),
      ),
      body: Stack(
        children: [
          // Background
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
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              children: [
                if (widget.mode != PinChangeMode.create)
                  // Step: Input Old PIN
                  _buildStepWrapper(
                    title: 'Verifikasi Identitas',
                    child: Column(
                      children: [
                        Text('Masukkan PIN Anda saat ini', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor)),
                        const SizedBox(height: 20),
                        GlassmorphismTextField(
                          controller: _oldPinController,
                          hintText: 'PIN Lama (4 Digit)',
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOldPin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.isDarkMode ? Colors.white.withOpacity(0.25) : const Color(0xFF448AFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Lanjutkan'),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (widget.mode != PinChangeMode.delete)
                  // Step: Input New PIN
                  _buildStepWrapper(
                    title: widget.mode == PinChangeMode.create ? 'Buat Keamanan' : 'PIN Baru',
                    child: Column(
                      children: [
                        Text('Masukkan 4 angka untuk PIN Anda', style: GoogleFonts.inter(color: themeProvider.secondaryTextColor)),
                        const SizedBox(height: 20),
                        GlassmorphismTextField(
                          controller: _newPinController,
                          hintText: 'PIN Baru',
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        GlassmorphismTextField(
                          controller: _confirmPinController,
                          hintText: 'Konfirmasi PIN',
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveNewPin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.isDarkMode ? Colors.white.withOpacity(0.25) : const Color(0xFF448AFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Simpan PIN'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
