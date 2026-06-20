import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../main.dart';
import '../../../../shared/widgets/glassmorphism_container.dart';
import '../../../auth/data/services/pin_firestore_service.dart';
import '../../../settings/presentation/screens/pin_change_screen.dart';
import '../../../journal/data/services/journal_firestore_service.dart';
import '../../../journal/data/models/journal_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/export_data_card.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/services/biometric_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final JournalFirestoreService _journalService = JournalFirestoreService();
  bool _isNotificationEnabled = true;
  bool _isBiometricEnabled = false;
  final PinFirestoreService _pinFirestoreService = PinFirestoreService();
  bool _isPinEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
    _checkPinStatus();
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final isEnabled = await BiometricService().getBiometricToggle();
    if (mounted) {
      setState(() => _isBiometricEnabled = isEnabled);
    }
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await _pinFirestoreService.hasPinSetup();
    if (mounted) {
      setState(() => _isPinEnabled = hasPin);
    }
  }

  void _togglePin(bool value) async {
    if (value) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PinChangeScreen(mode: PinChangeMode.create)),
      );
      if (result == true) _checkPinStatus();
    } else {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PinChangeScreen(mode: PinChangeMode.delete)),
      );
      if (result == true) {
        _checkPinStatus();
        // Mematikan biometrik secara paksa jika PIN dimatikan
        if (_isBiometricEnabled) {
          setState(() => _isBiometricEnabled = false);
          await BiometricService().setBiometricToggle(false);
        }
      }
    }
  }

  void _changePin() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinChangeScreen(mode: PinChangeMode.update)),
    );
  }

  Future<void> _loadNotificationSetting() async {
    final isEnabled = await NotificationService().getNotificationToggle();
    if (mounted) {
      setState(() => _isNotificationEnabled = isEnabled);
    }
  }
  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text('Keluar Akun?', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Apakah Anda yakin ingin keluar dari akun ini? Anda harus login kembali nanti.',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Batal', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Keluar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Profil Saya', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Latar Belakang Gradien
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
            bottom: false,
            child: StreamBuilder<List<JournalModel>>(
              stream: _journalService.getJournalsStream(),
              builder: (context, snapshot) {
                final allJournals = snapshot.data ?? [];
                
                // Hitung Streak
                int streak = 0;
                final now = DateTime.now();
                DateTime checkDate = now;
                final journalDates = allJournals.map((j) => DateFormat('yyyy-MM-dd').format(j.createdAt)).toSet();

                if (!journalDates.contains(DateFormat('yyyy-MM-dd').format(now))) {
                  checkDate = now.subtract(const Duration(days: 1));
                }
                
                while (journalDates.contains(DateFormat('yyyy-MM-dd').format(checkDate))) {
                  streak++;
                  checkDate = checkDate.subtract(const Duration(days: 1));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 180.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar & Info Card
                  GlassmorphismContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                            child: user?.photoURL != null
                                ? ClipOval(
                                    child: Image.network(user!.photoURL!, width: 100, height: 100, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(Icons.person, color: themeProvider.isDarkMode ? Colors.white : Colors.black45, size: 60),
                                    ),
                                  )
                                : Icon(Icons.person, color: themeProvider.isDarkMode ? Colors.white : Colors.black45, size: 60),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user?.displayName ?? 'Pengguna',
                            style: GoogleFonts.outfit(color: themeProvider.primaryTextColor, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'email@example.com',
                            style: GoogleFonts.inter(color: themeProvider.secondaryTextColor, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Lencana Pencapaian (Gamification)
                  Text('Lencana Pencapaian', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildBadge(
                          icon: Icons.local_fire_department_rounded,
                          color: streak >= 3 ? Colors.orangeAccent : Colors.grey,
                          title: 'On Fire',
                          subtitle: 'Streak > 3',
                          isUnlocked: streak >= 3,
                        ),
                        const SizedBox(width: 16),
                        _buildBadge(
                          icon: Icons.edit_document,
                          color: allJournals.length >= 10 ? Colors.blueAccent : Colors.grey,
                          title: 'Rajin Menulis',
                          subtitle: '10+ Jurnal',
                          isUnlocked: allJournals.length >= 10,
                        ),
                        const SizedBox(width: 16),
                        _buildBadge(
                          icon: Icons.nightlight_round,
                          color: Colors.purpleAccent,
                          title: 'Night Owl',
                          subtitle: 'Sering Begadang',
                          isUnlocked: true, // Example fixed
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Ekspor Data
                  Text('Ekspor Data', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const ExportDataCard(),
                  const SizedBox(height: 32),

                  // Pengaturan Cepat
                  Text('Pengaturan Cepat', style: GoogleFonts.inter(color: themeProvider.primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GlassmorphismContainer(
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          SwitchListTile(
                          title: Text('Notifikasi Pengingat', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
                          secondary: const Icon(Icons.notifications_active_rounded, color: Colors.amberAccent),
                          value: _isNotificationEnabled,
                          activeTrackColor: Colors.blueAccent,
                          onChanged: (val) async {
                            setState(() => _isNotificationEnabled = val);
                            final now = DateTime.now();
                            final todayStr = DateFormat('yyyy-MM-dd').format(now);
                            final hasJournalToday = journalDates.contains(todayStr);
                            await NotificationService().setNotificationToggle(val, hasJournalToday: hasJournalToday);
                          },
                        ),
                        Divider(color: themeProvider.glassBorderColor, height: 1),
                        SwitchListTile(
                          title: Text('Tema Gelap', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
                          secondary: const Icon(Icons.dark_mode_rounded, color: Colors.purpleAccent),
                          value: themeProvider.isDarkMode,
                          activeTrackColor: Colors.blueAccent,
                          onChanged: (val) {
                            themeProvider.toggleTheme(val);
                          },
                        ),
                        Divider(color: themeProvider.glassBorderColor, height: 1),
                        SwitchListTile(
                          title: Text('Kunci Biometrik (Sidik Jari)', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
                          secondary: const Icon(Icons.fingerprint_rounded, color: Colors.greenAccent),
                          value: _isBiometricEnabled,
                          activeTrackColor: Colors.blueAccent,
                          onChanged: (val) async {
                            if (val) {
                              if (!_isPinEnabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Anda harus mengaktifkan PIN terlebih dahulu sebelum mengatur sidik jari.', style: GoogleFonts.inter()),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }
                              
                              final hasBiometrics = await BiometricService().hasBiometrics();
                              if (!hasBiometrics) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Perangkat ini tidak mendukung kunci sidik jari atau belum diatur.', style: GoogleFonts.inter()),
                                    backgroundColor: Colors.orangeAccent,
                                  ),
                                );
                                return;
                              }

                              final authenticated = await BiometricService().authenticate();
                              if (authenticated) {
                                setState(() => _isBiometricEnabled = true);
                                await BiometricService().setBiometricToggle(true);
                              }
                            } else {
                              setState(() => _isBiometricEnabled = false);
                              await BiometricService().setBiometricToggle(false);
                            }
                          },
                        ),
                        Divider(color: themeProvider.glassBorderColor, height: 1),
                        SwitchListTile(
                          title: Text('Aktifkan PIN Keamanan', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
                          secondary: const Icon(Icons.security_rounded, color: Colors.orangeAccent),
                          value: _isPinEnabled,
                          onChanged: _togglePin,
                          activeTrackColor: Colors.blueAccent,
                        ),
                        if (_isPinEnabled) ...[
                          Divider(color: themeProvider.glassBorderColor, height: 1),
                          ListTile(
                            leading: const Icon(Icons.lock_outline_rounded, color: Colors.redAccent),
                            title: Text('Ubah PIN', style: GoogleFonts.inter(color: themeProvider.primaryTextColor)),
                            trailing: Icon(Icons.chevron_right_rounded, color: themeProvider.secondaryTextColor),
                            onTap: _changePin,
                          ),
                        ]
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  GestureDetector(
                    onTap: _logout,
                    child: GlassmorphismContainer(
                      borderRadius: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Text('Keluar dari Akun', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
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

  Widget _buildBadge({required IconData icon, required Color color, required String title, required String subtitle, required bool isUnlocked}) {
    return GlassmorphismContainer(
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.transparent : Colors.black.withValues(alpha: 0.3),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? color.withOpacity(0.2) : (Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white10 : Colors.black12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Provider.of<ThemeProvider>(context).primaryTextColor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Provider.of<ThemeProvider>(context).secondaryTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
