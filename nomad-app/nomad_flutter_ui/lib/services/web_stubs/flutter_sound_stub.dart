// Web stub for flutter_sound
class FlutterSoundRecorder {
  Future<void> openRecorder() async {}
  Future<void> closeRecorder() async {}
  Future<void> startRecorder({String? toFile, Codec codec = Codec.aacADTS}) async {}
  Future<String?> stopRecorder() async => null;
  bool get isRecording => false;
}

class FlutterSoundPlayer {
  Future<void> openPlayer() async {}
  Future<void> closePlayer() async {}
  Future<void> startPlayer({String? fromURI, Codec codec = Codec.aacADTS}) async {}
  Future<void> stopPlayer() async {}
  bool get isPlaying => false;
}

enum Codec {
  aacADTS,
  opusOGG,
  mp3,
}
