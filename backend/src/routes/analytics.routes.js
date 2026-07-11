import express from 'express';
import AnalyticsController from '../controllers/analytics.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { asyncHandler } from '../middleware/errorHandler.middleware.js';

const router = express.Router();

// GET /api/analytics/student/:studentId — бір оқушының аналитикасы
router.get(
  '/student/:studentId',
  authMiddleware,
  asyncHandler(AnalyticsController.student)
);

// GET /api/analytics/class/:school — сынып/мектеп агрегаты (мұғалім)
router.get(
  '/class/:school',
  authMiddleware,
  asyncHandler(AnalyticsController.classFor)
);

export default router;
