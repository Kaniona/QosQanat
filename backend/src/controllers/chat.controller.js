import AIService from '../services/ai.service.js';
import ContextService from '../services/context.service.js';
import MemoryService from '../services/memory.service.js';
import { logger } from '../utils/logger.js';

export class ChatController {
  static async sendMessage(req, res, next) {
    const startTime = Date.now();

    try {
      // Request body has already been validated and normalised by the Joi
      // schema (validateRequest) and the safety middleware on the route.
      const {
        student_id,
        grade,
        subject,
        topic,
        message,
        assistant_type
      } = req.body;

      const trimmedMessage = message.trim();

      logger.info(`💬 Chat: ${student_id} → "${trimmedMessage.substring(0, 50)}..."`);

      try {
        // Get conversation history
        const history = await MemoryService.getConversationHistory(student_id);

        // Build context
        const context = ContextService.buildContext(
          student_id,
          grade,
          subject,
          topic,
          trimmedMessage,
          assistant_type,
          history
        );

        // Get AI response. The underlying SDK clients enforce their own 30s
        // request timeout, so a wrapper race here would only leak a pending
        // request without cancelling it.
        const aiResponse = await AIService.generateResponse(context);

        if (!aiResponse || !aiResponse.text) {
          throw new Error('Empty AI response');
        }

        // Store conversation
        try {
          await MemoryService.storeConversation(
            student_id,
            trimmedMessage,
            aiResponse.text,
            grade,
            subject,
            topic
          );
        } catch (storageError) {
          logger.warn('⚠️ Failed to store conversation:', storageError.message);
        }

        const processingTime = Date.now() - startTime;

        logger.info(`✅ Chat response (${processingTime}ms): "${aiResponse.text.substring(0, 50)}..."`);

        res.json({
          reply: aiResponse.text,
          assistantType: assistant_type,
          model: aiResponse.model || 'claude',
          processingTime,
          timestamp: new Date().toISOString()
        });
      } catch (aiError) {
        logger.error('❌ AI Error in chat:', aiError.message);
        return res.status(503).json({
          error: 'AI жауап бере алмады',
          code: 'AI_SERVICE_ERROR',
          message: process.env.NODE_ENV === 'development' ? aiError.message : undefined,
          processingTime: Date.now() - startTime,
          timestamp: new Date().toISOString()
        });
      }
    } catch (error) {
      logger.error('❌ Chat controller error:', error);
      const processingTime = Date.now() - startTime;

      res.status(500).json({
        error: 'Сұхбат қатесі',
        code: 'CHAT_ERROR',
        processingTime,
        message: process.env.NODE_ENV === 'development' ? error.message : undefined,
        timestamp: new Date().toISOString()
      });
    }
  }
}

export default ChatController;
