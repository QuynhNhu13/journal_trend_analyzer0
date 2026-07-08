import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_bootstrap.dart';

/// Wraps Firebase Storage — used to upload exported PDF reports (lab §4.8).
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Uploads [file] to `reports/<fileName>` and returns its public download URL.
  Future<String> uploadReport(File file, String fileName) async {
    if (!firebaseReady) {
      throw StateError('Firebase chưa cấu hình — không thể tải lên Storage.');
    }
    final ref = _storage.ref().child('reports/$fileName');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'application/pdf'),
    );
    return task.ref.getDownloadURL();
  }
}
