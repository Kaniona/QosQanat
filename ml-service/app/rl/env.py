"""Оқу жолын оңтайландыру ортасы (Gymnasium үлгісі).

State — меңгеру векторы; Action — келесі оқытылатын тақырып; Reward — меңгеру
өсімі (+ тақырып «бекіді» табалдырығынан өткенде бонус). Агент шектеулі
қадамда МАКСИМАЛ меңгеруге жеткізуді үйренеді (Stable-Baselines3/RLlib осы
интерфейске оңай жалғанады).
"""
from __future__ import annotations

import numpy as np

from .student_sim import StudentSimulator


class CurriculumEnv:
    """Gymnasium-үйлесімді минималды интерфейс (reset/step)."""

    def __init__(
        self,
        num_skills: int = 10,
        horizon: int = 60,
        prereqs: dict | None = None,
        seed: int = 0,
    ) -> None:
        self.num_skills = num_skills
        self.horizon = horizon
        self.sim = StudentSimulator(num_skills, prereqs=prereqs, seed=seed)
        self.t = 0

        # Gym-стиль кеңістіктер (сипаттама ретінде)
        self.observation_dim = num_skills
        self.action_dim = num_skills

    def reset(self):
        self.t = 0
        obs = self.sim.reset()
        return obs, {}

    def step(self, action: int):
        action = int(action) % self.num_skills
        before_total = self.sim.total_mastery()
        crossed_before = self.sim.mastery[action] >= 0.8
        self.sim.teach(action)
        crossed_after = self.sim.mastery[action] >= 0.8

        reward = (self.sim.total_mastery() - before_total) * self.num_skills
        if crossed_after and not crossed_before:
            reward += 1.0  # тақырып «бекіді» — бонус

        self.t += 1
        terminated = bool(self.sim.mastery.min() >= 0.8)  # бәрі меңгерілді
        truncated = self.t >= self.horizon
        obs = self.sim.mastery.copy()
        info = {"total_mastery": self.sim.total_mastery()}
        return obs, float(reward), terminated, truncated, info
