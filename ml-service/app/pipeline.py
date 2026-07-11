"""Оқыту құбыры (MLOps оркестрациясы) — дерек → жаттығу → бағалау → тізілім.

Бір команда: деректі дайындайды, BKT/IRT моделін жаттықтырады, метрикасын
есептеп, модель тізіліміне нұсқа ретінде тіркейді. Бұл — қайталанатын,
қадағаланатын ML процесі (өндіріске дайын).
"""
from __future__ import annotations

import time

import numpy as np

from .eval.metrics import evaluate_all
from .mlops.registry import ModelRegistry
from .models.bkt import BKT


def _synthetic_skill_sequences(num_seqs: int, seed: int = 0):
    """Бір тақырыптың жасанды жауап тізбектері (BKT үшін)."""
    rng = np.random.default_rng(seed)
    true = dict(p_init=0.1, p_learn=0.25, p_guess=0.2, p_slip=0.1)
    seqs = []
    for _ in range(num_seqs):
        known = rng.random() < true["p_init"]
        seq = []
        for _ in range(rng.integers(8, 20)):
            if known:
                c = rng.random() > true["p_slip"]
            else:
                c = rng.random() < true["p_guess"]
                if rng.random() < true["p_learn"]:
                    known = True
            seq.append(int(c))
        seqs.append(seq)
    return seqs


def run_bkt_pipeline(registry_root: str = "models_store", version: str | None = None):
    """BKT толық құбыры: дерек → fit → eval → register."""
    version = version or f"v{int(time.time())}"
    seqs = _synthetic_skill_sequences(500)

    # Train
    model = BKT().fit(seqs, iterations=40)

    # Eval (тарихтан келесіні болжау)
    y, p = [], []
    for seq in seqs:
        for t in range(1, len(seq)):
            p.append(model.predict_next_correct(seq[:t]))
            y.append(seq[t])
    metrics = evaluate_all(y, p)

    # Register
    registry = ModelRegistry(root=registry_root)
    entry = registry.register(
        name="bkt",
        version=version,
        metrics=metrics,
        params=model.params(),
        stage="staging",
    )
    # Ең жақсы нұсқаны production-ға көтеру
    best = registry.best("bkt", "auc")
    if best and best["version"] == version:
        registry.promote("bkt", version, "production")

    return {"version": version, "metrics": metrics, "params": entry["params"]}


def main():
    result = run_bkt_pipeline()
    print("=== BKT құбыры аяқталды ===")
    print("Нұсқа:", result["version"])
    print("Метрика:", {k: round(v, 3) for k, v in result["metrics"].items()})
    print("✅ Тізілімге тіркелді.")


if __name__ == "__main__":
    main()
