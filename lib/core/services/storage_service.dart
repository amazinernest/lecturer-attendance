import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static const String bucketName = 'lecturers-attendance-files';

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Uploads binary bytes to Supabase Storage under bucket 'lecturers-attendance-files'
  /// Path: {userId}/{category}/{timestamp}_{fileName}
  Future<String?> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String category, // 'imports', 'reports', 'avatars'
    String? mimeType,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      debugPrint('Storage upload skipped: user not authenticated or Supabase not initialized.');
      return null;
    }

    try {
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\._-]'), '_');
      final path = '${user.id}/$category/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

      await client.storage.from(bucketName).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: true,
        ),
      );

      final publicUrl = client.storage.from(bucketName).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase Storage upload error: $e');
      return null;
    }
  }

  /// Uploads profile avatar image and returns public URL
  Future<String?> uploadAvatar(Uint8List imageBytes, String fileName) async {
    return uploadFile(
      bytes: imageBytes,
      fileName: fileName,
      category: 'avatars',
    );
  }

  /// Uploads imported class list raw file
  Future<String?> uploadImportedDocument(Uint8List fileBytes, String fileName) async {
    return uploadFile(
      bytes: fileBytes,
      fileName: fileName,
      category: 'imports',
    );
  }

  /// Uploads generated attendance report (PDF/Excel)
  Future<String?> uploadReportDocument(Uint8List fileBytes, String fileName) async {
    return uploadFile(
      bytes: fileBytes,
      fileName: fileName,
      category: 'reports',
    );
  }
}
