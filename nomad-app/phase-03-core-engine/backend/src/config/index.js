const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

module.exports = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    name: process.env.DB_NAME || 'nomad',
    user: process.env.DB_USER || 'nomad_user',
    password: process.env.DB_PASSWORD || '',
  },
  
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379,
  },
  
  openai: {
    apiKey: process.env.OPENAI_API_KEY,
    model: process.env.OPENAI_MODEL || 'gpt-4',
  },
  
  mapbox: {
    accessToken: process.env.MAPBOX_ACCESS_TOKEN,
  },
  
  jwt: {
    secret: process.env.JWT_SECRET || 'nomad_default_secret_change_in_production',
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
  },
  
  weather: {
    apiKey: process.env.WEATHER_API_KEY,
  },
};
