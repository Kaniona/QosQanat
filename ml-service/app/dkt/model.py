"""Deep Knowledge Tracing (DKT) — оқушының білім күйін модельдейтін нейрожелі.

Әдіс: Piech et al., 2015 ("Deep Knowledge Tracing"). LSTM оқушының жауап
тізбегін оқып, ӘР тақырып бойынша «келесіде дұрыс жауап беру ықтималдығын»
болжайды. Бұл — QosQanat-тың қазіргі EMA эвристикасының күшті, зерттеу
деңгейіндегі баламасы.
"""
from __future__ import annotations

import torch
from torch import nn


class DKT(nn.Module):
    """LSTM негізді Deep Knowledge Tracing моделі.

    Кіріс: (B, T, 2*num_skills) — әр қадам (тақырып, дұрыс/қате) one-hot.
    Шығыс: (B, T, num_skills) — әр қадамнан кейінгі әр тақырыптың P(дұрыс) логиті.
    """

    def __init__(
        self,
        num_skills: int,
        hidden_size: int = 128,
        num_layers: int = 2,
        dropout: float = 0.2,
    ) -> None:
        super().__init__()
        self.num_skills = num_skills
        self.input_size = 2 * num_skills
        self.hidden_size = hidden_size

        self.lstm = nn.LSTM(
            input_size=self.input_size,
            hidden_size=hidden_size,
            num_layers=num_layers,
            batch_first=True,
            dropout=dropout if num_layers > 1 else 0.0,
        )
        self.dropout = nn.Dropout(dropout)
        self.fc = nn.Linear(hidden_size, num_skills)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Логиттер (B, T, num_skills)."""
        hidden, _ = self.lstm(x)
        return self.fc(self.dropout(hidden))

    @torch.no_grad()
    def mastery(self, x: torch.Tensor) -> torch.Tensor:
        """Соңғы қадамдағы әр тақырып бойынша меңгеру ықтималдығы (B, num_skills)."""
        probs = torch.sigmoid(self.forward(x))
        return probs[:, -1, :]

    def config(self) -> dict:
        return {
            "num_skills": self.num_skills,
            "hidden_size": self.hidden_size,
            "num_layers": self.lstm.num_layers,
        }


def save_checkpoint(model: DKT, path: str) -> None:
    """Модель салмағы + конфигурациясын сақтау."""
    torch.save({"state_dict": model.state_dict(), "config": model.config()}, path)


def load_checkpoint(path: str, map_location: str = "cpu") -> DKT:
    """Сақталған модельді жүктеу."""
    ckpt = torch.load(path, map_location=map_location)
    model = DKT(**ckpt["config"])
    model.load_state_dict(ckpt["state_dict"])
    model.eval()
    return model
