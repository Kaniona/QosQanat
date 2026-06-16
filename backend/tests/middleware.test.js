// Middleware tests
import { validateGrade, validateAssistantType, filterAIResponse } from '../src/middleware/safety.middleware.js';

describe('Safety Middleware', () => {

  describe('validateGrade()', () => {
    test('accepts valid grades 5-11', () => {
      expect(validateGrade(5)).toBe(true);
      expect(validateGrade(8)).toBe(true);
      expect(validateGrade(11)).toBe(true);
    });

    test('rejects invalid grades', () => {
      expect(validateGrade(4)).toBe(false);
      expect(validateGrade(12)).toBe(false);
      expect(validateGrade('abc')).toBe(false);
    });
  });

  describe('validateAssistantType()', () => {
    test('accepts valid assistant types', () => {
      expect(validateAssistantType('bektur')).toBe(true);
      expect(validateAssistantType('NAZYM')).toBe(true);
      expect(validateAssistantType('Bektur')).toBe(true);
    });

    test('rejects invalid types', () => {
      expect(validateAssistantType('brat')).toBe(false);
      expect(validateAssistantType('')).toBe(false);
      expect(validateAssistantType(null)).toBe(false);
    });
  });

  describe('filterAIResponse()', () => {
    test('removes URLs from response', () => {
      const input = 'Барлығы жақсы https://example.com қара';
      const output = filterAIResponse(input);
      expect(output).not.toContain('https://');
    });

    test('removes email addresses', () => {
      const input = 'Менің email test@example.com';
      const output = filterAIResponse(input);
      expect(output).not.toContain('@');
    });

    test('trims whitespace', () => {
      const input = '  Сәлем  ';
      const output = filterAIResponse(input);
      expect(output).toBe('Сәлем');
    });
  });

});
