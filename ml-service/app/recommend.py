"""Адаптив рекомендер — келесі ең тиімді тапсырманы таңдайды.

Бірнеше сигналды біріктіреді (ансамбль):
  - меңгеру (DKT/BKT): әлсіз тұсқа басымдық;
  - қиындық (IRT): оқушы деңгейіне сай (тым жеңіл де, тым қиын да емес — «ағын»);
  - қайталау мерзімі (HLR): ұмытуға жақын тақырыпты алда;
  - жаңалық: әлі көрмеген тақырыпты енгізу.
Бұл — Vygotsky-дың «жақын даму аймағы» (ZPD) принципі.
"""
from __future__ import annotations

import numpy as np


def zpd_weight(prob_correct: float, target: float = 0.75, sharpness: float = 6.0) -> float:
    """«Ағын» салмағы: P(дұрыс) target маңында болса — ең жоғары (тым оңай/қиын
    емес). Гаусс тәрізді қисық."""
    return float(np.exp(-sharpness * (prob_correct - target) ** 2))


class AdaptiveRecommender:
    def __init__(
        self,
        w_mastery: float = 0.45,
        w_zpd: float = 0.25,
        w_spacing: float = 0.20,
        w_novelty: float = 0.10,
    ) -> None:
        self.w_mastery = w_mastery
        self.w_zpd = w_zpd
        self.w_spacing = w_spacing
        self.w_novelty = w_novelty

    def score(
        self,
        mastery: float,
        difficulty_match: float,
        due_ratio: float,
        seen: bool,
    ) -> float:
        """Бір тақырыптың ұсыныс ұпайы (жоғары = жақсырақ)."""
        weak = 1.0 - mastery  # әлсізге басымдық
        novelty = 0.0 if seen else 1.0
        return (
            self.w_mastery * weak
            + self.w_zpd * difficulty_match
            + self.w_spacing * np.clip(due_ratio, 0.0, 1.5)
            + self.w_novelty * novelty
        )

    def rank(self, candidates, top_k: int = 5):
        """candidates: list[dict(skill, mastery, prob_correct, due_ratio, seen)].

        Қайтарады: ұпай бойынша сұрыпталған [(skill, score), ...]."""
        scored = []
        for c in candidates:
            s = self.score(
                mastery=c.get("mastery", 0.5),
                difficulty_match=zpd_weight(c.get("prob_correct", c.get("mastery", 0.5))),
                due_ratio=c.get("due_ratio", 0.0),
                seen=c.get("seen", False),
            )
            scored.append((c["skill"], float(s)))
        scored.sort(key=lambda x: x[1], reverse=True)
        return scored[:top_k]
