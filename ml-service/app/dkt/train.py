"""DKT моделін жаттықтыру: маскаланған BCE шығыны + AUC бағалауы.

Қолдану:
    python -m app.dkt.train --skills 98 --students 4000 --epochs 12 --out model.pt

Нақты деректе: --csv answers.csv (student_id, skill_id, correct, timestamp).
GPU болса автоматты қолданылады.
"""
from __future__ import annotations

import argparse

import numpy as np
import torch
from torch import nn
from torch.utils.data import DataLoader, random_split

from .data import dataframe_to_sequences, synthetic_dataset
from .model import DKT, save_checkpoint
from .torch_data import InteractionDataset, collate


def masked_bce(logits, tgt_skill, tgt_correct, mask):
    """Әр қадамда МАҚСАТ тақырыптың логитін алып, маскаланған BCE есептейді."""
    pred = torch.gather(logits, 2, tgt_skill.unsqueeze(-1)).squeeze(-1)
    loss = nn.functional.binary_cross_entropy_with_logits(
        pred, tgt_correct, reduction="none"
    )
    denom = mask.sum().clamp(min=1.0)
    return (loss * mask).sum() / denom, torch.sigmoid(pred)


def _auc(y_true: np.ndarray, y_score: np.ndarray) -> float:
    try:
        from sklearn.metrics import roc_auc_score

        return float(roc_auc_score(y_true, y_score))
    except Exception:
        return float("nan")


@torch.no_grad()
def evaluate(model: DKT, loader: DataLoader, device: str) -> float:
    model.eval()
    ys, ps = [], []
    for x, ts, tc, m in loader:
        x, ts, tc, m = x.to(device), ts.to(device), tc.to(device), m.to(device)
        _, prob = masked_bce(model(x), ts, tc, m)
        sel = m.bool()
        ys.append(tc[sel].cpu().numpy())
        ps.append(prob[sel].cpu().numpy())
    return _auc(np.concatenate(ys), np.concatenate(ps))


def train(
    sequences,
    num_skills: int,
    epochs: int = 12,
    batch_size: int = 64,
    lr: float = 1e-3,
    hidden_size: int = 128,
    out_path: str = "model.pt",
    device: str | None = None,
):
    device = device or ("cuda" if torch.cuda.is_available() else "cpu")
    dataset = InteractionDataset(sequences, num_skills)
    n_val = max(1, int(0.1 * len(dataset)))
    n_train = len(dataset) - n_val
    train_ds, val_ds = random_split(
        dataset, [n_train, n_val], generator=torch.Generator().manual_seed(0)
    )

    train_loader = DataLoader(
        train_ds, batch_size=batch_size, shuffle=True, collate_fn=collate
    )
    val_loader = DataLoader(val_ds, batch_size=batch_size, collate_fn=collate)

    model = DKT(num_skills=num_skills, hidden_size=hidden_size).to(device)
    optim = torch.optim.Adam(model.parameters(), lr=lr)

    best_auc = 0.0
    for epoch in range(1, epochs + 1):
        model.train()
        total = 0.0
        for x, ts, tc, m in train_loader:
            x, ts, tc, m = x.to(device), ts.to(device), tc.to(device), m.to(device)
            optim.zero_grad()
            loss, _ = masked_bce(model(x), ts, tc, m)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), 5.0)
            optim.step()
            total += loss.item()

        auc = evaluate(model, val_loader, device)
        print(f"epoch {epoch:02d} | loss {total / len(train_loader):.4f} | val AUC {auc:.4f}")
        if auc >= best_auc:
            best_auc = auc
            save_checkpoint(model, out_path)

    print(f"✅ Сақталды: {out_path} (best val AUC {best_auc:.4f})")
    return model, best_auc


def main() -> None:
    parser = argparse.ArgumentParser(description="DKT жаттықтыру")
    parser.add_argument("--skills", type=int, default=98)
    parser.add_argument("--students", type=int, default=4000)
    parser.add_argument("--epochs", type=int, default=12)
    parser.add_argument("--out", type=str, default="model.pt")
    parser.add_argument("--csv", type=str, default=None, help="нақты жауап журналы")
    args = parser.parse_args()

    if args.csv:
        import json

        import pandas as pd

        df = pd.read_csv(args.csv)
        skills = sorted(df["skill_id"].unique())
        skill_to_idx = {s: i for i, s in enumerate(skills)}
        with open("skill_vocab.json", "w", encoding="utf-8") as fh:
            json.dump(skill_to_idx, fh, ensure_ascii=False, indent=2)
        sequences = dataframe_to_sequences(df, skill_to_idx)
        num_skills = len(skills)
    else:
        sequences = synthetic_dataset(args.students, args.skills)
        num_skills = args.skills

    train(sequences, num_skills, epochs=args.epochs, out_path=args.out)


if __name__ == "__main__":
    main()
