import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_model.dart';

class JournalFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _journalsRef {
    final uid = currentUid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('journals');
  }

  /// Mendengarkan perubahan daftar jurnal secara real-time
  Stream<List<JournalModel>> getJournalsStream() {
    final ref = _journalsRef;
    if (ref == null) return Stream.value([]);

    return ref.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return JournalModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Membuat jurnal baru
  Future<String> createJournal(JournalModel journal) async {
    final ref = _journalsRef;
    if (ref == null) throw Exception('User not authenticated');

    final docRef = await ref.add(journal.toMap());
    return docRef.id;
  }

  /// Memperbarui jurnal
  Future<void> updateJournal(String journalId, Map<String, dynamic> data) async {
    final ref = _journalsRef;
    if (ref == null) throw Exception('User not authenticated');

    await ref.doc(journalId).update(data);
  }

  /// Menghapus jurnal
  Future<void> deleteJournal(String journalId) async {
    final ref = _journalsRef;
    if (ref == null) throw Exception('User not authenticated');

    await ref.doc(journalId).delete();
  }
}
