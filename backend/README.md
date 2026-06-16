# QosQanat API — AI Tutor Backend

AI тьютор API Қазақстан мектеп оқушыларына (5-11 сынып) арналған **QosQanat** қосымшасы үшін.

## 🎯 Мақсат

- **AI Тьютор**: Оқушылар Бектұр (ер бала) немесе Назым (қыз) көмекшілерінің бірін таңдап оқи алады
- **Дауыстық Байланыс**: Дауыс → STT → AI → TTS → Дауыс цикл
- **Балалар Қауіпсіздігі**: Барлық контент білім беру аймағында

## 🛠 Технологиялар

- **Backend**: Node.js + Express (TypeScript қосымшасы болып беріледі)
- **AI/LLM**: Anthropic Claude API (Haiku 4.5), OpenAI GPT fallback
- **STT**: OpenAI Whisper API (қазақ тілі - kk)
- **TTS**: Azure Speech Service (қазақ дауыстары)
- **Storage**: сұхбат тарихы — Redis (жоқ болса in-memory fallback)

## 📦 Орнату

### 1. Зависимостерді орнат

```bash
npm install
```

### 2. Айнымалыларды баптау

`.env.example` көшіп `.env` істеңіз:

```bash
cp .env.example .env
```

Өз API кілттерін толтырыңыз:

```env
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
AZURE_SPEECH_KEY=...
AZURE_SPEECH_REGION=eastus
PORT=3000
NODE_ENV=development
```

### 3. Серверді іске қосу

```bash
# Develop режімінде (hot reload)
npm run dev

# Production
npm start
```

Сервер: `http://localhost:3000`

## 📚 API Эндпоинттері

### 1️⃣ **Мәтіндік Чат**

```http
POST /api/chat
Content-Type: application/json

{
  "student_id": "student_123",
  "grade": 8,
  "subject": "Математика",
  "topic": "Теңдеулер",
  "message": "2x + 5 = 15 теңдеуін қалай шешемін?",
  "assistant_type": "bektur"
}
```

**Жауабы:**

```json
{
  "reply": "Сөйтіңіз, ең алғашқы қадам қандай болуы керек?...",
  "assistantType": "bektur",
  "timestamp": "2024-06-16T10:30:00Z"
}
```

---

### 2️⃣ **Дауыстық Чат (ТОЛЫҚ ЦИКЛ)**

```http
POST /api/voice/chat
Content-Type: multipart/form-data

Audio file (mp3/wav/ogg) + 
{
  "student_id": "student_123",
  "grade": 8,
  "subject": "Қазақ тілі",
  "topic": "Сабақ",
  "assistant_type": "nazym"
}
```

**Жауабы:**

```json
{
  "transcript": "2x + 5 = 15 теңдеуін қалай шешемін?",
  "reply_text": "Ойланайық, сөйлеген сұрақ...",
  "reply_audio": "base64_encoded_mp3",
  "audio_format": "mp3",
  "assistant_type": "nazym",
  "timestamp": "2024-06-16T10:30:00Z"
}
```

---

### 3️⃣ **STT (Дауыс → Мәтін)**

```http
POST /api/voice/stt
Content-Type: multipart/form-data

Audio file
```

**Жауабы:**

```json
{
  "text": "Анықтасыңыз, балалар қауіпсіздігі неде?",
  "language": "kk"
}
```

---

### 4️⃣ **TTS (Мәтін → Дауыс)**

```http
POST /api/voice/tts
Content-Type: application/json

{
  "text": "Привет, қалайсың?",
  "assistant_type": "bektur"
}
```

**Жауабы:** `audio/mpeg` (binary)

---

### 5️⃣ **Тақырыпты Түсіндіру**

```http
POST /api/tutor/explain
Content-Type: application/json

{
  "topic": "Қуадрат теңдеулер",
  "grade": 9,
  "assistant_type": "nazym"
}
```

**Жауабы:**

```json
{
  "topic": "Қуадрат теңдеулер",
  "explanation": "Қуадрат теңдеулер ax² + bx + c = 0 түрінде болады...",
  "assistant_type": "nazym",
  "timestamp": "2024-06-16T10:30:00Z"
}
```

---

### 6️⃣ **Кеңес Беру**

```http
POST /api/tutor/hint
Content-Type: application/json

{
  "question": "Периметрі 12 см, ұзындығы 4 см болса, ені неше см?",
  "student_answer": "3 см",
  "grade": 5,
  "assistant_type": "bektur"
}
```

**Жауабы:**

```json
{
  "question": "Периметрі 12 см, ұзындығы 4 см болса, ені неше см?",
  "student_answer": "3 см",
  "hint": "Дұрыс! Периметр = 2(ұзындық + ені)...",
  "assistant_type": "bektur",
  "timestamp": "2024-06-16T10:30:00Z"
}
```

---

### 7️⃣ **Жауапты Тексеру**

```http
POST /api/tutor/check
Content-Type: application/json

{
  "question": "2 + 2 = ?",
  "correct_answer": "4",
  "student_answer": "4",
  "grade": 5
}
```

**Жауабы:**

```json
{
  "question": "2 + 2 = ?",
  "correct_answer": "4",
  "student_answer": "4",
  "is_correct": true,
  "feedback": "Жарайсың! 2 + 2 = 4 дұрыс!",
  "timestamp": "2024-06-16T10:30:00Z"
}
```

---

### 8️⃣ **Health Check**

```http
GET /api/health
```

**Жауабы:**

```json
{
  "status": "healthy",
  "timestamp": "2024-06-16T10:30:00Z",
  "uptime": 3600.123
}
```

---

## 🔒 Қауіпсіздік

1. **Балалар Қауіпсіздігі**: Барлық жауаптар тек білім беру тақырыптарында
2. **Rate Limiting**: 
   - Chat: 30 сұрау/минута
   - Voice: 15 сұрау/минута
   - Tutor: 20 сұрау/минута
3. **JWT Аутентификация** (опция)
4. **Контент Фильтр**: Қауіпсіздік сөздерін өлімдеу
5. **Файл Өлшемі**: Макс 10MB аудио

## 🎭 AI Кейіпкерлері

### **Бектұр** 🏃‍♂️
- Энергиялы, оптимист
- Спорттық рух
- Дауысы: `kk-KZ-DauletNeural` (ер)

### **Назым** 💙
- Мейірімді, сабырлы
- Қамқорлы апа түрінде
- Дауысы: `kk-KZ-AigulNeural` (әйел)

## 📂 Жоба құрылымы

```
qosqanat-api/
├── src/
│   ├── server.js                 # Express негізгі сервер
│   ├── config/
│   │   ├── env.js                # Айнымалыларды жүкте
│   │   └── constants.js          # Тұрақтылар
│   ├── routes/                   # Маршруттар
│   ├── controllers/              # Бизнес логикасы
│   ├── services/                 # AI, STT, TTS сервистері
│   ├── prompts/                  # Бектұр & Назым промттары
│   ├── middleware/               # Auth, rate limit, safety
│   ├── models/                   # Дерекқор схемалары
│   └── utils/                    # Утилиттар
├── .env.example
├── package.json
└── README.md
```

## 🧪 Тестеу (Postman)

1. **Мәтіндік чат**:
   ```
   POST http://localhost:3000/api/chat
   Body: { "grade": 8, "message": "Сәлем!" }
   ```

2. **Дауыстық чат**:
   ```
   POST http://localhost:3000/api/voice/chat
   Form-data: audio (file) + grade=8
   ```

3. **TTS**:
   ```
   POST http://localhost:3000/api/voice/tts
   Body: { "text": "Сәлем", "assistant_type": "bektur" }
   ```

## 📝 Жүйелік Промттар

### Бектұр (bektur.prompt.js)
```
Сен Бектұрсің — 14 жастағы қазақ баласы...
Энергиялы, оптимист, "кеттік!" деген рухта
```

### Назым (nazym.prompt.js)
```
Сен Назымсың — 14 жастағы қазақ қызы...
Мейірімді, сабырлы, қамқорлы апа
```

## 🚀 Production Өндіктеріңіз

- [ ] PostgreSQL/MongoDB дерекқорын түгендеңіз
- [ ] Redis кэшін қосыңыз
- [ ] JWT аутентификацияны іске асыңыз
- [ ] SSL/HTTPS орнатыңыз
- [ ] Environment айнымалыларын шифрлеңіз
- [ ] Rate limiting-ті арттырыңыз
- [ ] Логгингті құрыңыз (Winston, Morgan)
- [ ] Мониторингті қосыңыз (Sentry, DataDog)

## 🐛 Ақаулықтарды Шешу

**STT жұмыс істемеген**: OpenAI API кілтін тексеріңіз
**TTS қатесі**: Azure Speech регионын дұрыс түрде орнатыңыз
**AI жауап жоқ**: Anthropic/OpenAI кілттерін қосыңыз

## 📞 Қосымша

- **API Docs**: OpenAPI/Swagger (өндіру кезінде қосыңыз)
- **Telegram Bot**: Flutter мобиль қосымшасымен интеграция
- **WebSocket**: Real-time сұхбат (фазасы 2)

---

**Жасалды**: QosQanat Team  
**Тілі**: Node.js + Claude API  
**Мақсаты**: Қазақ балалар → AI Тьютор 🎓

Сәттіліктер! 🚀
