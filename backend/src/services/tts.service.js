import axios from 'axios';
import { env } from '../config/env.js';
import { AZURE_VOICES } from '../config/constants.js';
import { logger } from '../utils/logger.js';

export class TTSService {
  static async synthesizeSpeech(text, assistantType = 'bektur') {
    try {
      // Validate inputs
      if (!text || typeof text !== 'string') {
        throw new Error('Text must be a non-empty string');
      }

      const trimmedText = text.trim();
      if (trimmedText.length === 0) {
        throw new Error('Мәтін бос болмауы керек');
      }

      if (trimmedText.length > 5000) {
        throw new Error('Мәтін тым ұзын (макс: 5000 символ)');
      }

      if (!env.azureSpeechKey || !env.azureSpeechRegion) {
        throw new Error('Azure Speech credentials not configured');
      }

      const voice = AZURE_VOICES[assistantType] || AZURE_VOICES.bektur;

      // SSML format for Azure Speech Service (Kazakh)
      const escapedText = this._escapeXml(trimmedText);
      const ssml = `<speak version='1.0' xml:lang='kk-KZ'>
        <voice xml:lang='kk-KZ' name='${voice}'>
          <prosody rate='0.95' pitch='0'>
            ${escapedText}
          </prosody>
        </voice>
      </speak>`;

      const url = `https://${env.azureSpeechRegion}.tts.speech.microsoft.com/cognitiveservices/v1`;

      const response = await axios.post(url, ssml, {
        headers: {
          'Ocp-Apim-Subscription-Key': env.azureSpeechKey,
          'Content-Type': 'application/ssml+xml',
          'X-Microsoft-OutputFormat': 'audio-16khz-32kbitrate-mono-mp3'
        },
        responseType: 'arraybuffer',
        timeout: 10000
      });

      if (!response.data || response.data.length === 0) {
        throw new Error('Empty audio response from Azure');
      }

      logger.info(`✅ TTS synthesis: ${assistantType} (${trimmedText.length} chars → ${response.data.length} bytes)`);

      return {
        audio: Buffer.from(response.data),
        mimeType: 'audio/mpeg',
        format: 'mp3',
        voice: voice,
        size: response.data.length,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('❌ TTS Error:', error.message);

      // Specific error messages
      if (error.response?.status === 401 || error.response?.status === 403) {
        throw new Error('Azure Speech API кілті дұрыс емес немесе қоршеу дұрыс емес');
      }

      if (error.code === 'ECONNREFUSED' || error.message.includes('ECONNREFUSED')) {
        throw new Error('Azure Speech сервері қолжетімсіз');
      }

      if (error.message.includes('timeout')) {
        throw new Error('TTS сервері ұзын жауап берді (>10s)');
      }

      throw new Error(`Мәтінді дауысқа айналдыру сәтсіз: ${error.message}`);
    }
  }

  static async synthesizeSpeechToBase64(text, assistantType = 'bektur') {
    const result = await this.synthesizeSpeech(text, assistantType);
    return result.audio.toString('base64');
  }

  static async synthesizeSpeechToFile(text, assistantType = 'bektur', filepath) {
    const result = await this.synthesizeSpeech(text, assistantType);

    const fs = await import('fs');
    fs.writeFileSync(filepath, result.audio);

    logger.info(`TTS файлы сақталды: ${filepath}`);

    return filepath;
  }

  static _escapeXml(text) {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }
}

export default TTSService;
