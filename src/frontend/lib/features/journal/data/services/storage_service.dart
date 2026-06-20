import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    final Reference ref = _storage.ref().child('users/${user.uid}/journals/$fileName');

    try {
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
