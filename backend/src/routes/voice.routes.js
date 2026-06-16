import express from 'express';
import multer from 'multer';
import VoiceController from '../controllers/voice.controller.js';
import { voiceLimiter } from '../middleware/rateLimit.middleware.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { asyncHandler } from '../middleware/errorHandler.middleware.js';

const router = express.Router();

// Configure multer for audio uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Аудио форматы қолдау жоқ'));
    }
  }
});

// POST /api/voice/chat - Full voice cycle
router.post('/chat',
  upload.single('audio'),
  voiceLimiter,
  authMiddleware,
  asyncHandler(VoiceController.voiceChat)
);

// POST /api/voice/stt - Speech to text only
router.post('/stt',
  upload.single('audio'),
  voiceLimiter,
  authMiddleware,
  asyncHandler(VoiceController.transcribeAudio)
);

// POST /api/voice/tts - Text to speech only
router.post('/tts',
  voiceLimiter,
  authMiddleware,
  asyncHandler(VoiceController.synthesizeAudio)
);

export default router;
