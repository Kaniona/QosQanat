import express from 'express';
import ProgressController from '../controllers/progress.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { asyncHandler } from '../middleware/errorHandler.middleware.js';
import { validateRequest, progressSyncSchema } from '../utils/validation.js';

const router = express.Router();

// POST /api/progress/sync — құрылғыдан прогресті жүктеу
router.post(
  '/sync',
  authMiddleware,
  validateRequest(progressSyncSchema),
  asyncHandler(ProgressController.sync)
);

// GET /api/progress/:studentId — бұлттан қайтару (құрылғы ауысқанда)
router.get('/:studentId', authMiddleware, asyncHandler(ProgressController.get));

// DELETE /api/progress/:studentId — өшіру (құпиялық)
router.delete(
  '/:studentId',
  authMiddleware,
  asyncHandler(ProgressController.erase)
);

export default router;
