import { logger } from '../utils/logger.js';

const requiredEnvVars = [
  'ANTHROPIC_API_KEY',
  'OPENAI_API_KEY',
  'AZURE_SPEECH_KEY',
  'AZURE_SPEECH_REGION',
  'JWT_SECRET'
];

const optionalEnvVars = [
  'DATABASE_URL',
  'REDIS_URL',
  'CORS_ORIGIN',
  'LOG_LEVEL',
  'PORT',
  'NODE_ENV'
];

export const validateEnvironment = () => {
  console.log('🔍 Validating environment...');

  const missing = [];
  const configured = [];

  // Check required
  for (const envVar of requiredEnvVars) {
    if (!process.env[envVar]) {
      missing.push(envVar);
      logger.warn(`❌ Missing required env var: ${envVar}`);
    } else {
      configured.push(envVar);
      logger.info(`✅ ${envVar} configured`);
    }
  }

  // Check optional
  for (const envVar of optionalEnvVars) {
    if (process.env[envVar]) {
      logger.info(`✅ ${envVar} configured`);
    }
  }

  if (missing.length > 0) {
    logger.error(`\n❌ Missing ${missing.length} required environment variables:`);
    missing.forEach(v => logger.error(`   - ${v}`));
    logger.error('\nPlease set these variables and restart the server.');
    process.exit(1);
  }

  console.log(`\n✅ Environment validation passed`);
  console.log(`   Configured: ${configured.length} required + ${
    optionalEnvVars.filter(v => process.env[v]).length
  } optional variables\n`);

  return true;
};

// Validate config values
export const validateConfig = () => {
  const errors = [];

  // Validate JWT secret length
  if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
    errors.push('JWT_SECRET must be at least 32 characters long');
  }

  // Validate port
  const port = parseInt(process.env.PORT || 3000);
  if (isNaN(port) || port < 1 || port > 65535) {
    errors.push('PORT must be a number between 1 and 65535');
  }

  // Validate grade range
  const validGrades = [5, 6, 7, 8, 9, 10, 11];
  // This would be checked at runtime for student grades

  if (errors.length > 0) {
    logger.error('Configuration validation errors:');
    errors.forEach(err => logger.error(`  - ${err}`));
    return false;
  }

  return true;
};

export const getEnvSummary = () => {
  return {
    node_env: process.env.NODE_ENV || 'development',
    port: process.env.PORT || 3000,
    log_level: process.env.LOG_LEVEL || 'info',
    has_database: !!process.env.DATABASE_URL,
    has_redis: !!process.env.REDIS_URL,
    has_anthropic: !!process.env.ANTHROPIC_API_KEY,
    has_openai: !!process.env.OPENAI_API_KEY,
    has_azure_speech: !!process.env.AZURE_SPEECH_KEY,
    uptime_seconds: Math.floor(process.uptime()),
    memory_usage_mb: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
    node_version: process.version
  };
};

export default {
  validateEnvironment,
  validateConfig,
  getEnvSummary
};
