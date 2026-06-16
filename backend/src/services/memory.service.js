import { logger } from '../utils/logger.js';
import { get, set, delete_ } from './cache.service.js';
import { CONTEXT_CONFIG } from '../config/constants.js';

// Conversation history is stored in Redis so that it is shared across PM2
// cluster workers and survives restarts. When Redis is unavailable we fall
// back to an in-process Map (single-worker / local dev only).
const fallbackMemory = new Map();

const MAX_HISTORY = 20;
const HISTORY_TTL_SECONDS = 60 * 60 * 24; // 24 hours

const keyFor = (studentId) => `conv:${studentId}`;

export class MemoryService {
  static async _readHistory(studentId) {
    const cached = await get(keyFor(studentId));
    if (cached) return cached;
    return fallbackMemory.get(studentId) || null;
  }

  static async storeConversation(studentId, message, response, grade, subject, topic) {
    try {
      const history = (await this._readHistory(studentId)) || [];

      history.push({
        timestamp: new Date().toISOString(),
        message,
        response,
        grade,
        subject,
        topic
      });

      // Keep only the most recent entries
      const trimmed = history.slice(-MAX_HISTORY);

      const persisted = await set(keyFor(studentId), trimmed, HISTORY_TTL_SECONDS);
      if (!persisted) {
        // Redis disabled/unavailable — keep in process memory
        fallbackMemory.set(studentId, trimmed);
      }

      logger.debug(`Сұхбат сақталды: ${studentId} (${trimmed.length} жазба)`);
      return trimmed;
    } catch (error) {
      logger.error('Сұхбат сақтау қатесі:', error);
      throw error;
    }
  }

  static async getConversationHistory(studentId) {
    try {
      const history = await this._readHistory(studentId);
      if (!history || history.length === 0) {
        return [];
      }

      // Convert to the role/content format expected by the AI context,
      // limited to the most recent turns.
      const recent = history.slice(-CONTEXT_CONFIG.MAX_HISTORY);
      return recent.flatMap((entry) => [
        { role: 'user', content: entry.message },
        { role: 'assistant', content: entry.response }
      ]);
    } catch (error) {
      logger.error('Сұхбат оқу қатесі:', error);
      return [];
    }
  }

  static async getConversationInfo(studentId) {
    const history = await this._readHistory(studentId);
    if (!history) return null;
    return { studentId, entries: history.length, history };
  }

  static async clearConversation(studentId) {
    await delete_(keyFor(studentId));
    fallbackMemory.delete(studentId);
    logger.info(`Сұхбат тазартылды: ${studentId}`);
  }
}

export default MemoryService;
