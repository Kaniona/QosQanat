import OpenAI from 'openai';
import fs from 'fs';
import { env } from '../config/env.js';
import { AUDIO_CONFIG } from '../config/constants.js';
import { logger } from '../utils/logger.js';
import { AudioConverter } from '../utils/audioConverter.js';

const openai = new OpenAI({ apiKey: env.openaiApiKey });

export class STTService {
  static async transcribeAudio(audioBuffer, language = 'kk') {
    let tempPath = null;

    try {
      // Validate audio
      if (!audioBuffer) {
        throw new Error('Audio buffer is required');
      }

      AudioConverter.validateAudioBuffer(audioBuffer);

      // Save temporarily to file (Whisper API needs file object)
      tempPath = AudioConverter.saveTemporaryAudio(audioBuffer);

      if (!openai) {
        throw new Error('OpenAI client not initialized');
      }

      // Call Whisper API with timeout
      const transcript = await Promise.race([
        openai.audio.transcriptions.create({
          file: fs.createReadStream(tempPath),
          model: 'whisper-1',
          language: language,
          response_format: 'text'
        }),
        new Promise((_, reject) =>
          setTimeout(() => reject(new Error('STT timeout (25s)')), 25000)
        )
      ]);

      if (!transcript || typeof transcript !== 'string') {
        throw new Error('Invalid transcript response from Whisper');
      }

      const cleanedTranscript = transcript.trim();
      if (cleanedTranscript.length === 0) {
        logger.warn('⚠️ Whisper returned empty transcript');
        return {
          text: '',
          language: language,
          confidence: 0,
          empty: true
        };
      }

      logger.info(`✅ STT: "${cleanedTranscript.substring(0, 100)}..." (${language})`);

      return {
        text: cleanedTranscript,
        language: language,
        confidence: 0.95,
        length: cleanedTranscript.length,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('❌ STT Error:', error.message);

      // Specific error handling
      if (error.message.includes('too long') || error.message.includes('Request too large')) {
        throw new Error('Аудио файлы тым ұзын (макс 25 минут)');
      }

      if (error.message.includes('Unsupported') || error.message.includes('format')) {
        throw new Error('Аудио форматы қолдау жоқ (MP3, WAV, OGG)');
      }

      if (error.message.includes('401') || error.message.includes('403')) {
        throw new Error('OpenAI API кілті дұрыс емес');
      }

      if (error.message.includes('timeout')) {
        throw new Error('Дауысты өңдеу ұзақ болды (>25с)');
      }

      if (error.message.includes('429')) {
        throw new Error('API rate limit достигнут. Бірнеше сәттік күтіңіз');
      }

      throw new Error(`Дауысты мәтінге айналдыру сәтсіз: ${error.message}`);
    } finally {
      // Always clean up temp file
      if (tempPath) {
        AudioConverter.deleteTemporaryAudio(tempPath);
      }
    }
  }

  static async transcribeBase64(base64Audio, language = 'kk') {
    try {
      const buffer = AudioConverter.base64ToBuffer(base64Audio);
      return await this.transcribeAudio(buffer, language);
    } catch (error) {
      logger.error('Base64 STT қатесі:', error);
      throw error;
    }
  }
}

export default STTService;
