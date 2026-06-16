import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { logger } from '../utils/logger.js';

export const authMiddleware = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      // Optional: make it required by returning 401
      // For now, allow anonymous access but warn
      logger.warn('Токен болмады');
      req.student = { id: 'anonymous', grade: 8 };
      return next();
    }

    const decoded = jwt.verify(token, env.jwtSecret);
    req.student = decoded;
    next();
  } catch (error) {
    logger.error('Аутентификация қатесі:', error);
    return res.status(401).json({ error: 'Аутентификация сәтсіз болды' });
  }
};

export const generateToken = (studentId, grade) => {
  return jwt.sign(
    { id: studentId, grade },
    env.jwtSecret,
    { expiresIn: '7d' }
  );
};
