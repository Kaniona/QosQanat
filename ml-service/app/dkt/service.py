"""DKT инференс қызметі — оқушы тарихынан меңгеру болжамы + ұсыныс.

Модель жаттықпаған болса — EMA эвристикасына ауысады (graceful), сонда API
әрқашан жұмыс істейді (қазіргі қосымша логикасымен бірдей).
"""
from __future__ import annotations

import os

import numpy as np


class DKTService:
    def __init__(self, model_path: str | None = None, num_skills: int = 98) -> None:
        self.model = None
        self.num_skills = num_skills
        if model_path and os.path.exists(model_path):
            from .model import load_checkpoint

            self.model = load_checkpoint(model_path)
            self.num_skills = self.model.num_skills

    @property
    def ready(self) -> bool:
        return self.model is not None

    def predict_mastery(self, interactions) -> np.ndarray:
        """interactions: list[(skill_idx, correct)] → (num_skills,) P(дұрыс)."""
        if not interactions:
            return np.full(self.num_skills, 0.5, dtype=np.float32)
        if self.model is None:
            return self._heuristic(interactions)

        import torch

        from .data import encode_sequence

        x, _, _, _ = encode_sequence(interactions, self.num_skills)
        xt = torch.from_numpy(x).unsqueeze(0)
        with torch.no_grad():
            mastery = self.model.mastery(xt)[0].cpu().numpy()
        return mastery

    def _heuristic(self, interactions) -> np.ndarray:
        """Модель жоқта — EMA (соңғы жауаптарға салмақ), қосымшамен үндес."""
        ema = np.full(self.num_skills, 0.5, dtype=np.float32)
        seen = np.zeros(self.num_skills, dtype=bool)
        alpha = 0.4
        for skill, correct in interactions:
            if skill < 0 or skill >= self.num_skills:
                continue
            if not seen[skill]:
                ema[skill] = float(correct)
                seen[skill] = True
            else:
                ema[skill] = ema[skill] * (1 - alpha) + correct * alpha
        return ema

    def recommend(self, interactions, candidate_skills=None, k: int = 3):
        """Ең әлсіз (төмен болжам) тақырыптарды ұсынады."""
        mastery = self.predict_mastery(interactions)
        pool = (
            list(candidate_skills)
            if candidate_skills is not None
            else list(range(self.num_skills))
        )
        pool = [i for i in pool if 0 <= i < self.num_skills]
        ranked = sorted(pool, key=lambda i: float(mastery[i]))
        return [(i, float(mastery[i])) for i in ranked[:k]]
