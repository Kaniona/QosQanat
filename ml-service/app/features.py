"""Белгі инженериясы (feature engineering) — жауап журналынан оқушы белгілерін
шығару (Pandas). Бұл белгілер кластерлеу, кету болжамы, рекомендерге азық.
"""
from __future__ import annotations

import numpy as np
import pandas as pd


def student_features(df: pd.DataFrame) -> pd.DataFrame:
    """Журнал (student_id, skill_id, correct, timestamp) → оқушы белгілері.

    Белгілер: жалпы дәлдік, тапсырма саны, бірегей тақырып, соңғы дәлдік
    (трендтің бағыты), орташа сессия қарқыны, белсенді күн саны.
    """
    df = df.copy()
    df["timestamp"] = pd.to_datetime(df["timestamp"], errors="coerce")
    df = df.dropna(subset=["timestamp"]).sort_values(["student_id", "timestamp"])

    rows = []
    for sid, g in df.groupby("student_id"):
        n = len(g)
        correct = g["correct"].astype(int)
        last_k = correct.tail(max(1, n // 5))  # соңғы ~20%
        first_k = correct.head(max(1, n // 5))
        days_active = g["timestamp"].dt.date.nunique()
        span_days = max(1, (g["timestamp"].max() - g["timestamp"].min()).days)
        rows.append(
            {
                "student_id": sid,
                "n_answers": n,
                "accuracy": float(correct.mean()),
                "unique_skills": int(g["skill_id"].nunique()),
                "recent_accuracy": float(last_k.mean()),
                "early_accuracy": float(first_k.mean()),
                "trend": float(last_k.mean() - first_k.mean()),
                "days_active": int(days_active),
                "answers_per_day": float(n / span_days),
            }
        )
    return pd.DataFrame(rows)


def skill_features(df: pd.DataFrame) -> pd.DataFrame:
    """Тақырып деңгейіндегі белгілер (қиындықты бағалауға)."""
    df = df.copy()
    grp = df.groupby("skill_id")["correct"].agg(["mean", "count"]).reset_index()
    grp.columns = ["skill_id", "p_correct", "attempts"]
    grp["empirical_difficulty"] = 1.0 - grp["p_correct"]
    return grp


def to_matrix(feat: pd.DataFrame, columns=None):
    """Белгі DataFrame-ін ML үшін (X, ids) матрицасына айналдыру."""
    cols = columns or [
        "n_answers",
        "accuracy",
        "unique_skills",
        "recent_accuracy",
        "trend",
        "days_active",
        "answers_per_day",
    ]
    x = feat[cols].to_numpy(dtype=np.float64)
    # Қарапайым стандарттау (z-score)
    mean = x.mean(axis=0)
    std = x.std(axis=0) + 1e-9
    return (x - mean) / std, feat["student_id"].tolist()
