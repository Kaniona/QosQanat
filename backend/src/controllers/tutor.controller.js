import AIService from '../services/ai.service.js';
import { logger } from '../utils/logger.js';

export class TutorController {
  static async explainConcept(req, res, next) {
    try {
      // Validated and normalised by validateRequest(tutorExplainSchema)
      const { topic, grade, assistant_type } = req.body;

      const result = await AIService.explainConcept(topic, grade, assistant_type);

      res.json({
        topic,
        explanation: result.explanation,
        assistant_type,
        timestamp: new Date()
      });
    } catch (error) {
      logger.error('Түсіндіру қатесі:', error);
      next(error);
    }
  }

  static async giveHint(req, res, next) {
    try {
      // Validated and normalised by validateRequest(tutorHintSchema)
      const { question, student_answer, grade, assistant_type } = req.body;

      const result = await AIService.giveHint(
        question,
        student_answer,
        grade,
        assistant_type
      );

      res.json({
        question,
        student_answer,
        hint: result.hint,
        assistant_type,
        timestamp: new Date()
      });
    } catch (error) {
      logger.error('Кеңес қатесі:', error);
      next(error);
    }
  }

  static async checkAnswer(req, res, next) {
    try {
      // Validated and normalised by validateRequest(tutorCheckSchema)
      const { question, correct_answer, student_answer, grade } = req.body;

      const result = await AIService.checkAnswer(
        question,
        correct_answer,
        student_answer,
        grade
      );

      res.json({
        question,
        correct_answer,
        student_answer,
        is_correct: result.isCorrect,
        feedback: result.feedback,
        timestamp: new Date()
      });
    } catch (error) {
      logger.error('Жауап тексеру қатесі:', error);
      next(error);
    }
  }
}

export default TutorController;
