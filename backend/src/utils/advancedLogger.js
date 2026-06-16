import winston from 'winston';
import fs from 'fs';
import path from 'path';

const logsDir = 'logs';

// Create logs directory if it doesn't exist
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir);
}

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.json(),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    const metaString = Object.keys(meta).length ? JSON.stringify(meta) : '';
    return `${timestamp} [${level.toUpperCase()}] ${message} ${metaString}`;
  })
);

// Console format (prettier)
const consoleFormat = winston.format.combine(
  winston.format.timestamp({ format: 'HH:mm:ss' }),
  winston.format.colorize(),
  winston.format.printf(({ timestamp, level, message }) => {
    return `${timestamp} ${level}: ${message}`;
  })
);

// Create transports
const transports = [
  // Console
  new winston.transports.Console({
    format: consoleFormat,
    level: process.env.LOG_LEVEL || 'info'
  }),

  // All logs
  new winston.transports.File({
    filename: path.join(logsDir, 'all.log'),
    format: logFormat,
    maxsize: 10 * 1024 * 1024, // 10MB
    maxFiles: 10
  }),

  // Error logs only
  new winston.transports.File({
    filename: path.join(logsDir, 'error.log'),
    format: logFormat,
    level: 'error',
    maxsize: 10 * 1024 * 1024,
    maxFiles: 10
  }),

  // API requests
  new winston.transports.File({
    filename: path.join(logsDir, 'api.log'),
    format: logFormat,
    maxsize: 10 * 1024 * 1024,
    maxFiles: 5
  })
];

// Create logger
export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  transports,
  exceptionHandlers: [
    new winston.transports.File({ filename: path.join(logsDir, 'exceptions.log') })
  ],
  rejectionHandlers: [
    new winston.transports.File({ filename: path.join(logsDir, 'rejections.log') })
  ]
});

// Add methods for structured logging
export const logRequest = (method, path, statusCode, duration, metadata = {}) => {
  const statusEmoji = statusCode < 400 ? '✅' : statusCode < 500 ? '⚠️' : '❌';
  logger.info(`${statusEmoji} ${method} ${path} ${statusCode} (+${duration}ms)`, metadata);
};

export const logError = (error, context = {}) => {
  logger.error(`Error: ${error.message}`, {
    code: error.code,
    statusCode: error.statusCode,
    stack: error.stack,
    ...context
  });
};

export const logWarning = (message, metadata = {}) => {
  logger.warn(message, metadata);
};

export const logInfo = (message, metadata = {}) => {
  logger.info(message, metadata);
};

export const logDebug = (message, metadata = {}) => {
  logger.debug(message, metadata);
};

export const logAICall = (service, model, tokenUsage, duration) => {
  logger.info(`AI Call: ${service}/${model}`, {
    tokens: tokenUsage,
    duration: `${duration}ms`
  });
};

export const logDatabaseOperation = (operation, table, duration, success = true) => {
  const status = success ? '✅' : '❌';
  logger.info(`${status} DB: ${operation} on ${table} (+${duration}ms)`);
};

export default logger;
