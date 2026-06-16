# QosQanat API — Орнату Нұсқалығы

## ⚡ Тез Бастау (5 минут)

### Қадам 1: Зависимостерді орнат

```bash
cd ~/Documents/QosQanatFable
npm install
```

### Қадам 2: .env файлын құр

```bash
cp .env.example .env
```

### Қадам 3: API кілттерін толтыр

`.env` файлын өзінің редактормен ашыңыз және төмендегілерді толтырыңыз:

```env
# Anthropic (Claude)
ANTHROPIC_API_KEY=sk-ant-...ваше_ключ...

# OpenAI (Whisper STT)
OPENAI_API_KEY=sk-...ваше_ключ...

# Azure Speech (TTS)
AZURE_SPEECH_KEY=...ваше_ключ...
AZURE_SPEECH_REGION=eastus
```

### Қадам 4: Серверді іске қос

```bash
npm run dev
```

Сервер жүріп барады:
```
🚀 QosQanat API сервері 3000 портында ұйымдастырылды
```

### Қадам 5: Тестеу

```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"grade": 8, "message": "Сәлем!", "assistant_type": "bektur"}'
```

✅ Болды!

---

## 🔧 API Кілттері қайсысынан алуға болады?

### 1. Anthropic API Key (Claude)

1. https://console.anthropic.com/ қатысыңыз
2. "API Keys" бөліміне өтіңіз
3. "Create Key" басыңыз
4. Кілтін көшіңіз

```
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

---

### 2. OpenAI API Key (Whisper STT)

1. https://platform.openai.com/api/keys қатысыңыз
2. "Create new secret key" басыңыз
3. Кілтін көшіңіз

```
OPENAI_API_KEY=sk-proj-xxxxx
```

---

### 3. Azure Speech Key (TTS)

1. https://azure.microsoft.com/en-us/ қатысыңыз
2. "Create a resource" басыңыз
3. "Speech" іздеңіз
4. "Create" басыңыз
5. Resource құрылғаннан кейін "Keys and Endpoint" өтіңіз

```
AZURE_SPEECH_KEY=xxxxxxxxxxxx
AZURE_SPEECH_REGION=eastus
```

---

## 📦 Техникалық Талабы

- **Node.js**: 16+ версиясы
- **npm**: 7+
- **Интернет қосылысы** (API сервистеріне)

---

## 🎯 Файл Құрылымы

Құрылсоттан кейін:

```
qosqanat-api/
├── src/
│   ├── server.js                 # Express сервері
│   ├── config/                   # Баптау файлдары
│   │   ├── env.js               # Айнымалылар
│   │   └── constants.js         # Тұрақтылар
│   ├── routes/                  # API маршруттары
│   │   ├── chat.routes.js
│   │   ├── voice.routes.js
│   │   ├── tutor.routes.js
│   │   └── health.routes.js
│   ├── controllers/             # Логика
│   │   ├── chat.controller.js
│   │   ├── voice.controller.js
│   │   └── tutor.controller.js
│   ├── services/                # Сервистер (AI, STT, TTS)
│   │   ├── ai.service.js
│   │   ├── stt.service.js
│   │   ├── tts.service.js
│   │   ├── context.service.js
│   │   └── memory.service.js
│   ├── prompts/                 # AI персоналиялары
│   │   ├── bektur.prompt.js
│   │   └── nazym.prompt.js
│   ├── middleware/              # Орындалдың фильтрлері
│   │   ├── auth.middleware.js
│   │   ├── rateLimit.middleware.js
│   │   ├── safety.middleware.js
│   │   └── errorHandler.middleware.js
│   ├── models/                  # Дерекқор моделі
│   │   ├── conversation.model.js
│   │   └── student.model.js
│   └── utils/                   # Пайдалы функциялар
│       ├── logger.js
│       └── audioConverter.js
├── .env.example                 # Үлгі env файл
├── .env                         # Қауіпсіздік! .gitignore-де
├── .gitignore
├── package.json
├── README.md
├── SETUP.md (бұл файл)
└── API_EXAMPLES.md
```

---

## 🧪 Тестеу Құралдары

### Postman Қолдану

1. Postman жүктеңіз: https://www.postman.com/downloads/
2. `API_EXAMPLES.md` ішінегі мысалдарды көшіңіз
3. Сұрауларды іске қосыңыз

### cURL Қолдану (Terminal)

```bash
# Мәтіндік чат тестеу
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "test_123",
    "grade": 8,
    "message": "Сәлем!",
    "assistant_type": "bektur"
  }'
```

### Node.js Скрипт

`test.js` файлын құрыңыз:

```javascript
import axios from 'axios';

async function test() {
  try {
    const response = await axios.post('http://localhost:3000/api/chat', {
      student_id: 'test_123',
      grade: 8,
      message: 'Сәлем!',
      assistant_type: 'bektur'
    });
    
    console.log('✅ Жауап:', response.data.reply);
  } catch (error) {
    console.error('❌ Қата:', error.message);
  }
}

test();
```

Іске қос:
```bash
node test.js
```

---

## 🔍 Ақаулықтарды Шешу

### Қата: "ANTHROPIC_API_KEY қажет"

**Құрылық**: `.env` файлында `ANTHROPIC_API_KEY` орнатылмады

**Шешу**:
```bash
# .env файлын ашыңыз
nano .env
```

Төмендегі сызықтарды табыңыз:
```
ANTHROPIC_API_KEY=your_key_here
```

Сізің кілтіңізді ауыстырыңыз:
```
ANTHROPIC_API_KEY=sk-ant-abc123xyz456
```

---

### Қата: "Port 3000 already in use"

**Құрылық**: Басқа процесс 3000 портында орындалып жатыр

**Шешу**:

```bash
# Басқа портты ұрындап алыңыз
PORT=3001 npm run dev
```

Немесе әрәйлі портты өлтіру:

```bash
# 3000 портын табыңыз
lsof -i :3000

# Процессін өлтіріңіз
kill -9 <PID>
```

---

### Қата: "OpenAI API Error"

**Құрылық**: STT қызметі қатасы

**Шешу**:
1. `OPENAI_API_KEY` дұрыс е-ді тексеріңіз
2. API лимиті бітіп кетпегені тексеріңіз
3. Аудио файлы < 25MB

---

### Қата: "Azure Speech Error"

**Құрылық**: TTS қызметі қатасы

**Шешу**:
1. `AZURE_SPEECH_KEY` және `AZURE_SPEECH_REGION` дұрыс ә-ді тексеріңіз
2. Azure Portal-да қызметі іске құйғаныңыз тексеріңіз
3. Регион дұрыс (мысалы `eastus` немесе `westeurope`)

---

## 🚀 Development vs Production

### Development режімінде

```bash
npm run dev
```

- Hot reload (код өзгергенде автоматты қос)
- Толық логгинг
- Түсіндіргіш ошибкалар

### Production режімінде

```bash
npm start
```

Немесе `package.json` туралығын өзгертіңіз:

```json
{
  "scripts": {
    "start": "NODE_ENV=production node src/server.js"
  }
}
```

Жүргіңіз:
```bash
npm start
```

---

## 📚 Қосымша Ресурстар

- [Node.js Құжаттамасы](https://nodejs.org/docs)
- [Express.js](https://expressjs.com)
- [Anthropic Claude API](https://docs.anthropic.com)
- [OpenAI Whisper](https://openai.com/research/whisper)
- [Azure Speech Services](https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service)

---

## 🆘 Көмек Керек ме?

1. `README.md` қараңыз — толық құжаттама
2. `API_EXAMPLES.md` қараңыз — сұрау мысалдары
3. GitHub Issues ашыңыз
4. Teams-та сұрау қойыңыз

---

**Ұсынысты тіршілік бастап тұрсыңыз!** 🎓✨

Келесі қадамдар (өндіктеге кісік):
- [ ] PostgreSQL дерекқорын орнатыңыз
- [ ] Redis кэшін орнатыңыз
- [ ] Docker контейнері жасаңыз
- [ ] CI/CD pipeline құрыңыз
- [ ] Unit тесттерін жазыңыз
- [ ] API документациясын Swagger-де жасаңыз
