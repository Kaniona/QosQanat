import fs from 'fs';
import path from 'path';
import { logger } from './logger.js';

export class AudioConverter {
  static getFileExtension(buffer) {
    // Check magic numbers to identify audio format
    const hex = buffer.toString('hex', 0, 4);

    if (hex.startsWith('fff')) return 'mp3'; // MPEG frame
    if (hex.startsWith('4944')) return 'mp3'; // ID3 tag
    if (hex.startsWith('5249')) return 'wav'; // RIFF header
    if (hex.startsWith('fffb')) return 'mp3';
    if (hex.startsWith('ffa')) return 'mp3';

    return 'mp3'; // Default fallback
  }

  static validateAudioBuffer(buffer, maxSize = 10 * 1024 * 1024) {
    if (!buffer || buffer.length === 0) {
      throw new Error('Аудио файл бос немесе жоқ');
    }

    if (buffer.length > maxSize) {
      throw new Error(`Аудио файлы тым ұлғайды (макс: ${maxSize / 1024 / 1024}MB)`);
    }

    return true;
  }

  static async saveTemporaryAudio(buffer, filename = null) {
    const tempDir = path.join(process.cwd(), 'temp');

    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    const ext = this.getFileExtension(buffer);
    const name = filename || `audio_${Date.now()}.${ext}`;
    const filepath = path.join(tempDir, name);

    fs.writeFileSync(filepath, buffer);
    logger.debug(`Аудио сақталды: ${filepath}`);

    return filepath;
  }

  static deleteTemporaryAudio(filepath) {
    try {
      if (fs.existsSync(filepath)) {
        fs.unlinkSync(filepath);
        logger.debug(`Аудио удалено: ${filepath}`);
      }
    } catch (error) {
      logger.warn(`Не удалось удалить: ${filepath}`);
    }
  }

  static bufferToBase64(buffer) {
    return buffer.toString('base64');
  }

  static base64ToBuffer(base64String) {
    return Buffer.from(base64String, 'base64');
  }
}
