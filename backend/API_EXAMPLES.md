# QosQanat API — Сұрау Мысалдары

## cURL Мысалдары

### 1. Мәтіндік Чат

```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "student_123",
    "grade": 8,
    "subject": "Математика",
    "topic": "Теңдеулер",
    "message": "Теңдеуді қалай шешеу керек?",
    "assistant_type": "bektur"
  }'
```

---

### 2. Дауыстық Чат (Audio Upload)

```bash
curl -X POST http://localhost:3000/api/voice/chat \
  -H "Content-Type: multipart/form-data" \
  -F "audio=@audio.mp3" \
  -F "student_id=student_123" \
  -F "grade=8" \
  -F "subject=Қазақ тілі" \
  -F "topic=Сабақ" \
  -F "assistant_type=nazym"
```

---

### 3. STT (Speech to Text)

```bash
curl -X POST http://localhost:3000/api/voice/stt \
  -H "Content-Type: multipart/form-data" \
  -F "audio=@audio.mp3"
```

---

### 4. TTS (Text to Speech)

```bash
curl -X POST http://localhost:3000/api/voice/tts \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Сәлем, оқушы! Бүгін сабақ қайта шешейік.",
    "assistant_type": "bektur"
  }' \
  --output response.mp3
```

---

### 5. Тақырыпты Түсіндіру

```bash
curl -X POST http://localhost:3000/api/tutor/explain \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "Қуадрат теңдеулер",
    "grade": 9,
    "assistant_type": "nazym"
  }'
```

---

### 6. Кеңес Беру

```bash
curl -X POST http://localhost:3000/api/tutor/hint \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Периметр = 12 см, ұзындық = 4 см, ені = ?",
    "student_answer": "2 см",
    "grade": 5,
    "assistant_type": "bektur"
  }'
```

---

### 7. Жауапты Тексеру

```bash
curl -X POST http://localhost:3000/api/tutor/check \
  -H "Content-Type: application/json" \
  -d '{
    "question": "2 + 3 = ?",
    "correct_answer": "5",
    "student_answer": "5",
    "grade": 5
  }'
```

---

### 8. Health Check

```bash
curl http://localhost:3000/api/health
```

---

## Python Мысалы

```python
import requests
import json

BASE_URL = "http://localhost:3000"

# Мәтіндік чат
def send_message():
    data = {
        "student_id": "student_123",
        "grade": 8,
        "subject": "Математика",
        "topic": "Геометрия",
        "message": "Үшбұрыш дегеніміз не?",
        "assistant_type": "nazym"
    }
    
    response = requests.post(f"{BASE_URL}/api/chat", json=data)
    print(response.json())

# Дауыстық чат
def voice_chat(audio_path):
    with open(audio_path, 'rb') as f:
        files = {'audio': f}
        data = {
            "student_id": "student_123",
            "grade": 8,
            "subject": "Қазақ тілі",
            "topic": "Сабақ",
            "assistant_type": "bektur"
        }
        
        response = requests.post(f"{BASE_URL}/api/voice/chat", files=files, data=data)
        result = response.json()
        
        # Аудио жауапты сақта
        if 'reply_audio' in result:
            with open('response.mp3', 'wb') as audio_file:
                import base64
                audio_file.write(base64.b64decode(result['reply_audio']))

# TTS
def text_to_speech(text, assistant="bektur"):
    data = {
        "text": text,
        "assistant_type": assistant
    }
    
    response = requests.post(f"{BASE_URL}/api/voice/tts", json=data)
    
    if response.status_code == 200:
        with open(f'output_{assistant}.mp3', 'wb') as f:
            f.write(response.content)
        print(f"✅ Аудио сохранён: output_{assistant}.mp3")

if __name__ == "__main__":
    # Test
    send_message()
    text_to_speech("Сәлем! Мен Бектұрмын!", "bektur")
```

---

## JavaScript/Node.js Мысалы

```javascript
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

const BASE_URL = 'http://localhost:3000';

// Мәтіндік чат
async function sendMessage() {
  try {
    const response = await axios.post(`${BASE_URL}/api/chat`, {
      student_id: 'student_123',
      grade: 8,
      subject: 'Математика',
      topic: 'Теңдеулер',
      message: 'Теңдеуді шешу кезінде қандай қадамдар жасалмалы?',
      assistant_type: 'bektur'
    });
    
    console.log('AI жауабы:', response.data.reply);
  } catch (error) {
    console.error('Қата:', error.message);
  }
}

// Дауыстық чат
async function voiceChat(audioPath) {
  try {
    const form = new FormData();
    form.append('audio', fs.createReadStream(audioPath));
    form.append('student_id', 'student_123');
    form.append('grade', 8);
    form.append('subject', 'Қазақ тілі');
    form.append('assistant_type', 'nazym');
    
    const response = await axios.post(
      `${BASE_URL}/api/voice/chat`,
      form,
      { headers: form.getHeaders() }
    );
    
    console.log('Транскрипция:', response.data.transcript);
    console.log('Жауап:', response.data.reply_text);
    
    // Аудио жауапты сақта
    if (response.data.reply_audio) {
      const buffer = Buffer.from(response.data.reply_audio, 'base64');
      fs.writeFileSync('response.mp3', buffer);
    }
  } catch (error) {
    console.error('Қата:', error.message);
  }
}

// TTS
async function textToSpeech(text, assistantType = 'bektur') {
  try {
    const response = await axios.post(
      `${BASE_URL}/api/voice/tts`,
      {
        text,
        assistant_type: assistantType
      },
      { responseType: 'arraybuffer' }
    );
    
    fs.writeFileSync(`output_${assistantType}.mp3`, response.data);
    console.log(`✅ Аудио сохранён: output_${assistantType}.mp3`);
  } catch (error) {
    console.error('Қата:', error.message);
  }
}

// Test
(async () => {
  await sendMessage();
  await textToSpeech('Сәлем! Қалайсың?', 'bektur');
})();
```

---

## Postman Collection (JSON)

Файлдарды `postman_collection.json` ретінде экспорттау:

```json
{
  "info": {
    "name": "QosQanat API",
    "description": "AI Tutor API for Kazakh Students"
  },
  "item": [
    {
      "name": "Chat",
      "request": {
        "method": "POST",
        "url": "{{base_url}}/api/chat",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\"student_id\": \"student_123\", \"grade\": 8, \"subject\": \"Математика\", \"message\": \"Помощь!\", \"assistant_type\": \"bektur\"}"
        }
      }
    },
    {
      "name": "Voice Chat",
      "request": {
        "method": "POST",
        "url": "{{base_url}}/api/voice/chat",
        "body": {
          "mode": "formdata",
          "formdata": [
            {
              "key": "audio",
              "type": "file",
              "src": "audio.mp3"
            },
            {
              "key": "grade",
              "value": "8"
            },
            {
              "key": "assistant_type",
              "value": "nazym"
            }
          ]
        }
      }
    }
  ]
}
```

---

## flutter Интеграция (Dart)

```dart
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class QosQanatAPI {
  final String baseUrl = 'http://localhost:3000';
  final Dio dio = Dio();
  
  // Мәтіндік чат
  Future<String> sendMessage({
    required String studentId,
    required int grade,
    required String message,
    String assistantType = 'bektur',
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/chat',
        data: {
          'student_id': studentId,
          'grade': grade,
          'subject': 'Қазақ тілі',
          'message': message,
          'assistant_type': assistantType,
        },
      );
      
      return response.data['reply'];
    } catch (e) {
      throw Exception('Қата: $e');
    }
  }
  
  // Дауыстық чат
  Future<Map> voiceChat({
    required String audioPath,
    required String studentId,
    required int grade,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioPath),
        'student_id': studentId,
        'grade': grade,
        'assistant_type': 'nazym',
      });
      
      final response = await dio.post(
        '$baseUrl/api/voice/chat',
        data: formData,
      );
      
      return response.data;
    } catch (e) {
      throw Exception('Қата: $e');
    }
  }
}
```

---

## Environment Айнымалылары

```bash
# .env
BASE_URL=http://localhost:3000
STUDENT_ID=student_123
GRADE=8
SUBJECT=Математика
ASSISTANT_TYPE=bektur
```

---

Барлық мысалдары тіл және инструменты сайын келтірілген! ✨
