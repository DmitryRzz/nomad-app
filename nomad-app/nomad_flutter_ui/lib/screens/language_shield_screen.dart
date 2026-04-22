import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class LanguageShieldScreen extends StatefulWidget {
  const LanguageShieldScreen({super.key});

  @override
  State<LanguageShieldScreen> createState() => _LanguageShieldScreenState();
}

class _LanguageShieldScreenState extends State<LanguageShieldScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final TextEditingController _textController = TextEditingController();
  
  bool _isRecording = false;
  bool _isTranslating = false;
  String _recognizedText = '';
  String _translatedText = '';
  String _selectedSourceLang = 'auto';
  String _selectedTargetLang = 'en';
  String _selectedContext = 'general';
  
  final List<String> _contexts = [
    'general', 'restaurant', 'taxi', 'hotel', 'shopping', 'airport'
  ];
  
  final Map<String, String> _languages = {
    'auto': 'Auto Detect',
    'en': 'English',
    'ru': 'Russian',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ar': 'Arabic',
    'pt': 'Portuguese',
  };

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/translation_${DateTime.now().millisecondsSinceEpoch}.aac';
    
    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
    );
    
    setState(() {
      _isRecording = true;
      _recognizedText = '';
      _translatedText = '';
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecorder();
    setState(() => _isRecording = false);
    
    if (path != null) {
      await _processAudio(path);
    }
  }

  Future<void> _processAudio(String path) async {
    setState(() => _isTranslating = true);
    
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('http://localhost:3000/ai/transcribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio': base64Audio,
          'language': _selectedSourceLang == 'auto' ? null : _selectedSourceLang,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _recognizedText = data['data']['text'];
          });
          await _translateText(_recognizedText);
        }
      }
    } catch (e) {
      print('Error processing audio: $e');
    } finally {
      setState(() => _isTranslating = false);
    }
  }

  Future<void> _translateText(String text) async {
    if (text.isEmpty) return;
    
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/ai/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'targetLang': _selectedTargetLang,
          'context': _selectedContext,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _translatedText = data['data']['translation'];
          });
        }
      }
    } catch (e) {
      print('Error translating: $e');
    }
  }

  void _handleTextSubmit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _translateText(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Shield'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Language selectors
          _buildLanguageSelectors(),
          
          // Context selector
          _buildContextSelector(),
          
          const Divider(),
          
          // Main content area
          Expanded(
            child: _buildTranslationArea(),
          ),
          
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectors() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildLangDropdown(
              label: 'From',
              value: _selectedSourceLang,
              onChanged: (val) => setState(() => _selectedSourceLang = val!),
              includeAuto: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.arrow_forward,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: _buildLangDropdown(
              label: 'To',
              value: _selectedTargetLang,
              onChanged: (val) => setState(() => _selectedTargetLang = val!),
              includeAuto: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangDropdown({
    required String label,
    required String value,
    required Function(String?) onChanged,
    required bool includeAuto,
  }) {
    final entries = includeAuto 
        ? _languages.entries 
        : _languages.entries.where((e) => e.key != 'auto');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildContextSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: _contexts.map((context) {
          final isSelected = _selectedContext == context;
          return ChoiceChip(
            label: Text(context.toUpperCase()),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedContext = context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTranslationArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Recognized text
          if (_recognizedText.isNotEmpty) ...[
            _buildTextCard(
              label: 'Recognized',
              text: _recognizedText,
              icon: Icons.mic,
            ),
            const SizedBox(height: 16),
          ],
          
          // Translated text
          if (_translatedText.isNotEmpty) ...[
            _buildTextCard(
              label: 'Translation',
              text: _translatedText,
              icon: Icons.translate,
              isHighlighted: true,
            ),
          ],
          
          if (_isTranslating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          
          if (_recognizedText.isEmpty && _translatedText.isEmpty && !_isTranslating)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.translate,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Speak or type to translate',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextCard({
    required String label,
    required String text,
    required IconData icon,
    bool isHighlighted = false,
  }) {
    return Card(
      color: isHighlighted ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(fontSize: 18),
            ),
            if (isHighlighted)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    // TODO: Play TTS
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text input
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type text to translate...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleTextSubmit,
                ),
              ),
              onSubmitted: (_) => _handleTextSubmit(),
            ),
            const SizedBox(height: 16),
            
            // Voice button
            GestureDetector(
              onTapDown: (_) => _startRecording(),
              onTapUp: (_) => _stopRecording(),
              onTapCancel: () => _stopRecording(),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording 
                      ? Colors.red 
                      : Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Theme.of(context).colorScheme.primary)
                          .withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording ? 'Listening...' : 'Hold to speak',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
