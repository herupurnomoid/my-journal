import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/glassmorphism_container.dart';
import '../widgets/glassmorphism_numpad_button.dart';
import '../../data/services/pin_firestore_service.dart';
import '../../../core/presentation/screens/main_navigation_screen.dart';
import 'pin_recovery_screen.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/services/biometric_service.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  final int _pinLength = 4;
  final PinFirestoreService _pinFirestoreService = PinFirestoreService();
  bool _isLoading = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final isEnabled = await BiometricService().getBiometricToggle();
    if (mounted) {
      setState(() => _isBiometricEnabled = isEnabled);
    }
    if (isEnabled) {
      _authenticateBiometric();
    }
  }

  Future<void> _authenticateBiometric() async {
    final authenticated = await BiometricService().authenticate();
    if (authenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sidik Jari dikenali! Aplikasi terbuka.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  void _onNumpadTapped(String value) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += value;
      });
      if (_pin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onBackspaceTapped() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onClearTapped() {
    setState(() {
      _pin = '';
    });
  }

  void _verifyPin() async {
    setState(() {
      _isLoading = true;
    });
    
    final isValid = await _pinFirestoreService.verifyPin(_pin);
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });

    if (isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN Benar! Aplikasi terbuka.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN Salah. Coba lagi.')),
      );
      _onClearTapped();
    }
  }

  void _onForgotPinTapped() {
    // Navigasi ke halaman pemulihan PIN
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PinRecoveryScreen()),
    );
  }

  Widget _buildPinDots(ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        bool isFilled = index < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? themeProvider.primaryTextColor : Colors.transparent,
            border: Border.all(color: themeProvider.primaryTextColor, width: 2),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: themeProvider.primaryTextColor.withValues(alpha: 0.8),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
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
          
          // Center Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Masukkan PIN Anda',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      color: themeProvider.primaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // PIN Dots Placeholder
                  _buildPinDots(themeProvider),
                  const SizedBox(height: 20),
                  if (_isBiometricEnabled)
                    IconButton(
                      icon: Icon(Icons.fingerprint_rounded, color: themeProvider.primaryTextColor, size: 48),
                      onPressed: _authenticateBiometric,
                      tooltip: 'Gunakan Sidik Jari',
                    ),
                  SizedBox(height: _isBiometricEnabled ? 10 : 60),

                  // Glass Container for Numpad
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: GlassmorphismContainer(
                      width: double.infinity,
                      height: 450,
                      child: _isLoading 
                        ? Center(child: CircularProgressIndicator(color: themeProvider.primaryTextColor))
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Numpad Grid
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              childAspectRatio: 1.2,
                              padding: const EdgeInsets.all(16),
                              children: [
                                GlassmorphismNumpadButton(label: '1', onTap: () => _onNumpadTapped('1')),
                                GlassmorphismNumpadButton(label: '2', onTap: () => _onNumpadTapped('2')),
                                GlassmorphismNumpadButton(label: '3', onTap: () => _onNumpadTapped('3')),
                                GlassmorphismNumpadButton(label: '4', onTap: () => _onNumpadTapped('4')),
                                GlassmorphismNumpadButton(label: '5', onTap: () => _onNumpadTapped('5')),
                                GlassmorphismNumpadButton(label: '6', onTap: () => _onNumpadTapped('6')),
                                GlassmorphismNumpadButton(label: '7', onTap: () => _onNumpadTapped('7')),
                                GlassmorphismNumpadButton(label: '8', onTap: () => _onNumpadTapped('8')),
                                GlassmorphismNumpadButton(label: '9', onTap: () => _onNumpadTapped('9')),
                                GlassmorphismNumpadButton(label: 'C', onTap: _onClearTapped),
                                GlassmorphismNumpadButton(label: '0', onTap: () => _onNumpadTapped('0')),
                                GlassmorphismNumpadButton(label: '', icon: Icons.backspace_outlined, onTap: _onBackspaceTapped),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Lupa PIN Hyperlink
                            InkWell(
                              onTap: _onForgotPinTapped,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(
                                  'Lupa PIN?',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: themeProvider.primaryTextColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: themeProvider.primaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
