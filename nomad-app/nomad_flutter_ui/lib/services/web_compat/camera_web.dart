import 'package:flutter/material.dart';
import 'dart:typed_data';

// Web-compatible camera stub
class CameraController {
  final CameraDescription description;
  final ResolutionPreset resolutionPreset;
  final bool enableAudio;
  
  CameraController(this.description, this.resolutionPreset, {this.enableAudio = true});
  
  Future<void> initialize() async {}
  Future<XFile> takePicture() async => XFile('demo.jpg');
  Future<void> dispose() async {}
  
  CameraValue get value => CameraValue();
  bool get isInitialized => true;
}

class CameraValue {
  bool get isInitialized => true;
  bool get isRecordingVideo => false;
  bool get isTakingPicture => false;
}

class CameraPreview extends StatelessWidget {
  final CameraController controller;
  const CameraPreview(this.controller, {super.key});
  
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.grey[900],
    child: const Center(
      child: Icon(Icons.camera_alt, size: 64, color: Colors.white54),
    ),
  );
}

class XFile {
  final String path;
  XFile(this.path);
  Future<String> readAsString() async => '';
  Future<Uint8List> readAsBytes() async => Uint8List(0);
}

class CameraDescription {
  final String name;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;
  
  CameraDescription({this.name = 'demo', this.lensDirection = CameraLensDirection.back, this.sensorOrientation = 0});
}

enum CameraLensDirection { front, back, external }

enum ResolutionPreset { low, medium, high, veryHigh, ultraHigh, max }

Future<List<CameraDescription>> availableCameras() async => [
  CameraDescription(name: 'back', lensDirection: CameraLensDirection.back, sensorOrientation: 90),
];
