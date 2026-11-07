import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

/// Cloudinary replaces Firebase Storage because Storage requires the paid
/// Blaze plan; switch back by changing only this service file.
class StorageService {
  Future<({String path, String url})> uploadIncidentImage({
    required String uid,
    required String incidentId,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://api.cloudinary.com/v1_1/'
        '${CloudinaryConfig.cloudName}/image/upload',
      ),
    )
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = 'incident_images/$uid'
      ..fields['public_id'] = incidentId
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$incidentId.jpg',
        ),
      );

    onProgress?.call(0.1);
    try {
      return await (() async {
        final response = await request.send();
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        if (response.statusCode != 200) {
          final error = json['error'] as Map<String, dynamic>?;
          throw Exception(
            'Photo upload failed: ${error?['message'] ?? 'Unknown Cloudinary error'}',
          );
        }

        onProgress?.call(1);
        return (
          path: json['public_id'] as String,
          url: json['secure_url'] as String,
        );
      })()
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw Exception(
        'Photo upload timed out. Check your internet connection.',
      );
    }
  }

  Future<void> deleteImage(String path) async {
    // Unsigned presets cannot delete; deletion requires a secret API key that
    // must never be embedded in a mobile app. Remove unreferenced photos from
    // the Cloudinary dashboard.
  }
}
