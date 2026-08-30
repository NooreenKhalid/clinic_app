import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageBBService {
  static const String _apiKey = String.fromEnvironment('IMGBB_API_KEY');

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
        'https://api.imgbb.com/1/upload',
      );

      final request = http.MultipartRequest('POST', uri);

      request.fields['key'] = _apiKey;
      request.fields['name'] =
          name ?? 'image_${DateTime.now().millisecondsSinceEpoch}';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'image.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('ImgBB status: ${response.statusCode}');
      debugPrint('ImgBB response: ${response.body}');

      if (response.statusCode != 200) {
        debugPrint('ImgBB upload failed.');
        return null;
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        debugPrint('ImgBB returned invalid JSON.');
        return null;
      }

      if (data['success'] != true) {
        debugPrint('ImgBB upload unsuccessful: $data');
        return null;
      }

      final imageData = data['data'];

      if (imageData is! Map<String, dynamic>) {
        debugPrint('ImgBB image data missing.');
        return null;
      }

      final url = imageData['url'];

      if (url is String && url.isNotEmpty) {
        debugPrint('ImgBB image URL: $url');
        return url;
      }

      debugPrint('ImgBB image URL missing.');
    } catch (e) {
      debugPrint('ImgBB upload error: $e');
    }

    return null;
  }
}
