import rateLimit from 'express-rate-limit';
import { RATE_LIMITS } from '../config/constants.js';

export const chatLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: RATE_LIMITS.CHAT_PER_MINUTE,
  message: { error: 'Сұрауларыңызды көп жібердіңіз. Бірнеше сәттік күтіңіз.' },
  standardHeaders: true,
  legacyHeaders: false,
});

export const voiceLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: RATE_LIMITS.VOICE_PER_MINUTE,
  message: { error: 'Дауыс сұрауларыңыз қолақ болып кетті. Бірнеше сәттік күтіңіз.' },
  standardHeaders: true,
  legacyHeaders: false,
});

export const tutorLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: RATE_LIMITS.TUTOR_PER_MINUTE,
  message: { error: 'Түсіндіру сұрауларыңыз көп. Бірнеше сәттік күтіңіз.' },
  standardHeaders: true,
  legacyHeaders: false,
});
