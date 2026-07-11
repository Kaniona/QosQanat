"""Модель тізілімі (Model Registry) — модельдердің нұсқаларын, метрикаларын,
параметрлерін сақтайды әрі ең жақсысын таңдайды. Қарапайым MLOps: эксперимент
қадағалау + өндіріске қай нұсқа шығатынын басқару (MLflow-дың жеңіл баламасы).
"""
from __future__ import annotations

import json
import time
from pathlib import Path


class ModelRegistry:
    def __init__(self, root: str = "models_store") -> None:
        self.root = Path(root)
        self.root.mkdir(parents=True, exist_ok=True)

    def _meta_path(self, name: str) -> Path:
        return self.root / f"{name}.registry.json"

    def _load(self, name: str) -> list:
        p = self._meta_path(name)
        if not p.exists():
            return []
        with p.open(encoding="utf-8") as fh:
            return json.load(fh)

    def _save(self, name: str, entries: list) -> None:
        with self._meta_path(name).open("w", encoding="utf-8") as fh:
            json.dump(entries, fh, ensure_ascii=False, indent=2)

    def register(
        self,
        name: str,
        version: str,
        metrics: dict | None = None,
        params: dict | None = None,
        artifact_path: str | None = None,
        stage: str = "staging",
    ) -> dict:
        entries = self._load(name)
        entry = {
            "name": name,
            "version": version,
            "metrics": metrics or {},
            "params": params or {},
            "artifact_path": artifact_path,
            "stage": stage,
            "created_at": time.time(),
        }
        # Бар нұсқаны жаңартамыз немесе қосамыз
        entries = [e for e in entries if e["version"] != version]
        entries.append(entry)
        self._save(name, entries)
        return entry

    def list_versions(self, name: str) -> list:
        return sorted(self._load(name), key=lambda e: e["created_at"], reverse=True)

    def latest(self, name: str) -> dict | None:
        versions = self.list_versions(name)
        return versions[0] if versions else None

    def best(self, name: str, metric: str, higher_better: bool = True) -> dict | None:
        entries = [e for e in self._load(name) if metric in e.get("metrics", {})]
        if not entries:
            return None
        return (max if higher_better else min)(
            entries, key=lambda e: e["metrics"][metric]
        )

    def promote(self, name: str, version: str, stage: str = "production") -> bool:
        entries = self._load(name)
        found = False
        for e in entries:
            if e["version"] == version:
                e["stage"] = stage
                found = True
            elif e["stage"] == stage:
                e["stage"] = "archived"  # бір ғана production
        if found:
            self._save(name, entries)
        return found
