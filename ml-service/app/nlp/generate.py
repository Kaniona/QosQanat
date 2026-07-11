"""Сұрақ генерациясы — сабақ мәтінінен автоматты тапсырма жасау.

Екі түр: (1) бос орын (cloze) — сөйлемнен мәнді сөзді алып тастау; (2) сұрақ-
дистрактор қаңқасы. Бұл — мазмұнды масштабтаудың (контент тереңдігі) AI жолы.
Мәтінді талдау NLP арқылы (sentence сегменттеу + кілт сөз).
"""
from __future__ import annotations

import re

_SENT = re.compile(r"[.!?…]+\s+")
_WORD = re.compile(r"\b[\w-]{4,}\b", re.UNICODE)

# Қазақ жалғаулықтары/көмекші сөздер (cloze кандидаты емес)
_STOP = {
    "және", "немесе", "бірақ", "сонда", "себебі", "үшін", "арқылы", "болады",
    "болып", "деген", "дегеніміз", "келесі", "мысалы", "сондай", "жатыр",
}


def _sentences(text: str):
    return [s.strip() for s in _SENT.split(text) if len(s.strip()) > 15]


def cloze_questions(lesson: dict, max_q: int = 3):
    """Сабақ интросынан бос орын сұрақтарын жасайды."""
    text = lesson.get("intro", "")
    out = []
    for sent in _sentences(text):
        candidates = [
            w for w in _WORD.findall(sent) if w.lower() not in _STOP
        ]
        if not candidates:
            continue
        # Ең ұзын (мәнді) сөзді жасырамыз
        answer = max(candidates, key=len)
        blanked = re.sub(rf"\b{re.escape(answer)}\b", "___", sent, count=1)
        if "___" not in blanked:
            continue
        out.append(
            {
                "type": "fill_blank",
                "text": blanked,
                "answer": answer,
                "source": lesson.get("title", ""),
            }
        )
        if len(out) >= max_q:
            break
    return out


def mcq_skeleton(lesson: dict, distractor_pool):
    """Сабақ тақырыбынан MCQ қаңқасы (дұрыс жауап + дистрактор кандидаттары)."""
    title = lesson.get("title", "")
    distractors = [d for d in distractor_pool if d != title][:3]
    return {
        "type": "multiple_choice",
        "text": f"«{title}» тақырыбы қай ұғымға жатады?",
        "answer": title,
        "distractors": distractors,
        "needs_review": True,  # мұғалім тексеруі ұсынылады
    }


def generate_for_lessons(lessons, max_per_lesson: int = 2):
    """Сабақтар тізімінен генерацияланған сұрақтар жинағы."""
    titles = [l.get("title", "") for l in lessons]
    questions = []
    for lesson in lessons:
        questions.extend(cloze_questions(lesson, max_q=max_per_lesson))
        questions.append(mcq_skeleton(lesson, titles))
    return questions
