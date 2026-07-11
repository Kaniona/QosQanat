"""PyTorch-қа тәуелді деректер бөлігі (Dataset + collate).

Бөлек модуль: `data.py` (encode/synthetic) torch-сыз да импортталады, сонда
инференс/тест ауыр кітапханасыз жұмыс істейді.
"""
from __future__ import annotations

import torch
from torch.utils.data import Dataset

from .data import encode_sequence


class InteractionDataset(Dataset):
    """Оқушы тізбектерінің PyTorch деректер жиыны."""

    def __init__(self, sequences, num_skills: int) -> None:
        self.sequences = sequences
        self.num_skills = num_skills

    def __len__(self) -> int:
        return len(self.sequences)

    def __getitem__(self, idx: int):
        x, ts, tc, m = encode_sequence(self.sequences[idx], self.num_skills)
        return (
            torch.from_numpy(x),
            torch.from_numpy(ts),
            torch.from_numpy(tc),
            torch.from_numpy(m),
        )


def collate(batch):
    """Әртүрлі ұзындықты тізбектерді ең ұзынына дейін толтыру (padding)."""
    xs, tss, tcs, ms = zip(*batch)
    lengths = [x.shape[0] for x in xs]
    max_t = max(lengths)
    feat = xs[0].shape[1]
    bsz = len(batch)

    x = torch.zeros(bsz, max_t, feat)
    tgt_skill = torch.zeros(bsz, max_t, dtype=torch.long)
    tgt_correct = torch.zeros(bsz, max_t)
    mask = torch.zeros(bsz, max_t)

    for i, length in enumerate(lengths):
        x[i, :length] = xs[i]
        tgt_skill[i, :length] = tss[i]
        tgt_correct[i, :length] = tcs[i]
        mask[i, :length] = ms[i]

    return x, tgt_skill, tgt_correct, mask
