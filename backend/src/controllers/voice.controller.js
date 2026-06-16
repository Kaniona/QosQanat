import STTService from '../services/stt.service.js';
import TTSService from '../services/tts.service.js';
import AIService from '../services/ai.service.js';
import ContextService from '../services/context.service.js';
import MemoryService from '../services/memory.service.js';
import { logger } from '../utils/logger.js';
import { validateGrade, validateAssistantType } from '../middleware/safety.middleware.js';
import { AUDIO_CONFIG } from '../config/constants.js';

export class VoiceController {
  // Full voice chat cycle: Audio → STT → AI → TTS → Audio
  static async voiceChat(req, res, next) {
    const startTime = Date.now();

    try {
      const {
        student_id = 'anonymous',
        grade = 8,
        subject = 'Қазақ тілі',
        topic = 'Сабақ',
        assistant_type = 'bektur'
      } = req.body;

      // Input validation
      if (!req.file) {
        return res.status(400).json({
          error: 'Аудио файл жіберіңіз',
          code: 'MISSING_AUDIO'
        });
      }

      if (!validateGrade(grade)) {
        return res.status(400).json({
          error: 'Сынып дұрыс емес (5-11)',
          code: 'INVALID_GRADE'
        });
      }

      if (!validateAssistantType(assistant_type)) {
        return res.status(400).json({
          error: 'Көмекші түрі дұрыс емес (bektur/nazym)',
          code: 'INVALID_ASSISTANT'
        });
      }

      logger.info(`🎤 Voice chat started: ${student_id} (${assistant_type})`);

      // Step 1: STT - Convert audio to text (with timeout)
      let transcription;
      try {
        transcription = await Promise.race([
          STTService.transcribeAudio(req.file.buffer, AUDIO_CONFIG.LANGUAGE),
          new Promise((_, reject) =>
            setTimeout(() => reject(new Error('STT timeout (25s)')), 25000)
          )
        ]);
      } catch (sttError) {
        logger.error('❌ STT failed:', sttError.message);
        return res.status(503).json({
          error: 'Дауысты өңдеу сәтсіз аяқталды. Қайталап көріңіз.',
          code: 'STT_ERROR'
        });
      }

      const studentMessage = transcription.text?.trim();
      if (!studentMessage) {
        logger.warn('⚠️ Empty transcription');
        return res.status(400).json({
          error: 'Дауысыңыз анық емес, қайталап айтыңыз',
          code: 'EMPTY_TRANSCRIPTION'
        });
      }

      logger.info(`📝 Transcribed: "${studentMessage.substring(0, 50)}..."`);

      // Step 2: AI - Generate response (with timeout)
      let aiResponse;
      try {
        const history = await MemoryService.getConversationHistory(student_id);
        const context = ContextService.buildContext(
          student_id,
          grade,
          subject,
          topic,
          studentMessage,
          assistant_type,
          history
        );

        aiResponse = await Promise.race([
          AIService.generateResponse(context),
          new Promise((_, reject) =>
            setTimeout(() => reject(new Error('AI timeout (30s)')), 30000)
          )
        ]);
      } catch (aiError) {
        logger.error('❌ AI failed:', aiError.message);
        return res.status(503).json({
          error: 'AI жауап бере алмады. Қайталап көріңіз.',
          code: 'AI_ERROR'
        });
      }

      const responseText = aiResponse.text;
      if (!responseText) {
        throw new Error('Empty AI response');
      }

      logger.info(`🤖 AI response: "${responseText.substring(0, 50)}..."`);

      // Step 3: TTS - Convert text to speech (with timeout)
      let audioResult;
      try {
        audioResult = await Promise.race([
          TTSService.synthesizeSpeech(responseText, assistant_type),
          new Promise((_, reject) =>
            setTimeout(() => reject(new Error('TTS timeout (15s)')), 15000)
          )
        ]);
      } catch (ttsError) {
        logger.error('❌ TTS failed:', ttsError.message);
        // Return text response if TTS fails
        logger.warn('⚠️ Returning text-only response (TTS failed)');
        await MemoryService.storeConversation(
          student_id, studentMessage, responseText, grade, subject, topic
        );
        return res.json({
          transcript: studentMessage,
          reply_text: responseText,
          reply_audio: null,
          audio_format: null,
          assistant_type,
          warning: 'TTS service unavailable',
          processingTime: Date.now() - startTime
        });
      }

      // Store conversation
      try {
        await MemoryService.storeConversation(
          student_id, studentMessage, responseText, grade, subject, topic
        );
      } catch (storageError) {
        logger.warn('⚠️ Failed to store conversation:', storageError.message);
        // Don't fail the request if storage fails
      }

      const audioBase64 = audioResult.audio.toString('base64');
      const processingTime = Date.now() - startTime;

      logger.info(`✅ Voice chat completed in ${processingTime}ms`);

      res.json({
        transcript: studentMessage,
        reply_text: responseText,
        reply_audio: audioBase64,
        audio_format: 'mp3',
        assistant_type,
        timestamp: new Date().toISOString(),
        processingTime,
        model: aiResponse.model
      });
    } catch (error) {
      logger.error('❌ Unexpected voice chat error:', error);
      const processingTime = Date.now() - startTime;

      res.status(500).json({
        error: 'Ішкі қызмет қатесі',
        code: 'INTERNAL_ERROR',
        processingTime,
        message: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // STT only
  static async transcribeAudio(req, res, next) {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'Аудио файл жіберіңіз' });
      }

      const transcription = await STTService.transcribeAudio(
        req.file.buffer,
        AUDIO_CONFIG.LANGUAGE
      );

      res.json({
        text: transcription.text,
        language: transcription.language
      });
    } catch (error) {
      logger.error('STT қатесі:', error);
      next(error);
    }
  }

  // TTS only
  static async synthesizeAudio(req, res, next) {
    try {
      const { text, assistant_type = 'bektur' } = req.body;

      if (!text || text.trim().length === 0) {
        return res.status(400).json({ error: 'Мәтін бос болмауы керек' });
      }

      if (!validateAssistantType(assistant_type)) {
        return res.status(400).json({ error: 'Көмекші түрі дұрыс емес' });
      }

      const audioResult = await TTSService.synthesizeSpeech(text, assistant_type);

      res.set('Content-Type', 'audio/mpeg');
      res.send(audioResult.audio);
    } catch (error) {
      logger.error('TTS қатесі:', error);
      next(error);
    }
  }
}

export default VoiceController;
