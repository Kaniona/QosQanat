"""Оқушы симуляторы — RL ортасы үшін «виртуалды бала».

Әр тақырыптың меңгеру деңгейі (0..1) бар. Тақырыпты оқыту оны көтереді (алғы
шарттар орындалса тезірек); уақыт өте ұмыту (decay). Бұл — RL агенті оқу
ретін оңтайландыруды ҮЙРЕНЕТІН орта (нақты балаға тәуекелсіз).
"""
from __future__ import annotations

import numpy as np


class StudentSimulator:
    def __init__(
        self,
        num_skills: int,
        prereqs: dict | None = None,
        learn_rate: float = 0.25,
        decay: float = 0.02,
        seed: int = 0,
    ) -> None:
        self.num_skills = num_skills
        self.prereqs = prereqs or {}
        self.learn_rate = learn_rate
        self.decay = decay
        self.rng = np.random.default_rng(seed)
        self.mastery = np.zeros(num_skills, dtype=np.float64)

    def reset(self) -> np.ndarray:
        # Әртүрлі бастапқы қабілет (кейбірі дайын келеді)
        self.mastery = np.clip(self.rng.normal(0.1, 0.1, self.num_skills), 0.0, 1.0)
        return self.mastery.copy()

    def _prereq_factor(self, skill: int) -> float:
        """Алғы шарттар меңгерілмесе — үйрену баяу."""
        reqs = self.prereqs.get(skill, [])
        if not reqs:
            return 1.0
        return float(np.mean([self.mastery[r] for r in reqs]))

    def teach(self, skill: int) -> float:
        """Тақырыпты оқыту → меңгеру өсімін қайтарады."""
        before = self.mastery[skill]
        gain = self.learn_rate * self._prereq_factor(skill) * (1.0 - before)
        # Шу: үйрену әрқашан бірдей емес
        gain *= self.rng.uniform(0.7, 1.1)
        self.mastery[skill] = min(1.0, before + gain)
        # Ұмыту: қалғаны сәл төмендейді
        for s in range(self.num_skills):
            if s != skill:
                self.mastery[s] = max(0.0, self.mastery[s] - self.decay)
        return float(self.mastery[skill] - before)

    def answer(self, skill: int) -> int:
        """Сұраққа жауап (P дұрыс = меңгеру)."""
        return int(self.rng.random() < self.mastery[skill])

    def total_mastery(self) -> float:
        return float(self.mastery.mean())
