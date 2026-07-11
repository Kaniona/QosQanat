"""Бағалау метрикалары — білім трекинг модельдерін салыстыру (AUC/ACC/RMSE/
калибрация). NumPy ғана (sklearn болмаса да жұмыс істейді)."""
from __future__ import annotations

import numpy as np


def accuracy(y_true, y_prob, threshold: float = 0.5) -> float:
    y_true = np.asarray(y_true)
    y_pred = (np.asarray(y_prob) >= threshold).astype(int)
    return float((y_pred == y_true).mean()) if len(y_true) else float("nan")


def rmse(y_true, y_prob) -> float:
    y_true = np.asarray(y_true, dtype=float)
    y_prob = np.asarray(y_prob, dtype=float)
    return float(np.sqrt(np.mean((y_true - y_prob) ** 2))) if len(y_true) else float("nan")


def roc_auc(y_true, y_prob) -> float:
    """AUC — рангтік (Mann–Whitney U) есеп; sklearn қажет емес."""
    y_true = np.asarray(y_true)
    y_prob = np.asarray(y_prob, dtype=float)
    pos = y_prob[y_true == 1]
    neg = y_prob[y_true == 0]
    if len(pos) == 0 or len(neg) == 0:
        return float("nan")
    order = np.argsort(y_prob, kind="mergesort")
    ranks = np.empty(len(y_prob), dtype=float)
    ranks[order] = np.arange(1, len(y_prob) + 1)
    # Тең мәндерге орташа ранг
    sorted_p = y_prob[order]
    i = 0
    while i < len(sorted_p):
        j = i
        while j + 1 < len(sorted_p) and sorted_p[j + 1] == sorted_p[i]:
            j += 1
        if j > i:
            avg = (ranks[order[i]] + ranks[order[j]]) / 2.0
            for k in range(i, j + 1):
                ranks[order[k]] = avg
        i = j + 1
    sum_pos = ranks[y_true == 1].sum()
    n_pos, n_neg = len(pos), len(neg)
    auc = (sum_pos - n_pos * (n_pos + 1) / 2.0) / (n_pos * n_neg)
    return float(auc)


def log_loss(y_true, y_prob, eps: float = 1e-9) -> float:
    y_true = np.asarray(y_true, dtype=float)
    p = np.clip(np.asarray(y_prob, dtype=float), eps, 1 - eps)
    return float(-np.mean(y_true * np.log(p) + (1 - y_true) * np.log(1 - p)))


def calibration_bins(y_true, y_prob, n_bins: int = 10):
    """Калибрация: болжам vs нақты жиілік (n_bins себетте)."""
    y_true = np.asarray(y_true, dtype=float)
    y_prob = np.asarray(y_prob, dtype=float)
    edges = np.linspace(0, 1, n_bins + 1)
    out = []
    for i in range(n_bins):
        sel = (y_prob >= edges[i]) & (y_prob < edges[i + 1] if i < n_bins - 1 else y_prob <= edges[i + 1])
        if sel.sum() == 0:
            continue
        out.append(
            {
                "bin": [float(edges[i]), float(edges[i + 1])],
                "predicted": float(y_prob[sel].mean()),
                "actual": float(y_true[sel].mean()),
                "count": int(sel.sum()),
            }
        )
    return out


def evaluate_all(y_true, y_prob) -> dict:
    return {
        "auc": roc_auc(y_true, y_prob),
        "accuracy": accuracy(y_true, y_prob),
        "rmse": rmse(y_true, y_prob),
        "log_loss": log_loss(y_true, y_prob),
        "n": int(len(y_true)),
    }
