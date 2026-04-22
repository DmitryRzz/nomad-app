const aiService = require('../services/aiService');
const fs = require('fs');
const path = require('path');

async function routes(fastify, options) {
  // POST /ai/generate-route - Generate AI route
  fastify.post('/generate-route', async (request, reply) => {
    try {
      const { city, country, interests, budgetLevel, pace, weather, numStops } = request.body;

      if (!city) {
        reply.code(400);
        return { success: false, error: 'City is required' };
      }

      const route = await aiService.generateRoute({
        city,
        country,
        interests,
        budgetLevel,
        pace,
        weather,
        numStops,
      });

      return { success: true, data: route };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // POST /ai/adapt-route - Adapt route for weather
  fastify.post('/adapt-route', async (request, reply) => {
    try {
      const { route, newWeather } = request.body;

      if (!route || !newWeather) {
        reply.code(400);
        return { success: false, error: 'Route and newWeather are required' };
      }

      const adaptedRoute = await aiService.adaptRouteForWeather(route, newWeather);
      return { success: true, data: adaptedRoute };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // POST /ai/translate - Translate text
  fastify.post('/translate', async (request, reply) => {
    try {
      const { text, targetLang, context } = request.body;

      if (!text || !targetLang) {
        reply.code(400);
        return { success: false, error: 'Text and targetLang are required' };
      }

      const translation = await aiService.translate(text, targetLang, context);
      return { success: true, data: { translation, source: text, target: targetLang } };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // POST /ai/transcribe - Transcribe audio with Whisper
  fastify.post('/transcribe', async (request, reply) => {
    try {
      const { audio, language } = request.body;

      if (!audio) {
        reply.code(400);
        return { success: false, error: 'Audio data is required' };
      }

      // Decode base64 audio
      const audioBuffer = Buffer.from(audio, 'base64');
      const tempFile = path.join('/tmp', `audio_${Date.now()}.webm`);
      fs.writeFileSync(tempFile, audioBuffer);

      // Use local Whisper or OpenAI API
      const transcription = await aiService.transcribeAudio(tempFile, language);

      // Clean up temp file
      fs.unlinkSync(tempFile);

      return { 
        success: true, 
        data: { 
          text: transcription,
          language: language || 'auto'
        } 
      };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });
}

module.exports = routes;
