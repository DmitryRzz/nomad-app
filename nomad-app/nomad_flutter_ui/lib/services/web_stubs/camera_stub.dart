class CameraController {
  CameraController(dynamic camera, dynamic resolutionPreset, {bool enableAudio = true});
  Future<void> initialize() async {}
  Future<XFile> takePicture() async => XFile('');
  Future<void> dispose() async {}
  bool get value => false;
  bool get isInitialized => false;
}

class CameraPreview extends StatelessWidget {
  final CameraController controller;
  const CameraPreview(this.controller, {super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Camera not available'));
}

class XFile {
  final String path;
  XFile(this.path);
  Future<String> readAsString() async => '';
}

class CameraDescription {}
Future<List<CameraDescription>> availableCameras() async => [];

// Stub for dart:io
class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
}
