// Assistant Types
export const ASSISTANT_TYPES = {
  BEKTUR: 'bektur',
  NAZYM: 'nazym'
};

// Azure Voice Mappings
export const AZURE_VOICES = {
  bektur: 'kk-KZ-DauletNeural',  // Male voice
  nazym: 'kk-KZ-AigulNeural'     // Female voice
};

// Grades (5-11)
export const GRADES = [5, 6, 7, 8, 9, 10, 11];

// Subjects
export const SUBJECTS = {
  MATH: 'Математика',
  KAZAKH: 'Қазақ тілі',
  ENGLISH: 'Ағылшын тілі',
  PHYSICS: 'Физика',
  CHEMISTRY: 'Химия',
  BIOLOGY: 'Биология',
  HISTORY: 'История',
  GEOGRAPHY: 'География',
  LITERATURE: 'Әдебиет'
};

// Rate Limiting
export const RATE_LIMITS = {
  CHAT_PER_MINUTE: 30,
  VOICE_PER_MINUTE: 15,
  TUTOR_PER_MINUTE: 20
};

// Audio
export const AUDIO_CONFIG = {
  MAX_FILE_SIZE: 10 * 1024 * 1024, // 10MB
  SUPPORTED_FORMATS: ['mp3', 'wav', 'ogg', 'm4a'],
  SAMPLE_RATE: 16000,
  LANGUAGE: 'kk' // Kazakh
};

// Context
export const CONTEXT_CONFIG = {
  MAX_HISTORY: 10,
  TEMPERATURE: 0.7,
  MAX_TOKENS: 500
};

// API Models
export const AI_MODELS = {
  // Haiku 4.5 — fast and cost-effective, suitable for an education app at scale
  CLAUDE: 'claude-haiku-4-5-20251001',
  // Sonnet 4.6 — higher quality for complex explanations when needed
  CLAUDE_SONNET: 'claude-sonnet-4-6',
  // OpenAI fallback
  GPT4: 'gpt-4o'
};

// Safety keywords (coarse pre-filter only).
//
// NOTE: a keyword blocklist is intentionally minimal — it catches only
// clearly inappropriate adult/illegal topics. We deliberately do NOT block
// neutral academic words like "қан" (blood) or "өлім" (death), which appear
// legitimately in biology, history and literature lessons. Nuanced moderation
// is handled by the AI model's own safety behaviour and the per-grade prompts.
export const BANNED_KEYWORDS = [
  'порнография',
  'порно',
  'есірткі',
  'нашақор',
  'педофил'
];
