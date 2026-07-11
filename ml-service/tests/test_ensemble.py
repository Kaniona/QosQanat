"""Ансамбль + құбыр (MLOps) тесттері."""
from app.ensemble import MasteryEnsemble
from app.pipeline import run_bkt_pipeline


def test_ensemble_combines_and_confidence():
    e = MasteryEnsemble()
    agree = e.estimate({"bkt": 0.80, "dkt": 0.82})
    disagree = e.estimate({"bkt": 0.20, "dkt": 0.90})
    # Модельдер келіссе — сенімділік жоғары
    assert agree["confidence"] > disagree["confidence"]
    assert 0.0 <= agree["mastery"] <= 1.0
    assert agree["sources"] == 2


def test_ensemble_single_source():
    e = MasteryEnsemble()
    res = e.estimate({"bkt": 0.7})
    assert res["sources"] == 1
    assert abs(res["mastery"] - 0.7) < 1e-6


def test_calibration_softens():
    e = MasteryEnsemble()
    # Жоғары температура → 0.5-ке жақындатады (артық сенімділікті тегістейді)
    assert e.calibrate(0.95, temperature=3.0) < 0.95


def test_pipeline_end_to_end(tmp_path):
    res = run_bkt_pipeline(registry_root=str(tmp_path), version="test1")
    assert "auc" in res["metrics"]
    assert res["version"] == "test1"
    assert res["metrics"]["auc"] > 0.5  # жасанды деректе мағыналы
