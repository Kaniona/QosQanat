"""BKT/IRT/HLR/метрика/рекомендер тесттері (numpy — torch қажет емес)."""
import numpy as np

from app.eval.metrics import accuracy, evaluate_all, roc_auc, rmse
from app.models.bkt import BKT
from app.models.irt import IRT2PL
from app.models.spacing import HalfLifeRegression, review_features
from app.recommend import AdaptiveRecommender, zpd_weight


def test_bkt_learning_increases_confidence():
    m = BKT(p_init=0.1, p_learn=0.3, p_guess=0.2, p_slip=0.1)
    p_early = m.predict_next_correct([1])
    p_late = m.predict_next_correct([1, 1, 1, 1, 1])
    assert p_late > p_early


def test_bkt_fit_constraints():
    seqs = [[1, 0, 1, 1, 1], [0, 1, 1, 1, 1]] * 30
    m = BKT().fit(seqs, iterations=15)
    assert 0.01 <= m.p_guess <= 0.5
    assert 0.01 <= m.p_slip <= 0.5


def test_irt_recovers_difficulty():
    rng = np.random.default_rng(0)
    theta = rng.normal(0, 1, 100)
    b = rng.normal(0, 1, 30)
    resp = []
    for s in range(100):
        for i in range(30):
            p = 1 / (1 + np.exp(-(theta[s] - b[i])))
            resp.append((s, int(i), int(rng.random() < p)))
    m = IRT2PL(100, 30).fit(resp, epochs=250, lr=0.05)
    corr = float(np.corrcoef(m.item_difficulty(), b)[0, 1])
    assert corr > 0.8


def test_hlr_more_practice_longer_interval():
    m = HalfLifeRegression(3)
    m.theta[:] = [0.5, 1.0, -0.8]
    i1 = m.optimal_interval(review_features(1, 0))
    i5 = m.optimal_interval(review_features(5, 0))
    assert i5 > i1 > 0


def test_metrics():
    auc = roc_auc([0, 0, 1, 1], [0.1, 0.4, 0.35, 0.8])
    assert 0.5 <= auc <= 1.0
    assert accuracy([1, 0, 1], [0.9, 0.2, 0.8]) == 1.0
    res = evaluate_all([0, 1, 0, 1], [0.2, 0.7, 0.3, 0.9])
    assert res["n"] == 4 and 0 <= res["accuracy"] <= 1


def test_recommender_prefers_weak_and_due():
    rec = AdaptiveRecommender()
    cands = [
        {"skill": 0, "mastery": 0.95, "prob_correct": 0.97, "due_ratio": 0.0, "seen": True},
        {"skill": 1, "mastery": 0.3, "prob_correct": 0.6, "due_ratio": 1.0, "seen": True},
    ]
    ranked = rec.rank(cands, top_k=1)
    assert ranked[0][0] == 1


def test_zpd_peaks_at_target():
    assert zpd_weight(0.75) > zpd_weight(0.95)
    assert zpd_weight(0.75) > zpd_weight(0.40)
