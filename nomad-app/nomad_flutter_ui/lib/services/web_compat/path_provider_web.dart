// Web-compatible path_provider stub
import 'dart:html' as html;

Future<Directory> getApplicationDocumentsDirectory() async => Directory('web_docs');
Future<Directory> getApplicationSupportDirectory() async => Directory('web_support');
Future<Directory> getTemporaryDirectory() async => Directory('web_temp');
Future<Directory> getDownloadsDirectory() async => Directory('web_downloads');

class Directory {
  final String path;
  Directory(this.path);
  Future<bool> exists() async => true;
  Future<Directory> create({bool recursive = false}) async => this;
}

class File {
  final String path;
  File(this.path);
  Future<bool> exists() async => false;
  Future<String> readAsString() async => '';
  Future<void> writeAsString(String contents, {bool flush = false}) async {
    html.window.localStorage[path] = contents;
  }
}
