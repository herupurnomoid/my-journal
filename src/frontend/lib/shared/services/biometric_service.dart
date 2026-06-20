import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricPrefKey = 'is_biometric_enabled';

  /// Cek apakah device memiliki hardware biometrik dan sudah mendaftarkan biometrik (sidik jari/face id)
  Future<bool> hasBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Meminta pengguna untuk memindai sidik jari / Face ID
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari Anda untuk membuka kunci jurnal',
        biometricOnly: true, // Hanya menggunakan biometrik, bukan PIN HP bawaan
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      return false;
    }
  }

  /// Mengambil status toggle biometrik di penyimpanan lokal
  Future<bool> getBiometricToggle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricPrefKey) ?? false;
  }

  /// Menyimpan status toggle biometrik ke penyimpanan lokal
  Future<void> setBiometricToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricPrefKey, value);
  }
}
