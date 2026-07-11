# QosQanat ML Service 🧠

Білім беруге арналған **нақты қолданбалы AI** микросервисі (Python, PyTorch).
Бұл — «нөлден ChatGPT» емес (ол миллиондаған доллар + мыңдаған GPU керек), бірақ
адаптив оқытуға одан да құнды, зерттеу деңгейіндегі екі модель:

## 1. Deep Knowledge Tracing (DKT) — PyTorch
Оқушының жауап тізбегін LSTM арқылы оқып, **әр тақырып бойынша «келесіде дұрыс
жауап беру ықтималдығын»** болжайды (Piech et al., 2015). Бұл — қосымшаның қазіргі
EMA эвристикасының күшті баламасы: «бала нені ұмытып барады, нені бекітті».

- `app/dkt/model.py` — LSTM моделі
- `app/dkt/data.py` — NumPy/Pandas кодтау + жасанды дерек генераторы
- `app/dkt/train.py` — жаттықтыру (маскаланған BCE + AUC)
- `app/dkt/service.py` — инференс (модель жоқта EMA-ға graceful ауысады)

## 2. Curriculum-grounded RAG ұстаз — Transformers + LangChain
AI **QosQanат сабақтарына негізделіп** жауап береді (қаңсыз ChatGPT емес —
бағдарламаға сай, қауіпсіз, қазақша). 3 деңгейлі іздеу: sentence-transformers →
sklearn TF-IDF → кілт сөз (ауыр кітапханасыз да жұмыс істейді).

- `app/tutor/rag.py` — RAG қозғалтқышы
- `app/data/lessons.sample.json` — сабақ корпусы (толығы content API-ден синхрондалады)

## Қосымшамен байланысы
**Offline-first бұзылмайды.** Бұл сервис — БОНУС: онлайн болғанда қосымша
DKT болжамын/семантикалық ұстазды қолданады; болмаса өзінің офлайн логикасымен
(EMA + кілт сөз) жұмыс істей береді.

## Іске қосу
```bash
pip install -r requirements.txt

# (қалауыңша) DKT-ні жаттықтыру — жасанды дерекпен демо:
python -m app.dkt.train --skills 98 --students 4000 --epochs 12 --out model.pt
# нақты дерекпен:
python -m app.dkt.train --csv answers.csv --out model.pt

# API:
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Тест:
pytest -q
```

## Эндпоинттер
| Метод | Жол | Сипаттама |
|---|---|---|
| GET | `/health` | күй (модель дайын ба) |
| POST | `/dkt/predict` | тарихтан меңгеру болжамы + әлсіз тақырыптар |
| POST | `/tutor/ask` | бағдарламаға негізделген AI жауап |

## Нені сіз бересіз (өндіріске)
- **GPU + нақты жауап журналы** (`student_id, skill_id, correct, timestamp`) — DKT-ні
  шынайы баптау үшін (жасанды дерек тек демо).
- Деплой (Docker) + Node backend-пен жалғау.
