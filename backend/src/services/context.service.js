import { CONTEXT_CONFIG } from '../config/constants.js';
import { logger } from '../utils/logger.js';

export class ContextService {
  static buildContext(studentId, grade, subject, topic, message, assistantType, conversationHistory = []) {
    return {
      studentId,
      grade: parseInt(grade),
      subject,
      topic,
      message,
      assistantType: assistantType || 'bektur',
      conversationHistory: this._limitHistory(conversationHistory)
    };
  }

  static _limitHistory(history) {
    if (!Array.isArray(history)) {
      return [];
    }
    return history.slice(-CONTEXT_CONFIG.MAX_HISTORY);
  }

  static addMessageToHistory(history, role, content) {
    const newHistory = Array.isArray(history) ? [...history] : [];
    newHistory.push({
      role: role || 'user',
      content: content || ''
    });
    return this._limitHistory(newHistory);
  }

  static formatConversationHistory(history) {
    if (!Array.isArray(history) || history.length === 0) {
      return [];
    }

    return history.map(entry => ({
      role: entry.role || 'user',
      content: typeof entry === 'string' ? entry : entry.content || ''
    }));
  }
}

export default ContextService;
