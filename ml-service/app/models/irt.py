"""Item Response Theory (IRT) — психометрия. 2PL моделі сұрақтың ҚИЫНДЫҒЫ (b)
мен АЖЫРАТУ қабілетін (a) әрі оқушының ҚАБІЛЕТІН (θ) бір уақытта бағалайды:

    P(дұрыс | θ, a, b) = σ(a·(θ − b))

Қолданысы: сұрақтардың нақты қиындығын деректен табу (қолмен қойған «Жеңіл/
Қиын» орнына), оқушыны дұрыс деңгейге орналастыру (адаптив іріктеу).
"""
from __future__ import annotations

import numpy as np


def _sigmoid(x: np.ndarray) -> np.ndarray:
    return 1.0 / (1.0 + np.exp(-np.clip(x, -30, 30)))


class IRT2PL:
    def __init__(self, n_students: int, n_items: int) -> None:
        self.theta = np.zeros(n_students, dtype=np.float64)
        self.a = np.ones(n_items, dtype=np.float64)
        self.b = np.zeros(n_items, dtype=np.float64)

    def prob(self, student: int, item: int) -> float:
        return float(_sigmoid(self.a[item] * (self.theta[student] - self.b[item])))

    def fit(
        self,
        responses,
        epochs: int = 200,
        lr: float = 0.05,
        reg: float = 1e-3,
    ) -> "IRT2PL":
        """responses: (student, item, correct) үштіктерінің тізімі.

        MLE — градиенттік көтерілу (θ, a, b бір уақытта жаңарады).
        """
        s = np.asarray([r[0] for r in responses], dtype=np.int64)
        it = np.asarray([r[1] for r in responses], dtype=np.int64)
        y = np.asarray([r[2] for r in responses], dtype=np.float64)

        for _ in range(epochs):
            z = self.a[it] * (self.theta[s] - self.b[it])
            p = _sigmoid(z)
            err = y - p  # (N,)

            # Градиенттер (теріс лог-сенімділіктің)
            g_theta = self.a[it] * err
            g_b = -self.a[it] * err
            g_a = (self.theta[s] - self.b[it]) * err

            # Жинақтау (np.add.at — қайталанатын индекстер)
            d_theta = np.zeros_like(self.theta)
            d_a = np.zeros_like(self.a)
            d_b = np.zeros_like(self.b)
            np.add.at(d_theta, s, g_theta)
            np.add.at(d_a, it, g_a)
            np.add.at(d_b, it, g_b)

            self.theta += lr * (d_theta - reg * self.theta)
            self.a += lr * (d_a - reg * (self.a - 1.0))
            self.b += lr * (d_b - reg * self.b)
            self.a = np.clip(self.a, 0.2, 4.0)
            self.theta = np.clip(self.theta, -4.0, 4.0)
            self.b = np.clip(self.b, -4.0, 4.0)

        return self

    def item_difficulty(self) -> np.ndarray:
        """Сұрақтардың бағаланған қиындығы (b)."""
        return self.b.copy()

    def ability(self) -> np.ndarray:
        """Оқушылардың бағаланған қабілеті (θ)."""
        return self.theta.copy()

    def log_likelihood(self, responses) -> float:
        ll = 0.0
        for st, item, y in responses:
            p = self.prob(st, item)
            p = min(max(p, 1e-9), 1 - 1e-9)
            ll += y * np.log(p) + (1 - y) * np.log(1 - p)
        return float(ll)
