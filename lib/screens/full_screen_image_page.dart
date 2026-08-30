import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/permission_service.dart';

// ⚠️ important: html sirf web k liye

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String patientName;

  const FullScreenImagePage({
    super.key,
    required this.imageUrl,
    required this.patientName,
  });

  void _show(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> saveImage(BuildContext context) async {
    try {
      final res = await http.get(Uri.parse(imageUrl));
      final bytes = res.bodyBytes;

      if (kIsWeb) {
        _show(context, "Image saving is available in the Android app");
        return;
      }

      final allowed = await PermissionService.requestStoragePermission();
      if (!allowed) {
        _show(context, "Permission denied");
        return;
      }

      await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(bytes),
        quality: 100,
        name: patientName,
      );

      _show(context, "Saved to gallery");
    } catch (e) {
      _show(context, "Save failed");
    }
  }

  Future<void> savePdf(BuildContext context) async {
    try {
      final res = await http.get(Uri.parse(imageUrl));
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (_) =>
              pw.Center(child: pw.Image(pw.MemoryImage(res.bodyBytes))),
        ),
      );

      final pdfBytes = await pdf.save();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: "$patientName.pdf",
      );
    } catch (e) {
      _show(context, "PDF failed");
    }
  }

  Widget _sheet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Download Options",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text("Save Image"),
            onTap: () {
              Navigator.pop(context);
              saveImage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text("Save PDF"),
            onTap: () {
              Navigator.pop(context);
              savePdf(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => _sheet(context),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
