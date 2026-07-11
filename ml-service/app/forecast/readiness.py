"""Емтиханға дайындықты болжау — оқушы ағымдағы меңгеруі мен қарқынынан
«қашан дайын боласың» деп есептейді (оқу қисығы моделі).

Оқу қисығы: m(t) = 1 − (1 − m₀)·e^(−r·t). Бір тақырыпты target деңгейге
жеткізуге қанша күн керегін табамыз, бәрін біріктіріп дайындық индексін береміз.
"""
from __future__ import annotations

import numpy as np


class ReadinessForecaster:
    def __init__(self, learn_rate: float = 0.15) -> None:
        # Күніне бір тақырыпқа орташа меңгеру өсу қарқыны
        self.learn_rate = learn_rate

    def days_to_target(self, mastery: float, target: float = 0.8) -> float:
        """Бір тақырыпты target деңгейге жеткізуге қанша күн (болжам)."""
        if mastery >= target:
            return 0.0
        # m(t)=target шешімі: t = −ln((1−target)/(1−m₀)) / r
        ratio = (1.0 - target) / max(1e-6, 1.0 - mastery)
        return float(-np.log(max(ratio, 1e-6)) / self.learn_rate)

    def exam_readiness(self, mastery_vector, target: float = 0.8) -> dict:
        """Жалпы дайындық индексі + болжам."""
        m = np.asarray(mastery_vector, dtype=np.float64)
        if m.size == 0:
            return {"readiness": 0.0, "days_to_ready": None, "ready_topics": 0, "total": 0}

        ready = int((m >= target).sum())
        # Болжалды балл: ағымдағы орташа меңгеру (емтихан проксиі)
        projected_score = float(m.mean())
        # Бәрін target-қа жеткізу уақыты — ең баяу тақырып бойынша
        days = max(self.days_to_target(float(v), target) for v in m)

        return {
            "readiness": round(projected_score, 3),
            "ready_topics": ready,
            "total": int(m.size),
            "days_to_ready": round(days, 1),
            "weakest_eta_days": round(days, 1),
        }

    def trajectory(self, mastery: float, days: int = 30, target: float = 0.8):
        """Болашақ меңгеру қисығы (график үшін)."""
        t = np.arange(days + 1)
        m = 1.0 - (1.0 - mastery) * np.exp(-self.learn_rate * t)
        return [round(float(v), 3) for v in m]
