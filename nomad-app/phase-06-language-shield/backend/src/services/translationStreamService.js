const WebSocket = require('ws');
const aiService = require('../services/aiService');

class TranslationStreamService {
  constructor() {
    this.sessions = new Map(); // sessionId -> { sourceLang, targetLang, context }
  }

  async handleConnection(ws, req) {
    const sessionId = req.url.split('?')[1]?.split('=')[1] || this.generateSessionId();
    
    ws.on('message', async (data) => {
      try {
        const message = JSON.parse(data);
        
        switch (message.type) {
          case 'init':
            this.sessions.set(sessionId, {
              sourceLang: message.sourceLang || 'auto',
              targetLang: message.targetLang,
              context: message.context || '',
            });
            ws.send(JSON.stringify({ type: 'ready', sessionId }));
            break;
            
          case 'audio':
            // Receive audio base64, transcribe with Whisper
            const audioBuffer = Buffer.from(message.audio, 'base64');
            const transcription = await this.transcribeAudio(audioBuffer, sessionId);
            
            if (transcription) {
              const session = this.sessions.get(sessionId);
              const translation = await aiService.translate(
                transcription,
                session.targetLang,
                session.context
              );
              
              // Generate TTS audio
              const ttsAudio = await this.generateTTS(translation, session.targetLang);
              
              ws.send(JSON.stringify({
                type: 'translation',
                original: transcription,
                translated: translation,
                audio: ttsAudio ? ttsAudio.toString('base64') : null,
              }));
            }
            break;
            
          case 'text':
            // Direct text translation
            const session = this.sessions.get(sessionId);
            if (session) {
              const translation = await aiService.translate(
                message.text,
                session.targetLang,
                session.context
              );
              
              ws.send(JSON.stringify({
                type: 'translation',
                original: message.text,
                translated: translation,
              }));
            }
            break;
        }
      } catch (error) {
        ws.send(JSON.stringify({ type: 'error', message: error.message }));
      }
    });

    ws.on('close', () => {
      this.sessions.delete(sessionId);
    });
  }

  async transcribeAudio(audioBuffer, sessionId) {
    // Use OpenAI Whisper API
    // For MVP, we'll use a simpler approach - send to /ai/transcribe endpoint
    // In production, use streaming Whisper
    return null; // Placeholder
  }

  async generateTTS(text, lang) {
    // Use Google Cloud TTS or similar
    // Placeholder for MVP
    return null;
  }

  generateSessionId() {
    return Math.random().toString(36).substring(2, 15);
  }
}

module.exports = new TranslationStreamService();
