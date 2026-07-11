"""Меңгеру ансамблі — бірнеше білім-трекинг моделінің болжамын біріктіреді
(BKT + DKT/EMA + IRT), сенімдірек әрі калибрленген баға береді. Модельдер
келіспегенде сенімділік төмендейді (белгісіздікті көрсетеді).
"""
from __future__ import annotations

import numpy as np


class MasteryEnsemble:
    def __init__(self, weights: dict | None = None) -> None:
        # Әдепкі: BKT (түсіндірмелі) + EMA/DKT (динамикалы) тең салмақ
        self.weights = weights or {"bkt": 0.4, "dkt": 0.4, "irt": 0.2}

    def estimate(self, predictions: dict) -> dict:
        """predictions: {'bkt': p, 'dkt': p, 'irt': p} (бар болғаны)."""
        keys = [k for k in self.weights if k in predictions]
        if not keys:
            return {"mastery": 0.5, "confidence": 0.0, "sources": 0}

        w = np.array([self.weights[k] for k in keys], dtype=float)
        w = w / w.sum()
        p = np.array([float(predictions[k]) for k in keys], dtype=float)

        combined = float((w * p).sum())
        # Сенімділік: модельдер арасындағы келісім (дисперсия кері)
        spread = float(p.std()) if len(p) > 1 else 0.0
        confidence = float(np.clip(1.0 - 2.0 * spread, 0.0, 1.0))

        return {
            "mastery": round(combined, 4),
            "confidence": round(confidence, 4),
            "sources": len(keys),
            "agreement": round(1.0 - spread, 4),
        }

    def batch(self, prediction_list) -> list:
        return [self.estimate(p) for p in prediction_list]

    def calibrate(self, raw: float, temperature: float = 1.0) -> float:
        """Температуралық калибрация (артық сенімділікті тегістеу)."""
        logit = np.log(np.clip(raw, 1e-6, 1 - 1e-6) / np.clip(1 - raw, 1e-6, 1))
        return float(1.0 / (1.0 + np.exp(-logit / max(temperature, 1e-6))))
