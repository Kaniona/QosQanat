# AI-ды қосымшада қалай қолданамын 🔌

QosQanat offline-first болғандықтан, ML сервис — **БОНУС қабат**: онлайн болса AI
күштірек, болмаса қосымша өзінің офлайн логикасымен жұмыс істей береді.

## 1. ML сервисті іске қосу (сізде/серверде)
```bash
cd ml-service
pip install -r requirements.txt
# (қалауыңша) DKT-ні баптау:
python -m app.dkt.train --skills 98 --students 4000 --out model.pt
# Сервер:
uvicorn app.main:app --host 0.0.0.0 --port 8000
# немесе Docker:
docker build -t qosqanat-ml . && docker run -p 8000:8000 qosqanat-ml
```

## 2. Қосымшаны ML-ге қосу (бір жол)
```bash
flutter run --dart-define=QOSQANAT_ML_URL=https://ml.qosqanat.kz
```
URL берілсе — қосымша AI-ды автоматты қолданады; берілмесе — офлайн (ешнәрсе бұзылмайды).

## 3. Қосымшаның қай жері AI-ды қолданады (қазір жалғанған)
| Қосымша | ML эндпоинт | Не береді |
|---|---|---|
| **AI ассистент** (Бектұр/Назым) | `POST /tutor/ask` | RAG — оқу бағдарламасына негізделген семантикалық жауап |
| `MlService.readiness()` | `POST /forecast/readiness` | «Емтиханға ~12 күнде дайын боласың» |
| `MlService.spacingInterval()` | `POST /spacing/interval` | HLR — оптималды қайталау мерзімі |
| `MlService.gradeAnswer()` | `POST /nlp/grade` | Ашық жауапты семантикалық бағалау |
| `MlService.predictMastery()` | `POST /dkt/predict` | DKT — меңгеру болжамы + әлсіз тақырып |

Код: `frontend/lib/services/ml_service.dart` (клиент) + `assistant_service.dart`
(ML RAG ұстазын Claude→ML→офлайн ретімен қолданады). Бәрі `try/catch` + timeout —
қате болса үнсіз офлайнға ауысады.

## 4. Архитектура (ағын)
```
Қосымша (offline-first)
  └─ онлайн болса → MlService → ML микросервис (FastAPI)
                                   ├─ DKT/SAKT/DKVMN/BKT  (меңгеру болжамы)
                                   ├─ IRT                 (сұрақ қиындығы)
                                   ├─ HLR                 (қайталау мерзімі)
                                   ├─ RL агент            (оқу реті)
                                   ├─ RAG ұстаз           (Transformers + LangChain)
                                   └─ болжау/NLP/сегмент  (аналитика)
  └─ офлайн → құрылғыдағы логика (EMA + SM-2 + кілт сөз)
```

## 5. Сізден керек (өндіріске)
1. **Деплой** — ML сервисті серверге (Docker дайын).
2. **Нақты дерек** — оқушы жауап журналы (`student_id, skill_id, correct, timestamp`)
   → DKT/RL-ді шынайы баптауға (қазір жасанды дерек тек демо).
3. **(қаласаңыз) GPU** — SAKT/DKVMN/LLM-LoRA жаттықтыруға.
