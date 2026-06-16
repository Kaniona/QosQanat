import Anthropic from '@anthropic-ai/sdk';
import OpenAI from 'openai';
import { env } from '../config/env.js';
import { AI_MODELS, CONTEXT_CONFIG } from '../config/constants.js';
import bekturPrompt from '../prompts/bektur.prompt.js';
import nazymPrompt from '../prompts/nazym.prompt.js';
import { logger } from '../utils/logger.js';
import { filterAIResponse } from '../middleware/safety.middleware.js';

let anthropic = null;
let openai = null;

// Initialize clients with error handling
try {
  if (env.anthropicApiKey) {
    anthropic = new Anthropic({
      apiKey: env.anthropicApiKey,
      timeout: 30000
    });
    logger.info('✅ Anthropic Claude client initialized');
  }
} catch (error) {
  logger.warn('⚠️ Anthropic initialization failed:', error.message);
}

try {
  if (env.openaiApiKey) {
    openai = new OpenAI({
      apiKey: env.openaiApiKey,
      timeout: 30000
    });
    logger.info('✅ OpenAI client initialized');
  }
} catch (error) {
  logger.warn('⚠️ OpenAI initialization failed:', error.message);
}

export class AIService {
  static async generateResponse(context, retries = 2) {
    try {
      // Validate input
      if (!context || !context.message) {
        throw new Error('Message is required');
      }

      const {
        message,
        grade = 8,
        subject = 'Қазақ тілі',
        topic = 'Сабақ',
        assistantType = 'bektur',
        conversationHistory = []
      } = context;

      // Validate grade
      if (grade < 5 || grade > 11) {
        throw new Error('Grade must be between 5 and 11');
      }

      // Select prompt based on assistant type
      const systemPrompt = assistantType === 'nazym'
        ? nazymPrompt(grade, subject, topic)
        : bekturPrompt(grade, subject, topic);

      // Build messages with history - limit to last 10
      const limitedHistory = Array.isArray(conversationHistory)
        ? conversationHistory.slice(-10)
        : [];

      const messages = [
        ...limitedHistory.map(h => ({
          role: h.role || 'user',
          content: String(h.content || '').substring(0, 2000)
        })),
        { role: 'user', content: String(message).substring(0, 2000) }
      ];

      let response;
      let usedProvider;

      // Use Anthropic Claude (primary)
      if (anthropic) {
        try {
          response = await this._generateWithClaude(systemPrompt, messages);
          usedProvider = 'claude';
        } catch (error) {
          if (retries > 0 && this._isRetryableError(error)) {
            logger.warn(`🔄 Retrying Claude (${retries} left):`, error.message);
            await this._delay(1000);
            return this.generateResponse(context, retries - 1);
          }
          // Fallback to OpenAI if Claude fails
          if (openai) {
            logger.warn('📱 Switching to OpenAI fallback');
            response = await this._generateWithOpenAI(systemPrompt, messages);
            usedProvider = 'openai';
          } else {
            throw error;
          }
        }
      }
      // Fallback to OpenAI GPT
      else if (openai) {
        response = await this._generateWithOpenAI(systemPrompt, messages);
        usedProvider = 'openai';
      }
      else {
        throw new Error('API keys not configured. Set ANTHROPIC_API_KEY or OPENAI_API_KEY');
      }

      // Validate response
      if (!response || typeof response !== 'string') {
        throw new Error('Invalid response from AI service');
      }

      // Filter response for safety
      const filtered = filterAIResponse(response);

      if (!filtered || filtered.length === 0) {
        throw new Error('Response filtered to empty');
      }

      logger.info(`✅ AI ${assistantType}: ${filtered.substring(0, 80)}...`);

      return {
        text: filtered,
        assistantType,
        model: usedProvider,
        length: filtered.length,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('❌ AI Service Error:', error.message);
      throw new Error(`AI жауап беру сәтсіз аяқталды: ${error.message}`);
    }
  }

  static _isRetryableError(error) {
    const retryableCodes = [429, 500, 502, 503, 504];
    const message = error.message || '';
    return (
      retryableCodes.includes(error.status) ||
      message.includes('timeout') ||
      message.includes('ECONNRESET') ||
      message.includes('ETIMEDOUT')
    );
  }

  static _delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  static async _generateWithClaude(systemPrompt, messages) {
    const response = await anthropic.messages.create({
      model: AI_MODELS.CLAUDE,
      max_tokens: CONTEXT_CONFIG.MAX_TOKENS,
      temperature: CONTEXT_CONFIG.TEMPERATURE,
      system: systemPrompt,
      messages
    });

    return response.content[0].type === 'text'
      ? response.content[0].text
      : '';
  }

  static async _generateWithOpenAI(systemPrompt, messages) {
    const response = await openai.chat.completions.create({
      model: AI_MODELS.GPT4,
      max_tokens: CONTEXT_CONFIG.MAX_TOKENS,
      temperature: CONTEXT_CONFIG.TEMPERATURE,
      messages: [{ role: 'system', content: systemPrompt }, ...messages]
    });

    return response.choices[0].message.content || '';
  }

  static async explainConcept(topic, grade, assistantType = 'bektur') {
    try {
      const prompt = assistantType === 'nazym'
        ? nazymPrompt(grade, 'Түсіндіру', topic)
        : bekturPrompt(grade, 'Түсіндіру', topic);

      let response;

      if (anthropic) {
        response = await anthropic.messages.create({
          model: AI_MODELS.CLAUDE,
          max_tokens: CONTEXT_CONFIG.MAX_TOKENS,
          temperature: CONTEXT_CONFIG.TEMPERATURE,
          system: prompt,
          messages: [{
            role: 'user',
            content: `${topic} тақырыбын түсіндіре беріңіз`
          }]
        });
        response = response.content[0].text;
      } else if (openai) {
        const gptResponse = await openai.chat.completions.create({
          model: AI_MODELS.GPT4,
          max_tokens: CONTEXT_CONFIG.MAX_TOKENS,
          messages: [
            { role: 'system', content: prompt },
            { role: 'user', content: `${topic} тақырыбын түсіндіріп беріңіз` }
          ]
        });
        response = gptResponse.choices[0].message.content;
      }

      return { explanation: filterAIResponse(response) };
    } catch (error) {
      logger.error('Түсіндіру қатесі:', error);
      throw error;
    }
  }

  static async giveHint(question, studentAnswer, grade, assistantType = 'bektur') {
    try {
      const prompt = assistantType === 'nazym'
        ? nazymPrompt(grade, 'Кеңес', question)
        : bekturPrompt(grade, 'Кеңес', question);

      let response;

      if (anthropic) {
        response = await anthropic.messages.create({
          model: AI_MODELS.CLAUDE,
          max_tokens: 300,
          temperature: CONTEXT_CONFIG.TEMPERATURE,
          system: prompt,
          messages: [{
            role: 'user',
            content: `Сұрақ: ${question}\nМенің жауабым: ${studentAnswer}\nТолық жауапты бермей, бағыттайтын кеңес бер.`
          }]
        });
        response = response.content[0].text;
      } else if (openai) {
        const gptResponse = await openai.chat.completions.create({
          model: AI_MODELS.GPT4,
          max_tokens: 300,
          messages: [
            { role: 'system', content: prompt },
            { role: 'user', content: `Сұрақ: ${question}\nМенің жауабым: ${studentAnswer}\nТолық жауапты бермей, бағыттайтын кеңес бер.` }
          ]
        });
        response = gptResponse.choices[0].message.content;
      }

      return { hint: filterAIResponse(response) };
    } catch (error) {
      logger.error('Кеңес қатесі:', error);
      throw error;
    }
  }

  static async checkAnswer(question, correctAnswer, studentAnswer, grade) {
    try {
      const systemPrompt = `
Сен қатаң бірақ әділ оқытушысың. Оқушының жауабын тексер және:
1. Дұрыс па? (true/false)
2. Түсіндіру (қысқа, балалық деңгейде)
3. Қалыпты жауап болса, мадақта
4. Қателі болса, жұмсақ түзет

СЫНЫП ДЕҢГЕЙІ: ${grade}
`;

      let response;

      if (anthropic) {
        response = await anthropic.messages.create({
          model: AI_MODELS.CLAUDE,
          max_tokens: 400,
          system: systemPrompt,
          messages: [{
            role: 'user',
            content: `
Сұрақ: ${question}
Дұрыс жауап: ${correctAnswer}
Оқушының жауабы: ${studentAnswer}

JSON форматында жауап бер: {"is_correct": true/false, "feedback": "..."}`
          }]
        });
        response = response.content[0].text;
      } else if (openai) {
        const gptResponse = await openai.chat.completions.create({
          model: AI_MODELS.GPT4,
          max_tokens: 400,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: `
Сұрақ: ${question}
Дұрыс жауап: ${correctAnswer}
Оқушының жауабы: ${studentAnswer}

JSON форматында жауап бер: {"is_correct": true/false, "feedback": "..."}` }
          ]
        });
        response = gptResponse.choices[0].message.content;
      }

      // Parse JSON response safely
      let parsed;
      try {
        const jsonMatch = response.match(/\{[\s\S]*\}/);
        if (!jsonMatch || !jsonMatch[0]) {
          throw new Error('No JSON found in response');
        }
        parsed = JSON.parse(jsonMatch[0]);
      } catch (parseError) {
        logger.error('Failed to parse AI JSON response:', parseError);
        // Fallback: try to extract boolean from response
        const isCorrect = response.toLowerCase().includes('дұрыс') ||
                         response.toLowerCase().includes('толық') ||
                         response.toLowerCase().includes('yes') ||
                         response.toLowerCase().includes('true');
        return {
          isCorrect,
          feedback: filterAIResponse(response.substring(0, 500)),
          parseError: true
        };
      }

      if (typeof parsed.is_correct !== 'boolean' || !parsed.feedback) {
        throw new Error('Invalid JSON structure from AI');
      }

      return {
        isCorrect: parsed.is_correct,
        feedback: filterAIResponse(parsed.feedback),
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Жауап тексеру қатесі:', error);
      throw error;
    }
  }
}

export default AIService;
