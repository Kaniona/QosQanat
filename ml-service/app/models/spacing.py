"""Half-Life Regression (HLR) — Settles & Meeder, 2016 (Duolingo).

Жадының «жартылай ыдырау уақытын» (half-life) болжайды: бала тақырыпты қашан
ұмытатынын → ҚАШАН қайталау тиімді екенін есептейді. Бұл — қосымшаның қазіргі
SM-2 SRS-інің деректен үйренетін, дербес баламасы.

    h = 2^(θ·x)              — жартылай ыдырау уақыты (x — белгілер)
    p = 2^(−Δ / h)           — Δ уақыттан кейін еске түсіру ықтималдығы
"""
from __future__ import annotations

import numpy as np


class HalfLifeRegression:
    def __init__(self, n_features: int) -> None:
        self.theta = np.zeros(n_features, dtype=np.float64)
        self.h_min = 1.0 / 24.0  # 1 сағат (күнмен)
        self.h_max = 365.0

    def half_life(self, x: np.ndarray) -> np.ndarray:
        return np.clip(2.0 ** (x @ self.theta), self.h_min, self.h_max)

    def recall_prob(self, x: np.ndarray, delta: np.ndarray) -> np.ndarray:
        return np.power(2.0, -delta / self.half_life(x))

    def fit(
        self,
        x: np.ndarray,
        delta: np.ndarray,
        recall: np.ndarray,
        epochs: int = 300,
        lr: float = 0.01,
        alpha: float = 0.01,
    ) -> "HalfLifeRegression":
        """x: (N, F) белгілер; delta: (N,) уақыт; recall: (N,) 0/1 еске түсті ме."""
        x = np.asarray(x, dtype=np.float64)
        delta = np.asarray(delta, dtype=np.float64)
        recall = np.asarray(recall, dtype=np.float64)
        # Бақыланған half-life бағасы: ĥ = −Δ / log2(p), p≈recall (тегістелген)
        p_obs = np.clip(recall, 0.02, 0.98)
        h_obs = np.clip(-delta / np.log2(p_obs), self.h_min, self.h_max)

        for _ in range(epochs):
            h = self.half_life(x)
            p = np.power(2.0, -delta / h)
            ln2 = np.log(2.0)
            # dL/dθ = dL/dp · dp/dh · dh/dθ  +  α · half-life мүшесі
            dp = 2.0 * (p - recall)
            dp_dh = p * (delta / (h * h)) * ln2
            dh_dtheta = (h * ln2)[:, None] * x  # (N, F)
            grad_recall = (dp * dp_dh)[:, None] * dh_dtheta

            dh_term = 2.0 * (h - h_obs)
            grad_hl = (dh_term)[:, None] * dh_dtheta

            grad = grad_recall.mean(axis=0) + alpha * grad_hl.mean(axis=0)
            self.theta -= lr * grad
        return self

    def optimal_interval(self, x: np.ndarray, target_recall: float = 0.9) -> float:
        """Еске түсіру ықтималдығы target-қа тең болатын күтуді (күн) қайтарады."""
        h = float(self.half_life(np.atleast_2d(x))[0])
        return float(h * -np.log2(target_recall))


def review_features(n_correct: int, n_incorrect: int) -> np.ndarray:
    """Қарапайым HLR белгілері: [bias, √дұрыс, √қате]."""
    return np.array(
        [1.0, np.sqrt(max(n_correct, 0)), np.sqrt(max(n_incorrect, 0))],
        dtype=np.float64,
    )
