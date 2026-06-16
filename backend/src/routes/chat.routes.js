import express from 'express';
import ChatController from '../controllers/chat.controller.js';
import { chatLimiter } from '../middleware/rateLimit.middleware.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { validateStudentMessage } from '../middleware/safety.middleware.js';
import { validateRequest } from '../utils/validation.js';
import { asyncHandler } from '../middleware/errorHandler.middleware.js';
import { chatMessageSchema } from '../utils/validation.js';

const router = express.Router();

// POST /api/chat - Send text message
router.post('/',
  chatLimiter,
  authMiddleware,
  validateRequest(chatMessageSchema),
  validateStudentMessage,
  asyncHandler(ChatController.sendMessage)
);

export default router;
