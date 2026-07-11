"""DKVMN — Dynamic Key-Value Memory Network (Zhang et al., 2017).

Жадпен толықтырылған білім трекингі: статикалық КІЛТ жады (тақырып ұғымдары) +
динамикалық МӘН жады (меңгеру күйі). Әр жауап мән жадын erase/add қақпалармен
жаңартады. DKT/SAKT-тен өзгеше — әр «ұғымды» бөлек ұстайды (интерпретация
жақсырақ).
"""
from __future__ import annotations

import torch
import torch.nn.functional as F
from torch import nn


class DKVMN(nn.Module):
    def __init__(
        self,
        num_skills: int,
        memory_size: int = 50,
        key_dim: int = 50,
        value_dim: int = 100,
    ) -> None:
        super().__init__()
        self.num_skills = num_skills
        self.memory_size = memory_size
        self.value_dim = value_dim

        self.q_embed = nn.Embedding(num_skills + 1, key_dim, padding_idx=0)
        self.qa_embed = nn.Embedding(2 * num_skills + 1, value_dim, padding_idx=0)

        self.key_memory = nn.Parameter(torch.randn(memory_size, key_dim) * 0.1)
        self.value_memory_init = nn.Parameter(
            torch.randn(memory_size, value_dim) * 0.1
        )

        self.erase = nn.Linear(value_dim, value_dim)
        self.add = nn.Linear(value_dim, value_dim)
        self.summary = nn.Linear(value_dim + key_dim, 64)
        self.out = nn.Linear(64, 1)

    def forward(self, q: torch.Tensor, qa: torch.Tensor) -> torch.Tensor:
        """q: (B, T) тақырып id; qa: (B, T) интеракция id → логиттер (B, T)."""
        bsz, seq = q.shape
        value_mem = (
            self.value_memory_init.unsqueeze(0).expand(bsz, -1, -1).clone()
        )
        preds = []
        for t in range(seq):
            k = self.q_embed(q[:, t])  # (B, key_dim)
            corr = F.softmax(k @ self.key_memory.t(), dim=1)  # (B, N)
            read = torch.bmm(corr.unsqueeze(1), value_mem).squeeze(1)  # (B, value_dim)
            feat = torch.tanh(self.summary(torch.cat([read, k], dim=1)))
            preds.append(self.out(feat).squeeze(-1))

            # Мән жадын жаңарту (erase–add)
            v = self.qa_embed(qa[:, t])  # (B, value_dim)
            erase = torch.sigmoid(self.erase(v)).unsqueeze(1)  # (B, 1, value_dim)
            add = torch.tanh(self.add(v)).unsqueeze(1)
            w = corr.unsqueeze(2)  # (B, N, 1)
            value_mem = value_mem * (1 - w * erase) + w * add

        return torch.stack(preds, dim=1)

    def config(self) -> dict:
        return {"num_skills": self.num_skills, "memory_size": self.memory_size}
