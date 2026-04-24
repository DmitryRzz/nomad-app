// Web-compatible flutter_sound stub
class FlutterSoundRecorder {
  bool _isRecording = false;
  
  Future<void> openRecorder() async {}
  Future<void> closeRecorder() async {}
  Future<void> startRecorder({String? toFile, Codec codec = Codec.aacADTS}) async {
    _isRecording = true;
  }
  Future<String?> stopRecorder() async {
    _isRecording = false;
    return 'demo_recording.aac';
  }
  bool get isRecording => _isRecording;
}

class FlutterSoundPlayer {
  bool _isPlaying = false;
  
  Future<void> openPlayer() async {}
  Future<void> closePlayer() async {}
  Future<void> startPlayer({String? fromURI, Codec codec = Codec.aacADTS}) async {
    _isPlaying = true;
  }
  Future<void> stopPlayer() async {
    _isPlaying = false;
  }
  bool get isPlaying => _isPlaying;
}

enum Codec {
  aacADTS,
  opusOGG,
  mp3,
  pcm16WAV,
}
