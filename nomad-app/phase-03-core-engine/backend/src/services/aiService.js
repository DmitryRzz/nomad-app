const OpenAI = require('openai');
const config = require('../config');

const openai = new OpenAI({
  apiKey: config.openai.apiKey,
});

class AIService {
  /**
   * Generate a route using GPT-4
   * @param {Object} params - Route generation parameters
   * @param {string} params.city - Target city
   * @param {string} params.country - Country (optional)
   * @param {Array<string>} params.interests - User interests
   * @param {number} params.budgetLevel - 1-5
   * @param {string} params.pace - relaxed, balanced, intense
   * @param {Object} params.weather - Current weather data
   * @param {number} params.numStops - Number of stops (default 5)
   * @returns {Promise<Object>} Generated route
   */
  async generateRoute(params) {
    const {
      city,
      country,
      interests = [],
      budgetLevel = 3,
      pace = 'balanced',
      weather = null,
      numStops = 5,
    } = params;

    const systemPrompt = `You are NOMAD, an expert travel planner AI. Generate a daily route for a city.

Rules:
- Generate ${numStops} stops for a full day
- Consider weather conditions and prefer indoor activities during rain/snow/extreme heat
- Balance walking distances (prefer < 2km between consecutive stops, or suggest transport)
- Include meal breaks at appropriate times
- Mix popular attractions with hidden gems
- Respect typical opening hours
- Consider user's budget level (1=very cheap, 5=luxury) and pace

Output format: JSON with this exact structure:
{
  "title": "Route title",
  "logic": "Brief explanation of the route logic",
  "stops": [
    {
      "name": "Location name",
      "category": "museum|restaurant|park|landmark|cafe|shop|other",
      "description": "Brief description",
      "duration_minutes": 60,
      "time": "09:00",
      "reason": "Why this stop is included",
      "indoor": true|false,
      "price_level": 1-5,
      "latitude": 0.0,
      "longitude": 0.0,
      "address": "Approximate address",
      "must_see": true|false
    }
  ],
  "transport": [
    {
      "from": 0,
      "to": 1,
      "mode": "walk|metro|bus|taxi",
      "duration_minutes": 15,
      "distance_km": 1.2
    }
  ]
}`;

    const userPrompt = `Generate a route for ${city}${country ? ', ' + country : ''}.

User preferences:
- Interests: ${interests.join(', ') || 'general sightseeing'}
- Budget level: ${budgetLevel}/5
- Pace: ${pace}
${weather ? `- Weather: ${weather.condition}, ${weather.temperature}°C` : ''}

Requirements:
- Start around 9:00 AM
- End around 7:00 PM
- Include lunch break
- Mix indoor and outdoor (based on weather)
- Walking-friendly or suggest transport between stops`;

    try {
      const completion = await openai.chat.completions.create({
        model: config.openai.model,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: 2000,
      });

      const content = completion.choices[0].message.content;
      
      // Extract JSON from response
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error('No valid JSON in AI response');
      }

      const route = JSON.parse(jsonMatch[0]);
      
      // Validate structure
      if (!route.stops || !Array.isArray(route.stops) || route.stops.length === 0) {
        throw new Error('Invalid route structure: missing stops');
      }

      return route;
    } catch (error) {
      console.error('AI route generation failed:', error);
      throw error;
    }
  }

  /**
   * Adapt route based on weather changes
   * @param {Object} route - Current route
   * @param {Object} newWeather - New weather conditions
   * @returns {Promise<Object>} Adapted route
   */
  async adaptRouteForWeather(route, newWeather) {
    const systemPrompt = `You are NOMAD, an expert travel planner. Adapt an existing route due to weather changes.

Rules:
- Replace outdoor stops with indoor alternatives when it rains/snows
- Keep the route logical (no jumping across the city)
- Maintain meal times
- Preserve must-see attractions if possible (find indoor alternatives nearby)

Output format: Same JSON structure as input route, with adapted stops.`;

    const userPrompt = `Current route: ${JSON.stringify(route, null, 2)}

New weather: ${JSON.stringify(newWeather)}

Please adapt this route for the new weather conditions.`;

    try {
      const completion = await openai.chat.completions.create({
        model: config.openai.model,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.5,
        max_tokens: 2000,
      });

      const content = completion.choices[0].message.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
      
      return route; // Fallback to original
    } catch (error) {
      console.error('Weather adaptation failed:', error);
      return route; // Fallback to original
    }
  }

  /**
   * Translate text with context
   * @param {string} text - Text to translate
   * @param {string} targetLang - Target language code
   * @param {string} context - Context (restaurant, taxi, etc.)
   * @returns {Promise<string>} Translated text
   */
  async translate(text, targetLang, context = '') {
    const systemPrompt = `You are a professional translator. Translate the given text accurately and naturally.
${context ? `Context: ${context}` : ''}

Rules:
- Preserve meaning and tone
- Use natural, conversational language
- Keep it concise for spoken dialogue
- If it's a menu item, include a brief description

Output only the translation, no explanations.`;

    try {
      const completion = await openai.chat.completions.create({
        model: config.openai.model,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: `Translate to ${targetLang}: "${text}"` },
        ],
        temperature: 0.3,
        max_tokens: 500,
      });

      return completion.choices[0].message.content.trim();
    } catch (error) {
      console.error('Translation failed:', error);
      throw error;
    }
  }
}

  /**
   * Transcribe audio using Whisper
   * @param {string} audioFilePath - Path to audio file
   * @param {string} language - Language code (optional)
   * @returns {Promise<string>} Transcribed text
   */
  async transcribeAudio(audioFilePath, language = null) {
    try {
      // Use OpenAI Whisper API
      const fs = require('fs');
      const OpenAI = require('openai');
      const openai = new OpenAI({ apiKey: config.openai.apiKey });

      const transcription = await openai.audio.transcriptions.create({
        file: fs.createReadStream(audioFilePath),
        model: 'whisper-1',
        language: language || undefined,
      });

      return transcription.text;
    } catch (error) {
      console.error('Transcription failed:', error);
      throw error;
    }
  }

module.exports = new AIService();
