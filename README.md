# QosQanat — біріккен жоба (monorepo)

Бұрын екі бөлек қалтада жасалған QosQanat өнімінің **frontend** және
**backend** бөліктері бір репозиторийге біріктірілді.

```
qosqanat/
├── frontend/   Flutter қосымшасы (offline-first, геймификацияланған білім беру)
│               ← бұрынғы qosqanat_2_0
└── backend/    Node.js / Express AI Tutor API (Claude, voice STT/TTS, chat)
                ← бұрынғы QosQanatFable
```

## Frontend (Flutter)

Қазақстан мектеп оқушыларына (5–11 сынып) арналған геймификацияланған,
offline-first білім беру қосымшасы. Riverpod + go_router + Hive.

```bash
cd frontend
flutter pub get
flutter run            # қосымшаны іске қосу
flutter analyze        # статикалық талдау (қатесіз)
flutter test           # тесттер
```

Толық нұсқаулар: [`frontend/CLAUDE.md`](frontend/CLAUDE.md),
жол картасы: [`frontend/TASK.md`](frontend/TASK.md).

## Backend (Node.js API)

Дауыстық ассистент пен AI тьютордың proxy-сервері: Claude API, OpenAI,
Azure Speech (STT/TTS), чат, қауіпсіздік middleware-і.

```bash
cd backend
npm install
cp .env.example .env   # нақты API кілттерін енгізіңіз
npm run dev            # дамыту режимі (localhost:3000)
npm test               # тесттер
```

Толық нұсқаулар: [`backend/README.md`](backend/README.md),
API: [`backend/API_SPECIFICATION.md`](backend/API_SPECIFICATION.md).

## Архитектура (жоспар)

Flutter қосымшасы offline жұмыс істейді; жалғыз online мүмкіндік — AI
дауыстық ассистент, ол `backend/` API арқылы Claude-пен сөйлеседі.
API кілттері **ешқашан** қосымшаға енгізілмейді — барлық сұраулар backend
proxy арқылы өтеді (қараңыз: `frontend/TASK.md`, 2-бөлім).
