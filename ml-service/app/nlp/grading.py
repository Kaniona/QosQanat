"""Ашық жауапты автоматты бағалау — бала ЕРКІН мәтінмен жауап берсе (тек MCQ
емес), оны дұрыс жауаппен семантикалық салыстырады.

Деңгейлер: sentence-transformers (мағыналық) → таза мәтін ұқсастығы (difflib +
токен қабаттасуы, тәуелсіз). Қазақ тіліне де жарайды.
"""
from __future__ import annotations

import re
from difflib import SequenceMatcher

_WORD = re.compile(r"\w+", re.UNICODE)


def _normalize(text: str) -> str:
    return " ".join(_WORD.findall(text.lower()))


def _tokens(text: str):
    return set(_WORD.findall(text.lower()))


class AnswerGrader:
    def __init__(self) -> None:
        self._embedder = None
        self._tried = False

    def _embed_sim(self, a: str, b: str):
        if not self._tried:
            self._tried = True
            try:
                from sentence_transformers import SentenceTransformer, util

                self._embedder = SentenceTransformer(
                    "paraphrase-multilingual-MiniLM-L12-v2"
                )
                self._util = util
            except Exception:
                self._embedder = None
        if self._embedder is None:
            return None
        emb = self._embedder.encode([a, b], normalize_embeddings=True)
        return float(self._util.cos_sim(emb[0], emb[1]))

    def similarity(self, student: str, correct: str) -> float:
        sem = self._embed_sim(student, correct)
        if sem is not None:
            return max(0.0, min(1.0, sem))
        # Fallback: токен Jaccard + реттік ұқсастық орташасы
        st, ct = _tokens(student), _tokens(correct)
        jacc = len(st & ct) / len(st | ct) if (st | ct) else 0.0
        seq = SequenceMatcher(None, _normalize(student), _normalize(correct)).ratio()
        return 0.5 * jacc + 0.5 * seq

    def grade(self, student: str, correct: str, accept: float = 0.7) -> dict:
        score = self.similarity(student, correct)
        if score >= accept:
            verdict = "correct"
        elif score >= 0.4:
            verdict = "partial"
        else:
            verdict = "incorrect"
        return {
            "score": round(score, 3),
            "verdict": verdict,
            "feedback": _feedback(verdict),
        }


def _feedback(verdict: str) -> str:
    return {
        "correct": "Дұрыс! Жарайсың 🎉",
        "partial": "Жартылай дұрыс — нақтыла, негізгі ойды толықтыр.",
        "incorrect": "Қайта ойлан. Дұрыс жауапты сабақтан қарап шық 📚",
    }[verdict]
