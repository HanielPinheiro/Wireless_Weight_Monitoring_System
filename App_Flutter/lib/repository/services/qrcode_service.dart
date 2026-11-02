import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrCode extends StatefulWidget {
  @override
  State<ScanQrCode> createState() => _ScanQrState();
}

class _ScanQrState extends State<ScanQrCode> {
  bool state = true;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
        controller: MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, returnImage: true),
        onDetect: (capture) {
          if (state) {
            final Uint8List? image = capture.image;
            final String? qrText = capture.barcodes.first.rawValue;

            if (image != null && qrText != null) {
              state = false; // Prevent multiple triggers
              Navigator.pop(context, {'text': qrText, 'image': image}); // Return data to HomePage
            }
          }
        });
  }
}