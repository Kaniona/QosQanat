import Joi from 'joi';
import { logger } from './logger.js';

// Message schemas
export const chatMessageSchema = Joi.object({
  student_id: Joi.string().max(100).default('anonymous'),
  grade: Joi.number().integer().min(5).max(11).default(8),
  subject: Joi.string().max(100).default('Қазақ тілі'),
  topic: Joi.string().max(200).default('Сабақ'),
  message: Joi.string().required().min(1).max(2000).trim(),
  assistant_type: Joi.string().valid('bektur', 'nazym').default('bektur')
}).unknown(true);

export const voiceChatSchema = Joi.object({
  student_id: Joi.string().max(100).default('anonymous'),
  grade: Joi.number().integer().min(5).max(11).default(8),
  subject: Joi.string().max(100).default('Қазақ тілі'),
  topic: Joi.string().max(200).default('Сабақ'),
  assistant_type: Joi.string().valid('bektur', 'nazym').default('bektur')
}).unknown(true);

export const tutorExplainSchema = Joi.object({
  topic: Joi.string().required().min(1).max(200),
  grade: Joi.number().integer().min(5).max(11).default(8),
  assistant_type: Joi.string().valid('bektur', 'nazym').default('bektur')
}).unknown(true);

export const tutorHintSchema = Joi.object({
  question: Joi.string().required().min(1).max(500),
  student_answer: Joi.string().required().min(1).max(500),
  grade: Joi.number().integer().min(5).max(11).default(8),
  assistant_type: Joi.string().valid('bektur', 'nazym').default('bektur')
}).unknown(true);

export const tutorCheckSchema = Joi.object({
  question: Joi.string().required().min(1).max(500),
  correct_answer: Joi.string().required().min(1).max(500),
  student_answer: Joi.string().required().min(1).max(500),
  grade: Joi.number().integer().min(5).max(11).default(8)
}).unknown(true);

// Прогресс синхрондау сұлбасы (бұлтқа сақтау).
export const progressSyncSchema = Joi.object({
  student_id: Joi.string().required().min(1).max(100),
  name: Joi.string().allow('').max(80),
  grade: Joi.number().integer().min(1).max(11).default(5),
  school: Joi.string().allow('').max(120),
  city: Joi.string().allow('').max(80),
  skills: Joi.array().items(Joi.object().unknown(true)).max(500).default([]),
  nodes: Joi.array().items(Joi.object().unknown(true)).max(3000).default([]),
  streak: Joi.number().integer().min(0).default(0),
  longest_streak: Joi.number().integer().min(0).default(0),
  akyl: Joi.number().integer().min(0).default(0),
  level: Joi.number().integer().min(1).default(1)
}).unknown(true);

// Validation middleware factory
export const validateRequest = (schema) => {
  return (req, res, next) => {
    try {
      const { error, value } = schema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true
      });

      if (error) {
        const details = error.details.map(d => ({
          field: d.path.join('.'),
          message: d.message,
          type: d.type
        }));

        logger.warn('Validation error:', details);

        return res.status(400).json({
          error: 'Жарамсыз сұрау',
          code: 'VALIDATION_ERROR',
          details,
          timestamp: new Date().toISOString()
        });
      }

      // Replace body with validated values
      req.body = value;
      next();
    } catch (error) {
      logger.error('Validation middleware error:', error);
      res.status(500).json({
        error: 'Валидация қатесі',
        code: 'VALIDATION_MIDDLEWARE_ERROR'
      });
    }
  };
};

// Custom validation functions
export const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const isValidPhone = (phone) => {
  const phoneRegex = /^[\d\s+()-]{10,}$/;
  return phoneRegex.test(phone);
};

export const isValidGrade = (grade) => {
  const gradeNum = parseInt(grade);
  return gradeNum >= 5 && gradeNum <= 11;
};

export const isValidAssistantType = (type) => {
  return ['bektur', 'nazym'].includes(String(type).toLowerCase());
};

export const isSafeText = (text) => {
  if (!text || typeof text !== 'string') return false;
  if (text.length === 0 || text.length > 5000) return false;

  // Check for malicious patterns
  const maliciousPatterns = [
    /<script/gi,
    /javascript:/gi,
    /on\w+\s*=/gi,
    /<iframe/gi,
    /<object/gi
  ];

  return !maliciousPatterns.some(pattern => pattern.test(text));
};

export default {
  chatMessageSchema,
  voiceChatSchema,
  tutorExplainSchema,
  tutorHintSchema,
  tutorCheckSchema,
  validateRequest,
  isValidEmail,
  isValidPhone,
  isValidGrade,
  isValidAssistantType,
  isSafeText
};
