import express from 'express';
import {
  getHealthStatus,
  getDeepHealth,
  getMetrics
} from '../controllers/health.controller.js';
import { asyncHandler } from '../middleware/errorHandler.middleware.js';

const router = express.Router();

// GET /api/health - Basic health check
router.get('/', asyncHandler(getHealthStatus));

// GET /api/health/deep - Deep health diagnostics
router.get('/deep', asyncHandler(getDeepHealth));

// GET /api/health/metrics - Performance metrics
router.get('/metrics', asyncHandler(getMetrics));

export default router;
