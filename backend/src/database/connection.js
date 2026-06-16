import pkg from 'pg';
import { logger } from '../utils/logger.js';
import { env } from '../config/env.js';

const { Pool } = pkg;

let pool = null;

export const initDatabase = async () => {
  try {
    if (!env.databaseUrl) {
      logger.warn('Database URL not configured. Using in-memory storage.');
      return null;
    }

    pool = new Pool({
      connectionString: env.databaseUrl,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
    });

    pool.on('error', (err) => {
      logger.error('Unexpected error on idle client', err);
    });

    // Test connection
    const client = await pool.connect();
    await client.query('SELECT NOW()');
    client.release();

    logger.info('✅ Database connected successfully');
    return pool;
  } catch (error) {
    // The database is optional (conversation state lives in Redis / memory),
    // so a connection failure degrades gracefully instead of crashing.
    logger.error('❌ Database connection failed, continuing without DB:', error.message);
    pool = null;
    return null;
  }
};

export const query = async (text, params = []) => {
  try {
    if (!pool) {
      throw new Error('Database pool not initialized');
    }

    const startTime = Date.now();
    const result = await pool.query(text, params);
    const duration = Date.now() - startTime;

    logger.debug(`DB Query: ${duration}ms`, { query: text.substring(0, 100) });
    return result;
  } catch (error) {
    logger.error('Database query error:', error.message);
    throw error;
  }
};

export const transaction = async (callback) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('Transaction error:', error.message);
    throw error;
  } finally {
    client.release();
  }
};

export const closeDatabase = async () => {
  if (pool) {
    await pool.end();
    logger.info('Database pool closed');
  }
};

export default {
  initDatabase,
  query,
  transaction,
  closeDatabase
};
