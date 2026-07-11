"""DKT деректер құбыры — NumPy/Pandas кодтау + жасанды деректер генераторы.

Нақты дерек: оқушылардың жауап журналы (student_id, skill_id, correct, ts).
Жасанды дерек: модельді сынау/демо үшін (латентті қабілет + үйрену динамикасы).
"""
from __future__ import annotations

import numpy as np
import pandas as pd


def encode_sequence(seq, num_skills: int):
    """Бір оқушының тізбегі → (X, tgt_skill, tgt_correct, mask).

    seq: list[(skill_idx, correct)]. t-қадамда t+1 интеракцияны болжаймыз
    (стандарт DKT), сондықтан соңғы қадамның мақсаты болмайды (mask=0).
    """
    length = len(seq)
    x = np.zeros((length, 2 * num_skills), dtype=np.float32)
    tgt_skill = np.zeros(length, dtype=np.int64)
    tgt_correct = np.zeros(length, dtype=np.float32)
    mask = np.zeros(length, dtype=np.float32)

    for t, (skill, correct) in enumerate(seq):
        x[t, skill + (num_skills if correct else 0)] = 1.0
        if t + 1 < length:
            next_skill, next_correct = seq[t + 1]
            tgt_skill[t] = next_skill
            tgt_correct[t] = float(next_correct)
            mask[t] = 1.0

    return x, tgt_skill, tgt_correct, mask


def synthetic_dataset(
    num_students: int,
    num_skills: int,
    min_len: int = 10,
    max_len: int = 40,
    seed: int = 42,
):
    """Жасанды оқушылар: әр тақырыпқа жасырын қабілет + қайталау → үйрену.

    Бұл генератор модельге ҮЙРЕНЕТІН СИГНАЛ береді (қайталаған сайын дұрыс
    жауап ықтималдығы өседі) — DKT-ні сынау/демолау үшін.
    """
    rng = np.random.default_rng(seed)
    sequences = []
    for _ in range(num_students):
        ability = rng.normal(0.0, 1.0, size=num_skills)
        length = int(rng.integers(min_len, max_len + 1))
        seen = np.zeros(num_skills)
        seq = []
        for _ in range(length):
            skill = int(rng.integers(0, num_skills))
            seen[skill] += 1
            logit = ability[skill] + 0.3 * seen[skill] - 1.0
            prob = 1.0 / (1.0 + np.exp(-logit))
            correct = int(rng.random() < prob)
            seq.append((skill, correct))
        sequences.append(seq)
    return sequences


def dataframe_to_sequences(df: pd.DataFrame, skill_to_idx: dict):
    """Нақты журнал (student_id, skill_id, correct, timestamp) → тізбектер."""
    df = df.sort_values(["student_id", "timestamp"])
    sequences = []
    for _, group in df.groupby("student_id"):
        seq = [
            (skill_to_idx[s], int(c))
            for s, c in zip(group["skill_id"], group["correct"])
            if s in skill_to_idx
        ]
        if len(seq) >= 2:
            sequences.append(seq)
    return sequences
