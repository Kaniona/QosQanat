// AIService unit tests — SDK calls are mocked, no live API / network needed.
import { jest } from '@jest/globals';

// Shared mock for Anthropic's messages.create
const mockAnthropicCreate = jest.fn();
// Shared mock for OpenAI's chat.completions.create
const mockOpenAICreate = jest.fn();

jest.unstable_mockModule('@anthropic-ai/sdk', () => ({
  default: class {
    constructor() {
      this.messages = { create: mockAnthropicCreate };
    }
  }
}));

jest.unstable_mockModule('openai', () => ({
  default: class {
    constructor() {
      this.chat = { completions: { create: mockOpenAICreate } };
    }
  }
}));

// Ensure a key exists so the Anthropic client gets initialized in ai.service.js
process.env.ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY || 'sk-test-key';

const { default: AIService } = await import('../src/services/ai.service.js');

const claudeText = (text) => ({ content: [{ type: 'text', text }] });

beforeEach(() => {
  mockAnthropicCreate.mockReset();
  mockOpenAICreate.mockReset();
});

describe('AIService', () => {
  test('generateResponse() returns object with text property', async () => {
    mockAnthropicCreate.mockResolvedValue(claudeText('Сәлем! Мен көмектесемін.'));

    const response = await AIService.generateResponse({
      message: 'Сәлем!',
      grade: 8,
      subject: 'Қазақ тілі',
      topic: 'Сабақ',
      assistantType: 'bektur',
      conversationHistory: []
    });

    expect(response).toHaveProperty('text');
    expect(response).toHaveProperty('assistantType', 'bektur');
    expect(response).toHaveProperty('model', 'claude');
    expect(typeof response.text).toBe('string');
    expect(mockAnthropicCreate).toHaveBeenCalledTimes(1);
  });

  test('generateResponse() rejects invalid grade', async () => {
    await expect(
      AIService.generateResponse({ message: 'Сәлем!', grade: 99 })
    ).rejects.toThrow();
  });

  test('explainConcept() returns explanation', async () => {
    mockAnthropicCreate.mockResolvedValue(claudeText('Квадрат теңдеу дегеніміз...'));

    const result = await AIService.explainConcept('Квадрат теңдеулер', 9, 'nazym');
    expect(result).toHaveProperty('explanation');
    expect(typeof result.explanation).toBe('string');
  });

  test('giveHint() returns hint', async () => {
    mockAnthropicCreate.mockResolvedValue(claudeText('Алдымен 5-ті екі жаққа да азайтып көр.'));

    const result = await AIService.giveHint('2x + 5 = 15', '10', 8, 'bektur');
    expect(result).toHaveProperty('hint');
    expect(typeof result.hint).toBe('string');
  });

  test('checkAnswer() parses JSON correct/incorrect response', async () => {
    mockAnthropicCreate.mockResolvedValue(
      claudeText('{"is_correct": true, "feedback": "Дұрыс жауап!"}')
    );

    const result = await AIService.checkAnswer('2 + 2 = ?', '4', '4', 5);
    expect(result).toHaveProperty('isCorrect', true);
    expect(result).toHaveProperty('feedback');
    expect(typeof result.isCorrect).toBe('boolean');
  });
});
