"""Curriculum-grounded RAG ұстаз — AI оқу бағдарламасына НЕГІЗДЕЛІП жауап береді.

Бұл «қаңсыз ChatGPT» емес: жауап QosQanat сабақтарынан алынады (қауіпсіз,
бағдарламаға сай, қазақша). Іздеу қозғалтқышы артықшылық ретімен:
  1) sentence-transformers (көп тілді семантикалық embeddings) — ең дәл;
  2) sklearn TF-IDF — жеңіл, әрқашан қолжетімді;
  3) кілт сөз қабаттасуы — тәуелсіз fallback (ауыр кітапханасыз да жұмыс істейді).
"""
from __future__ import annotations

import json
import re
from pathlib import Path

_TOKEN = re.compile(r"\w+", re.UNICODE)


def _tokenize(text: str):
    return _TOKEN.findall(text.lower())


class TutorService:
    def __init__(self, lessons_path: str) -> None:
        self.lessons = self._load(lessons_path)
        self._backend: str | None = None
        self._matrix = None
        self._embedder = None
        self._vectorizer = None

    @staticmethod
    def _load(path: str):
        p = Path(path)
        if not p.exists():
            return []
        with p.open(encoding="utf-8") as fh:
            return json.load(fh)

    @staticmethod
    def _doc_text(lesson: dict) -> str:
        return " ".join(
            v
            for v in (
                lesson.get("title", ""),
                lesson.get("intro", ""),
                lesson.get("formula", ""),
            )
            if v
        )

    def _ensure_index(self) -> None:
        if self._backend is not None or not self.lessons:
            return
        docs = [self._doc_text(lesson) for lesson in self.lessons]

        # 1) sentence-transformers (семантикалық)
        try:
            from sentence_transformers import SentenceTransformer

            self._embedder = SentenceTransformer(
                "paraphrase-multilingual-MiniLM-L12-v2"
            )
            self._matrix = self._embedder.encode(docs, normalize_embeddings=True)
            self._backend = "sbert"
            return
        except Exception:
            pass

        # 2) TF-IDF (жеңіл)
        try:
            from sklearn.feature_extraction.text import TfidfVectorizer

            self._vectorizer = TfidfVectorizer()
            self._matrix = self._vectorizer.fit_transform(docs)
            self._backend = "tfidf"
            return
        except Exception:
            pass

        # 3) кілт сөз
        self._backend = "keyword"

    def retrieve(self, question: str):
        self._ensure_index()
        if not self.lessons:
            return None, 0.0

        if self._backend == "sbert":
            query = self._embedder.encode([question], normalize_embeddings=True)[0]
            scores = self._matrix @ query
            idx = int(scores.argmax())
            return self.lessons[idx], float(scores[idx])

        if self._backend == "tfidf":
            from sklearn.metrics.pairwise import linear_kernel

            qv = self._vectorizer.transform([question])
            scores = linear_kernel(qv, self._matrix)[0]
            idx = int(scores.argmax())
            return self.lessons[idx], float(scores[idx])

        # keyword overlap
        q_tokens = set(_tokenize(question))
        best, best_score = None, 0.0
        for lesson in self.lessons:
            doc_tokens = set(_tokenize(self._doc_text(lesson)))
            if not doc_tokens:
                continue
            overlap = len(q_tokens & doc_tokens) / (len(q_tokens) + 1e-9)
            if overlap > best_score:
                best, best_score = lesson, overlap
        return best, best_score

    def ask(self, question: str, grade: int = 8) -> dict:
        lesson, score = self.retrieve(question)
        if lesson is None or score < 0.05:
            return {
                "answer": "Бұл тақырып бойынша сабақ таппадым. Сұрағыңды нақтыла 🦅",
                "source_title": None,
                "grounded": False,
                "score": float(score),
            }
        formula = f"\n\n📐 {lesson['formula']}" if lesson.get("formula") else ""
        answer = (
            f"«{lesson['title']}» туралы:\n\n{lesson.get('intro', '')}{formula}"
            "\n\nТолығырақ әрі жаттығу — Оқу картасынан осы тақырыпты аш 📚"
        )
        return {
            "answer": answer,
            "source_title": lesson["title"],
            "grounded": True,
            "score": float(score),
        }
