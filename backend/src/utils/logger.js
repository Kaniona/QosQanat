import { env } from '../config/env.js';

const LOG_LEVELS = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3
};

const currentLevel = LOG_LEVELS[env.logLevel] || LOG_LEVELS.info;

const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  green: '\x1b[32m',
  blue: '\x1b[34m'
};

const getTimestamp = () => new Date().toISOString();

export const logger = {
  error: (message, error = null) => {
    if (LOG_LEVELS.error <= currentLevel) {
      console.error(`${colors.red}[ERROR] ${getTimestamp()}${colors.reset}`, message);
      if (error) console.error(error);
    }
  },

  warn: (message) => {
    if (LOG_LEVELS.warn <= currentLevel) {
      console.warn(`${colors.yellow}[WARN] ${getTimestamp()}${colors.reset}`, message);
    }
  },

  info: (message) => {
    if (LOG_LEVELS.info <= currentLevel) {
      console.log(`${colors.green}[INFO] ${getTimestamp()}${colors.reset}`, message);
    }
  },

  debug: (message, data = null) => {
    if (LOG_LEVELS.debug <= currentLevel) {
      console.log(`${colors.blue}[DEBUG] ${getTimestamp()}${colors.reset}`, message);
      if (data) console.log(data);
    }
  }
};
