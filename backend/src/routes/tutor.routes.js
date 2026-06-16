import express from 'express';
import TutorController from '../controllers/tutor.controller.js';
import { tutorLimiter } from '../middleware/rateLimit.middleware.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { asyncHandler } from '../middleware/errorHandler.middleware.js';
import {
  validateRequest,
  tutorExplainSchema,
  tutorHintSchema,
  tutorCheckSchema
} from '../utils/validation.js';

const router = express.Router();

// POST /api/tutor/explain - Explain a concept
router.post('/explain',
  tutorLimiter,
  authMiddleware,
  validateRequest(tutorExplainSchema),
  asyncHandler(TutorController.explainConcept)
);

// POST /api/tutor/hint - Give a hint
router.post('/hint',
  tutorLimiter,
  authMiddleware,
  validateRequest(tutorHintSchema),
  asyncHandler(TutorController.giveHint)
);

// POST /api/tutor/check - Check an answer
router.post('/check',
  tutorLimiter,
  authMiddleware,
  validateRequest(tutorCheckSchema),
  asyncHandler(TutorController.checkAnswer)
);

export default router;
