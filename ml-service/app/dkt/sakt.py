"""SAKT — Self-Attentive Knowledge Tracing (Pandey & Karypis, 2019).

Transformer (өзіне-назар): оқушының өткен интеракцияларына назар салып, КЕЛЕСІ
сұраққа жауапты болжайды. LSTM-ге қарағанда ұзақ тәуелділіктерді жақсы ұстайды
(қазіргі SOTA білім трекингі).
"""
from __future__ import annotations

import torch
from torch import nn


class SAKT(nn.Module):
    def __init__(
        self,
        num_skills: int,
        d_model: int = 128,
        n_heads: int = 8,
        dropout: float = 0.2,
        max_len: int = 200,
    ) -> None:
        super().__init__()
        self.num_skills = num_skills
        self.d_model = d_model
        # Интеракция: (тақырып, дұрыс/қате) → 0 padding үшін
        self.interaction_emb = nn.Embedding(2 * num_skills + 1, d_model, padding_idx=0)
        self.exercise_emb = nn.Embedding(num_skills + 1, d_model, padding_idx=0)
        self.pos_emb = nn.Embedding(max_len, d_model)

        self.attn = nn.MultiheadAttention(
            d_model, n_heads, dropout=dropout, batch_first=True
        )
        self.ln1 = nn.LayerNorm(d_model)
        self.ffn = nn.Sequential(
            nn.Linear(d_model, d_model),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(d_model, d_model),
        )
        self.ln2 = nn.LayerNorm(d_model)
        self.dropout = nn.Dropout(dropout)
        self.out = nn.Linear(d_model, 1)

    def forward(self, interactions: torch.Tensor, exercises: torch.Tensor) -> torch.Tensor:
        """interactions: (B, T) өткен интеракция id; exercises: (B, T) болжанатын
        сұрақ id. Қайтарады: (B, T) логиттер (P дұрыс)."""
        b, t = interactions.shape
        positions = torch.arange(t, device=interactions.device).unsqueeze(0).expand(b, t)

        key = self.interaction_emb(interactions) + self.pos_emb(positions)
        query = self.exercise_emb(exercises)

        # Себептік маска: тек өткенге назар (болашақты көрмеу)
        causal = torch.triu(
            torch.ones(t, t, device=interactions.device, dtype=torch.bool), diagonal=1
        )
        attn_out, _ = self.attn(query, key, key, attn_mask=causal)
        x = self.ln1(query + self.dropout(attn_out))
        x = self.ln2(x + self.dropout(self.ffn(x)))
        return self.out(x).squeeze(-1)

    @torch.no_grad()
    def predict_last(self, interactions: torch.Tensor, exercises: torch.Tensor) -> torch.Tensor:
        return torch.sigmoid(self.forward(interactions, exercises))[:, -1]

    def config(self) -> dict:
        return {"num_skills": self.num_skills, "d_model": self.d_model}
