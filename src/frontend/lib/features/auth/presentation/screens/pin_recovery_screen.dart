import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/widgets/glassmorphism_container.dart';
import '../widgets/glassmorphism_textfield.dart';
import '../../data/services/pin_api_service.dart';
import '../../data/services/pin_firestore_service.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';

class PinRecoveryScreen extends StatefulWidget {
  const PinRecoveryScreen({super.key});

  @override
  State<PinRecoveryScreen> createState() => _PinRecoveryScreenState();
}

class _PinRecoveryScreenState extends State<PinRecoveryScreen> {
  final PageController _pageController = PageController();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  
  // 6 controllers for OTP digits
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  final PinApiService _pinApiService = PinApiService();
  final PinFirestoreService _pinFirestoreService = PinFirestoreService();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    for (var c in _otpControllers) { c.dispose(); }
    for (var f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // Step 1
  void _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() { _isLoading = true; });

    try {
      await _pinApiService.forgotPin(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP berhasil dikirim ke email Anda!')),
      );
      _nextPage();
      // Focus ke kotak OTP pertama
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // Step 2
  void _verifyOtp() async {
    final email = _emailController.text.trim();
    final otpCode = _otpControllers.map((c) => c.text).join();

    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP harus 6 digit')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Verifikasi OTP ke backend Python
      await _pinApiService.verifyOtp(email, otpCode);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Valid! Silakan buat PIN baru.')));
      _nextPage();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // Step 3
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN berhasil dipulihkan!')),
      );
      Navigator.of(context).pop(); // Kembali ke pengaturan atau login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          child: GlassmorphismTextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            hintText: '',
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            contentPadding: const EdgeInsets.symmetric(vertical: 16), // Reduce horizontal padding for tiny box
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildStepWrapper({required String title, required String subtitle, required Widget child}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle, style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 14), textAlign: TextAlign.center),
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Pemulihan PIN', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
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
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // STEP 1: Email
                _buildStepWrapper(
                  title: 'Dapatkan OTP',
                  subtitle: 'Kami akan mengirimkan 6 digit kode OTP ke email Anda untuk memverifikasi identitas.',
                  child: Column(
                    children: [
                      GlassmorphismTextField(
                        controller: _emailController,
                        hintText: 'Alamat Email',
                        readOnly: true, // Email diambil otomatis
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.isDarkMode ? Colors.white.withOpacity(0.25) : const Color(0xFF448AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Kirim OTP'),
                        ),
                      ),
                    ],
                  ),
                ),

                // STEP 2: Verifikasi OTP
                _buildStepWrapper(
                  title: 'Masukkan OTP',
                  subtitle: 'Silakan periksa kotak masuk atau folder spam email Anda.',
                  child: Column(
                    children: [
                      _buildOtpBoxes(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.isDarkMode ? Colors.white.withOpacity(0.25) : const Color(0xFF448AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Verifikasi OTP'),
                        ),
                      ),
                    ],
                  ),
                ),

                // STEP 3: Buat PIN Baru
                _buildStepWrapper(
                  title: 'Atur PIN Baru',
                  subtitle: 'Keamanan sudah terverifikasi. Masukkan 4 angka PIN rahasia Anda yang baru.',
                  child: Column(
                    children: [
                      GlassmorphismTextField(
                        controller: _newPinController,
                        hintText: 'PIN Baru (4 Digit)',
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      GlassmorphismTextField(
                        controller: _confirmPinController,
                        hintText: 'Konfirmasi PIN Baru',
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
                              : const Text('Simpan PIN Baru'),
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
