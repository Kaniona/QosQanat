# QosQanat API — Тестеу Құжаттамасы

## 🧪 Тест Түрлері

### 1. Unit Tests (Құрамдық тесттер)
- Жеке функциялар мен сервистерді тестеу
- Мысалы: `validateGrade()`, `filterAIResponse()`

### 2. Integration Tests (Интеграция тесттері)
- Көптеген компоненттердің бірлігін тестеу
- Мысалы: Chat endpoint (auth → validation → AI → response)

### 3. API Tests (API тесттері)
- HTTP сұрау-жауапты тестеу
- Мысалы: POST /api/chat, POST /api/voice/chat

### 4. E2E Tests (Қорындығы тесттері)
- Толық пайдаланушы сценарийлерін тестеу
- Мысалы: Дауыс сұрақ → STT → AI → TTS → Аудио жауап

---

## 🚀 Тесттерді іске қосу

### Барлық тесттерді іске қос
```bash
npm test
```

### Белгілі бір тест файлын іске қос
```bash
npm test ai.service.test.js
npm test middleware.test.js
```

### Watch режімінде (кодты өзгеркен автоматты)
```bash
npm test -- --watch
```

### Coverage қараңыз (қай коды тестелінген)
```bash
npm test -- --coverage
```

---

## 📋 Тест Файлдары

### `ai.service.test.js`
AI сервисінің функциялары тестеледі:
- `generateResponse()` — AI жауап береді
- `explainConcept()` — Түсіндіру береді
- `giveHint()` — Кеңес береді
- `checkAnswer()` — Жауапты тексереді

### `middleware.test.js`
Қауіпсіздік орындалдығы:
- `validateGrade()` — Сынап дұрыс па
- `validateAssistantType()` — Көмекші дұрыс па
- `filterAIResponse()` — Жауап өңделген бе

### `api.test.js` (болады)
API эндпоинттерін тестеу:
```bash
POST /api/chat
POST /api/voice/chat
POST /api/tutor/explain
```

---

## 🔧 Тест Жазу Үлгісі

```javascript
import { someFunction } from '../src/services/service.js';

describe('ServiceName', () => {
  
  describe('functionName()', () => {
    
    test('description of what should happen', () => {
      // Дайындық
      const input = 'test input';
      
      // Іске қосу
      const result = someFunction(input);
      
      // Тексеру
      expect(result).toBe('expected output');
    });

    test('should handle error cases', () => {
      expect(() => {
        someFunction(null);
      }).toThrow();
    });

  });

});
```

---

## 📝 Тест Жазу Ережелері

1. **Ясы сипатта**: `test()` ішінде не тестеніңіз де 明確 болсын
2. **Бір тестте бір нәрсе**: Әрбір test() тек бір қасиетті тексереді
3. **Arrange-Act-Assert**: Дайындық → Іске қосу → Тексеру
4. **Error cases**: Толық болу үшін қалама сценарийлерді тестеңіз

Қалама:
```javascript
test('handles error gracefully', () => {
  // Қалама деректер
  const result = functionWithError(invalidInput);
  // Нәтиже дұрыс па?
  expect(result.error).toBeDefined();
});
```

---

## 🔍 Mock/Stub Пайдалану (Advanced)

```javascript
import { jest } from '@jest/globals';
import AIService from '../src/services/ai.service.js';

describe('AI Service with Mocks', () => {
  
  test('generateResponse calls API', async () => {
    // Mock Claude API
    const mockApiCall = jest.spyOn(AIService, 'generateResponse')
      .mockResolvedValue({ text: 'Мақал жауап' });
    
    const result = await AIService.generateResponse({ message: 'Сәлем' });
    
    expect(mockApiCall).toHaveBeenCalled();
    expect(result.text).toBe('Мақал жауап');
    
    mockApiCall.mockRestore();
  });

});
```

---

## ⚙️ Continuous Integration (CI)

GitHub Actions-та автоматты тестеу:

`.github/workflows/test.yml`:
```yaml
name: Run Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - run: npm install
      - run: npm test -- --coverage
      - run: npm run lint
```

---

## 🎯 Test Coverage Мақсаттары

```
Statements   : 80% ✅ (minimum)
Branches     : 75% ✅
Functions    : 80% ✅
Lines        : 80% ✅
```

Coverage қараңыз:
```bash
npm test -- --coverage
```

---

## 🐛 Ақаулықтарды шешу

### Тест жұмыс істемейді
```bash
# 1. Node версиясын тексер
node --version  # v18+ керек

# 2. Зависимостерді қайта орнат
rm -rf node_modules
npm install

# 3. .env файлы бар ма?
cp .env.example .env
```

### API кілттерінен қалғалығы сәтсіз болады
```javascript
// Интернет тестінің сәтсіздігін ұстау
test('handles API error', async () => {
  jest.spyOn(console, 'warn').mockImplementation();
  // Сервис қалмайтын API кілтілерін ұстап алады
});
```

---

## 📚 Қосымша Ресурстар

- [Jest Documentation](https://jestjs.io)
- [Testing Library](https://testing-library.com)
- [Supertest (API Testing)](https://github.com/visionmedia/supertest)

---

Барлық тесттерді жасап ақ құлақ болсын! 🚀
