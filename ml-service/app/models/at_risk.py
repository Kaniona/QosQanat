"""Тәуекел болжамы — оқуды тастап кетуі/артта қалуы ықтимал оқушыларды ерте
анықтау (логистикалық регрессия). Мұғалім алдын ала араласа алады.

Белгілер: соңғы белсенділік азаюы, дәлдік төмендеуі (теріс тренд), сирек кіру.
sklearn болса — соны, болмаса таза NumPy логистикалық регрессия (graceful).
"""
from __future__ import annotations

import numpy as np


def _sigmoid(z):
    return 1.0 / (1.0 + np.exp(-np.clip(z, -30, 30)))


class AtRiskModel:
    def __init__(self) -> None:
        self.w = None
        self.b = 0.0
        self._impl = None

    def fit(self, x: np.ndarray, y: np.ndarray) -> "AtRiskModel":
        x = np.asarray(x, dtype=np.float64)
        y = np.asarray(y, dtype=np.float64)
        try:
            from sklearn.linear_model import LogisticRegression

            self._impl = LogisticRegression(max_iter=500).fit(x, y)
            return self
        except Exception:
            return self._fit_numpy(x, y)

    def _fit_numpy(self, x, y, epochs: int = 500, lr: float = 0.1, reg: float = 1e-3):
        n, f = x.shape
        self.w = np.zeros(f)
        self.b = 0.0
        for _ in range(epochs):
            p = _sigmoid(x @ self.w + self.b)
            err = p - y
            self.w -= lr * (x.T @ err / n + reg * self.w)
            self.b -= lr * err.mean()
        return self

    def predict_proba(self, x: np.ndarray) -> np.ndarray:
        x = np.asarray(x, dtype=np.float64)
        if self._impl is not None:
            return self._impl.predict_proba(x)[:, 1]
        return _sigmoid(x @ self.w + self.b)

    def at_risk(self, x: np.ndarray, threshold: float = 0.5):
        proba = self.predict_proba(x)
        return [
            {"index": int(i), "risk": float(p), "flag": bool(p >= threshold)}
            for i, p in enumerate(proba)
        ]
