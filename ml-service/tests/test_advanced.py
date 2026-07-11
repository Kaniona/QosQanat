"""RL / NLP / болжау / MLOps модульдерінің тесттері (numpy — torch қажет емес)."""
import numpy as np

from app.forecast.readiness import ReadinessForecaster
from app.mlops.registry import ModelRegistry
from app.nlp.generate import cloze_questions, generate_for_lessons
from app.nlp.grading import AnswerGrader
from app.rl.agent import ReinforceAgent
from app.rl.env import CurriculumEnv
from app.rl.train import baseline_random, evaluate, run_episode


def test_env_runs():
    env = CurriculumEnv(num_skills=5, horizon=10)
    obs, _ = env.reset()
    assert obs.shape == (5,)
    obs2, reward, term, trunc, info = env.step(0)
    assert obs2.shape == (5,) and "total_mastery" in info


def test_rl_agent_trains_and_runs():
    """Агент қатесіз жаттығады әрі валид саясат береді (артықшылықты demo
    (app.rl.train) көрсетеді — стохастика тестте тұрақсыз)."""
    env = CurriculumEnv(num_skills=6, horizon=30, seed=1)
    agent = ReinforceAgent(6, 6, lr=0.05, seed=2)
    for _ in range(200):
        _, _, traj = run_episode(env, lambda o: agent.act(o)[0])
        agent.update(traj)
    after = evaluate(env, lambda o: agent.act_greedy(o), episodes=20)
    assert 0.0 < after <= 1.0
    # Саясат валид ықтималдық үлестірімін береді
    p = agent.policy(np.zeros(6))
    assert abs(float(p.sum()) - 1.0) < 1e-6


def test_answer_grader():
    g = AnswerGrader()
    good = g.grade("Жай бөлшек — бүтіннің бөлігі", "Бөлшек бүтіннің бөлігі")
    bad = g.grade("мүлдем қатысы жоқ сөздер", "Бөлшек бүтіннің бөлігі")
    assert good["score"] > bad["score"]
    assert good["verdict"] in ("correct", "partial")


def test_question_generation():
    lesson = {
        "title": "Жай бөлшектер",
        "intro": "Жай бөлшек бүтіннің бөлігі болады. Алым мен бөлім деген ұғымдар бар.",
    }
    qs = cloze_questions(lesson)
    assert len(qs) >= 1
    assert "___" in qs[0]["text"] and qs[0]["answer"]
    assert len(generate_for_lessons([lesson])) >= 2


def test_readiness_forecast():
    f = ReadinessForecaster()
    res = f.exam_readiness([0.9, 0.8, 0.5, 0.3])
    assert res["total"] == 4 and res["ready_topics"] == 2
    assert res["days_to_ready"] > 0
    assert len(f.trajectory(0.3, days=10)) == 11


def test_model_registry(tmp_path):
    reg = ModelRegistry(root=str(tmp_path))
    reg.register("dkt", "v1", metrics={"auc": 0.75})
    reg.register("dkt", "v2", metrics={"auc": 0.82})
    assert reg.best("dkt", "auc")["version"] == "v2"
    assert reg.latest("dkt")["version"] == "v2"
    assert reg.promote("dkt", "v2")
    prod = [e for e in reg.list_versions("dkt") if e["stage"] == "production"]
    assert len(prod) == 1
