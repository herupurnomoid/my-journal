import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PinFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// Menyimpan PIN baru ke dokumen `users/{uid}`
  Future<void> savePin(String pin) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('User tidak terautentikasi.');
    }

    // Validasi hanya angka
    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      throw Exception('PIN hanya boleh berisi angka.');
    }

    try {
      await _firestore.collection('users').doc(uid).set(
        {'pin': pin},
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Gagal menyimpan PIN ke database: $e');
    }
  }

  /// Menghapus PIN dari dokumen (Mematikan fitur PIN)
  Future<void> deletePin() async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('User tidak terautentikasi.');
    }

    try {
      await _firestore.collection('users').doc(uid).update({
        'pin': FieldValue.delete(),
      });
    } catch (e) {
      // Jika dokumen tidak ada, tidak perlu melempar error
      debugPrint('Error menghapus PIN: $e');
    }
  }

  /// Memverifikasi PIN dengan mencocokkan input terhadap data di Firestore
  Future<bool> verifyPin(String inputPin) async {
    final uid = currentUid;
    if (uid == null) return false;

    try {
      // Baca dari source cache terlebih dahulu jika offline
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final savedPin = doc.data()?['pin'] as String?;
        return savedPin == inputPin;
      }
      return false;
    } catch (e) {
      debugPrint('Error memverifikasi PIN: $e');
      return false;
    }
  }

  /// Memeriksa apakah user saat ini sudah pernah mengatur PIN
  Future<bool> hasPinSetup() async {
    final uid = currentUid;
    if (uid == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['pin'] != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
