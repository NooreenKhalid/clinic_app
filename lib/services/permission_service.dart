import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Storage / Media permission (Android 13+ & below)
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.photos.isGranted ||
          await Permission.storage.isGranted) {
        return true;
      }

      // Android 13+
      if (await Permission.photos.request().isGranted) {
        return true;
      }

      // Android 12 & below
      if (await Permission.storage.request().isGranted) {
        return true;
      }

      return false;
    }
    return true;
  }
}
