import express from 'express';
import ContentController from '../controllers/content.controller.js';
import { asyncHandler } from '../middleware/errorHandler.middleware.js';

const router = express.Router();

// Контент API ашық (құпия дерек жоқ) — қосымша жаңартуды тексереді.
// GET /api/content/manifest — нұсқа + құрылым
router.get('/manifest', asyncHandler(ContentController.manifest));

// GET /api/content/curriculum — толық таксономия
router.get('/curriculum', asyncHandler(ContentController.curriculum));

// GET /api/content/subject/:id — бір пән
router.get('/subject/:id', asyncHandler(ContentController.subject));

export default router;
