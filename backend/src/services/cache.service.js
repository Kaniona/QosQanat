import redis from 'redis';
import { createHash } from 'crypto';
import { logger } from '../utils/logger.js';
import { env } from '../config/env.js';

let redisClient = null;
let isConnected = false;

export const initCache = async () => {
  try {
    if (!env.redisUrl) {
      logger.warn('Redis URL not configured. Cache disabled.');
      return null;
    }

    redisClient = redis.createClient({
      url: env.redisUrl,
      socket: {
        reconnectStrategy: (retries) => {
          if (retries > 10) {
            logger.error('Max Redis reconnection attempts exceeded');
            return new Error('Redis max retries exceeded');
          }
          return Math.min(retries * 50, 500);
        }
      }
    });

    redisClient.on('error', (err) => {
      logger.error('Redis error:', err);
      isConnected = false;
    });

    redisClient.on('connect', () => {
      logger.info('✅ Redis connected');
      isConnected = true;
    });

    await redisClient.connect();
    return redisClient;
  } catch (error) {
    logger.warn('Redis initialization failed:', error.message);
    return null;
  }
};

export const get = async (key) => {
  if (!redisClient || !isConnected) return null;

  try {
    const value = await redisClient.get(key);
    if (value) {
      logger.debug(`Cache HIT: ${key}`);
      return JSON.parse(value);
    }
    logger.debug(`Cache MISS: ${key}`);
    return null;
  } catch (error) {
    logger.warn(`Cache get error for ${key}:`, error.message);
    return null;
  }
};

export const set = async (key, value, ttl = 3600) => {
  if (!redisClient || !isConnected) return false;

  try {
    await redisClient.setEx(key, ttl, JSON.stringify(value));
    logger.debug(`Cache SET: ${key} (TTL: ${ttl}s)`);
    return true;
  } catch (error) {
    logger.warn(`Cache set error for ${key}:`, error.message);
    return false;
  }
};

export const delete_ = async (key) => {
  if (!redisClient || !isConnected) return false;

  try {
    await redisClient.del(key);
    logger.debug(`Cache DEL: ${key}`);
    return true;
  } catch (error) {
    logger.warn(`Cache delete error for ${key}:`, error.message);
    return false;
  }
};

export const clear = async (pattern = '*') => {
  if (!redisClient || !isConnected) return false;

  try {
    const keys = await redisClient.keys(pattern);
    if (keys.length > 0) {
      await redisClient.del(keys);
      logger.info(`Cache cleared: ${keys.length} keys`);
    }
    return true;
  } catch (error) {
    logger.warn('Cache clear error:', error.message);
    return false;
  }
};

export const closeCache = async () => {
  if (redisClient && isConnected) {
    await redisClient.quit();
    logger.info('Redis connection closed');
    isConnected = false;
  }
};

// Hash variable-length user input so it is safe to use inside a Redis key.
const hash = (value) => createHash('sha256').update(String(value)).digest('hex').slice(0, 32);

// Cache key builders
export const cacheKeys = {
  aiResponse: (studentId, message) => `ai:${studentId}:${hash(message)}`,
  studentHistory: (studentId) => `history:${studentId}`,
  studentProfile: (studentId) => `student:${studentId}`,
  explanation: (topic, grade) => `explain:${hash(topic)}:${grade}`,
  hint: (question, grade) => `hint:${hash(question)}:${grade}`,
  health: 'health:status'
};

export default {
  initCache,
  get,
  set,
  delete: delete_,
  clear,
  closeCache,
  cacheKeys
};
