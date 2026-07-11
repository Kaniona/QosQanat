"""Бүкіл ML стегін жасанды деректе көрсету (torch қажет емес — numpy ғана).

    python -m app.demo

BKT/IRT/HLR/сегменттеу/рекомендерді жаттықтырып, метрикаларды басады.
"""
from __future__ import annotations

import numpy as np

from .eval.metrics import evaluate_all
from .models.bkt import BKT
from .models.irt import IRT2PL
from .models.segment import StudentSegmenter
from .models.spacing import HalfLifeRegression
from .recommend import AdaptiveRecommender


def demo_bkt(seed: int = 0):
    rng = np.random.default_rng(seed)
    # «Шынайы» BKT параметрлерімен бір тақырыптың тізбектерін генерациялаймыз
    true = dict(p_init=0.1, p_learn=0.25, p_guess=0.2, p_slip=0.1)
    sequences = []
    for _ in range(400):
        known = rng.random() < true["p_init"]
        seq = []
        for _ in range(rng.integers(8, 20)):
            if known:
                correct = rng.random() > true["p_slip"]
            else:
                correct = rng.random() < true["p_guess"]
                if rng.random() < true["p_learn"]:
                    known = True
            seq.append(int(correct))
        sequences.append(seq)

    model = BKT().fit(sequences, iterations=40)
    # Болжам сапасы: t қадамға дейінгі тарихтан t-ны болжау
    y, p = [], []
    for seq in sequences:
        for t in range(1, len(seq)):
            p.append(model.predict_next_correct(seq[:t]))
            y.append(seq[t])
    print("BKT   params:", {k: round(v, 3) for k, v in model.params().items()})
    print("BKT   metrics:", {k: round(v, 3) for k, v in evaluate_all(y, p).items()})


def demo_irt(seed: int = 0):
    rng = np.random.default_rng(seed)
    n_students, n_items = 300, 60
    true_theta = rng.normal(0, 1, n_students)
    true_b = rng.normal(0, 1, n_items)
    responses = []
    for s in range(n_students):
        for i in rng.choice(n_items, size=25, replace=False):
            p = 1 / (1 + np.exp(-(true_theta[s] - true_b[i])))
            responses.append((s, int(i), int(rng.random() < p)))

    model = IRT2PL(n_students, n_items).fit(responses, epochs=300, lr=0.03)
    corr = float(np.corrcoef(model.item_difficulty(), true_b)[0, 1])
    print(f"IRT   difficulty recovery corr: {corr:.3f}  (1.0 = мінсіз)")


def demo_hlr(seed: int = 0):
    rng = np.random.default_rng(seed)
    true_theta = np.array([0.4, 1.1, -0.7])
    n = 2000
    x = np.column_stack(
        [np.ones(n), np.sqrt(rng.integers(0, 8, n)), np.sqrt(rng.integers(0, 4, n))]
    )
    h = np.clip(2.0 ** (x @ true_theta), 1 / 24, 365)
    delta = rng.uniform(0.1, 10, n)
    p = np.power(2.0, -delta / h)
    recall = (rng.random(n) < p).astype(float)

    model = HalfLifeRegression(3).fit(x, delta, recall, epochs=400, lr=0.02)
    print("HLR   theta (true [0.4,1.1,-0.7]):", [round(v, 2) for v in model.theta])
    print("HLR   optimal interval [3 correct]:",
          round(model.optimal_interval(np.array([1, np.sqrt(3), 0])), 2), "күн")


def demo_recommender():
    rec = AdaptiveRecommender()
    cands = [
        {"skill": 0, "mastery": 0.2, "prob_correct": 0.3, "due_ratio": 0.1, "seen": True},
        {"skill": 1, "mastery": 0.5, "prob_correct": 0.75, "due_ratio": 1.0, "seen": True},
        {"skill": 2, "mastery": 0.9, "prob_correct": 0.95, "due_ratio": 0.0, "seen": True},
        {"skill": 3, "mastery": 0.5, "prob_correct": 0.5, "due_ratio": 0.0, "seen": False},
    ]
    print("REC   ranked:", rec.rank(cands, top_k=3))


def demo_segment(seed: int = 0):
    rng = np.random.default_rng(seed)
    x = np.vstack([
        rng.normal([5, 0.9, 10], 0.3, (40, 3)),
        rng.normal([3, 0.6, 6], 0.3, (40, 3)),
        rng.normal([1, 0.3, 3], 0.3, (40, 3)),
    ])
    seg = StudentSegmenter(n_clusters=3, seed=seed).fit(x)
    labels = seg.describe(accuracy_idx=1)
    print("SEG   3 топ табылды, мысал белгілер:", labels[:3], "...", labels[-3:])


def main():
    print("=== QosQanat ML стегі (жасанды дерек) ===")
    demo_bkt()
    demo_irt()
    demo_hlr()
    demo_recommender()
    demo_segment()
    print("✅ Барлық модель жұмыс істейді.")


if __name__ == "__main__":
    main()
