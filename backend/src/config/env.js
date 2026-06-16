import dotenv from 'dotenv';

dotenv.config();

export const env = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',

  // AI APIs
  anthropicApiKey: process.env.ANTHROPIC_API_KEY,
  openaiApiKey: process.env.OPENAI_API_KEY,

  // Azure Speech
  azureSpeechKey: process.env.AZURE_SPEECH_KEY,
  azureSpeechRegion: process.env.AZURE_SPEECH_REGION || 'eastus',

  // Database
  databaseUrl: process.env.DATABASE_URL,

  // Security — no insecure fallback; JWT_SECRET is a required, length-checked
  // variable validated at startup (config/validation.js).
  jwtSecret: process.env.JWT_SECRET,

  // Redis (optional)
  redisUrl: process.env.REDIS_URL,

  // CORS
  corsOrigin: process.env.CORS_ORIGIN || '*',

  // Logging
  logLevel: process.env.LOG_LEVEL || 'info'
};

// NOTE: required environment variables are validated authoritatively at
// startup in config/validation.js (validateEnvironment). Avoid duplicating
// that check here so there is a single source of truth.
