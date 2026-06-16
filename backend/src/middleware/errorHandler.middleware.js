import { logger } from '../utils/logger.js';

export const errorHandler = (err, req, res, next) => {
  logger.error('Сервер қатесі:', err);

  const status = err.status || 500;
  const message = err.message || 'Ішкі сервер қатесі';

  // Handle specific errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ error: 'Файл тым ұлғайды' });
  }

  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return res.status(400).json({ error: 'Файл типі дұрыс емес' });
  }

  if (err.name === 'ValidationError') {
    return res.status(400).json({ error: 'Деректер дұрыс емес' });
  }

  res.status(status).json({
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

export const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};
