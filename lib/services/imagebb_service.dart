import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageBBService {
  static const String _apiKey =
      String.fromEnvironment('IMGBB_API_KEY');

  static Future<String?> uploadImageBytes(
    Uint8List bytes, {
    String? name,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint('IMGBB_API_KEY is missing.');
      return null;
    }

    try {
      final uri = Uri.parse(
        'https://api.imgbb.com/1/upload?key=$_apiKey',
      );

      final response = await http.post(
        uri,
        body: {
          'image': base64Encode(bytes),
          'name': name ??
              'patient_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      debugPrint('ImgBB status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final imageData =
              data['data'] as Map<String, dynamic>;

          return imageData['url'] as String?;
        }
      }

      debugPrint('ImgBB upload failed: ${response.body}');
    } catch (e) {
      debugPrint('ImgBB upload error: $e');
    }

    return null;
  }
}