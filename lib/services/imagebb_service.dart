import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// ---------------- ImageBB Service ----------------
/// Works for Flutter Web, Android, iOS, and Desktop
class ImageBBService {
  // 🔑 Replace with your own ImageBB API key
  static const String apiKey = "bd21eea30a5602298f5604400020d5d0";

  /// Uploads a Uint8List (from ImagePicker or Web picker) to ImageBB
  /// Returns the public URL of the uploaded image, or null on failure
  static Future<String?> uploadImageBytes(Uint8List bytes,
      {String? name}) async {
    try {
      // Convert bytes to Base64
      final base64Image = base64Encode(bytes);

      // Create ImageBB URI
      final uri = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");

      // POST request to ImageBB
      final response = await http.post(uri, body: {
        'image': base64Image,
        'name': name ?? 'image_${DateTime.now().millisecondsSinceEpoch}',
      });

      // Check for success
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['url'] as String?;
        } else {
          print("ImgBB error: ${data['error']}");
        }
      } else {
        print("ImgBB upload failed: ${response.statusCode} - ${response.body}");
      }

      return null;
    } catch (e) {
      print("Exception uploading image to ImageBB: $e");
      return null;
    }
  }
}
