import 'dart:convert' as convert;
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../theme/sunset_theme.dart';

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
      final base64Audio = convert.base64Encode(bytes);

      final response = await http.post(
        Uri.parse('http://localhost:3000/ai/transcribe'),
        headers: {'Content-Type': 'application/json'},
        body: convert.jsonEncode({
          'audio': base64Audio,
          'language': _selectedSourceLang == 'auto' ? null : _selectedSourceLang,
        }),
      );

      if (response.statusCode == 200) {
        final data = convert.jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _recognizedText = data['data']['text'];
          });
          await _translateText(_recognizedText);
        }
      }
    } catch (e) {
      debugPrint('Error processing audio: $e');
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
        body: convert.jsonEncode({
          'text': text,
          'targetLang': _selectedTargetLang,
          'context': _selectedContext,
        }),
      );

      if (response.statusCode == 200) {
        final data = convert.jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _translatedText = data['data']['translation'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error translating: $e');
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
    return Container(
      decoration: const BoxDecoration(gradient: SunsetGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const GradientText(
            text: 'Language Shield',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            gradient: LinearGradient(
              colors: [Colors.white, SunsetColors.sunsetYellow],
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Language selectors
            _buildLanguageSelectors(),

            // Context selector
            _buildContextSelector(),

            const Divider(color: Colors.white24),

            // Main content area
            Expanded(
              child: _buildTranslationArea(),
            ),

            // Input area
            _buildInputArea(),
          ],
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.swap_horiz, color: Colors.white),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
              dropdownColor: const Color(0xFF2D2D44),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              items: entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
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
            label: Text(
              context.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            selectedColor: SunsetColors.sunsetRed,
            backgroundColor: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
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
          if (_recognizedText.isNotEmpty) ...[
            _buildTextCard(
              label: 'Recognized',
              text: _recognizedText,
              icon: Icons.mic,
            ),
            const SizedBox(height: 16),
          ],
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
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (_recognizedText.isEmpty && _translatedText.isEmpty && !_isTranslating)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.translate, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Speak or type to translate',
                      style: TextStyle(
                        fontSize: 16,
                        color: SunsetColors.textLightMuted,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHighlighted
                  ? SunsetColors.sunsetRed.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  color: isHighlighted ? Colors.white : Colors.white.withOpacity(0.9),
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isHighlighted)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white70),
                    onPressed: () {
                      // TODO: Play TTS
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: SunsetStyles.glassInput(
                hint: 'Type something...',
              ).copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _handleTextSubmit,
                ),
              ),
              onSubmitted: (_) => _handleTextSubmit(),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTapDown: (_) => _startRecording(),
              onTapUp: (_) => _stopRecording(),
              onTapCancel: () => _stopRecording(),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isRecording
                      ? null
                      : const LinearGradient(
                          colors: [SunsetColors.sunsetRed, SunsetColors.sunsetPink],
                        ),
                  color: _isRecording ? Colors.red : null,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : SunsetColors.sunsetRed)
                          .withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording ? 'Listening...' : 'Hold to speak',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
