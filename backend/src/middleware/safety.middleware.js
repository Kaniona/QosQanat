import { BANNED_KEYWORDS } from '../config/constants.js';
import { logger } from '../utils/logger.js';

// Content moderation only. Length/empty/type are already enforced by the Joi
// schema (validateRequest) earlier in the middleware chain.
export const validateStudentMessage = (req, res, next) => {
  const message = req.body.message || req.body.text || '';

  const lowerMessage = message.toLowerCase();
  const foundBanned = BANNED_KEYWORDS.find(keyword =>
    lowerMessage.includes(keyword)
  );

  if (foundBanned) {
    logger.warn(`Қауіпсіздік: тыйым салынған сөз анықталды — "${foundBanned}"`);
    return res.status(403).json({
      error: 'Бұл тақырыпта көмектесе алмаймын. Сабаққа қатысты сұрақ қойшы!'
    });
  }

  next();
};

export const filterAIResponse = (response) => {
  // Safety filter for AI responses
  if (!response || typeof response !== 'string') {
    logger.warn('⚠️ Invalid response type for filtering');
    return 'Кешіріңіз, түсінбедім. Қайталап көріңізші.';
  }

  let filtered = response.trim();

  if (filtered.length === 0) {
    logger.warn('⚠️ Empty response after trim');
    return 'Кешіріңіз, түсінбедім. Қайталап көріңізші.';
  }

  // Remove URLs (could contain inappropriate content)
  const originalLength = filtered.length;
  filtered = filtered.replace(/https?:\/\/\S+/gi, '[сілтеме]');

  // Remove email addresses (privacy)
  filtered = filtered.replace(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/gi, '[email]');

  // Remove phone numbers
  filtered = filtered.replace(/(\+?\d{1,3}[-.\s]?)?\d{3,4}[-.\s]?\d{3,4}[-.\s]?\d{4,}/g, '[телефон]');

  // Check for banned keywords
  const lowerResponse = filtered.toLowerCase();
  const foundBanned = BANNED_KEYWORDS.find(keyword =>
    lowerResponse.includes(keyword.toLowerCase())
  );

  if (foundBanned) {
    logger.warn(`🚨 Banned content detected in AI response: "${foundBanned}"`);
    return 'Бұл сұраққа жауап бере алмаймын. Сабаққа қатысты басқа сұрақ қойшы!';
  }

  // Check for excessive repetition (spam/injection detection)
  const words = filtered.split(/\s+/);
  if (words.length > 0) {
    const uniqueWords = new Set(words);
    const repetitionRatio = 1 - (uniqueWords.size / words.length);
    if (repetitionRatio > 0.7) { // >70% repeated words = likely spam
      logger.warn('🚨 Excessive repetition detected in response');
      return 'Жауап қате шықты. Қайталап сұраңызшы.';
    }
  }

  // Limit response length for safety
  const maxLength = 5000;
  if (filtered.length > maxLength) {
    logger.warn(`⚠️ Response truncated from ${filtered.length} to ${maxLength}`);
    filtered = filtered.substring(0, maxLength) + '...';
  }

  logger.debug(`✅ Response filtered: ${originalLength} → ${filtered.length} chars`);
  return filtered;
};

export const validateGrade = (grade) => {
  const gradeNum = parseInt(grade);
  return gradeNum >= 5 && gradeNum <= 11;
};

export const validateAssistantType = (type) => {
  return ['bektur', 'nazym'].includes(type?.toLowerCase());
};
