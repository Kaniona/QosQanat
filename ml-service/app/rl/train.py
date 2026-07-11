"""RL агентін жаттықтыру + базалық стратегиялармен салыстыру.

    python -m app.rl.train

Агент (REINFORCE) кездейсоқ/кезекті стратегиялардан АРТЫҚ оқу ретін табуы тиіс.
"""
from __future__ import annotations

import numpy as np

from .agent import ReinforceAgent
from .env import CurriculumEnv

# Қарапайым алғы шарт құрылымы: кейбір тақырып алдыңғыларды талап етеді
PREREQS = {2: [0, 1], 3: [2], 5: [4], 6: [5], 8: [7], 9: [8]}


def run_episode(env: CurriculumEnv, policy_fn):
    obs, _ = env.reset()
    total = 0.0
    trajectory = []
    done = False
    while not done:
        action = policy_fn(obs)
        next_obs, reward, term, trunc, info = env.step(action)
        trajectory.append((obs, action, reward))
        total += reward
        obs = next_obs
        done = term or trunc
    return total, info["total_mastery"], trajectory


def baseline_random(num_skills, seed=0):
    rng = np.random.default_rng(seed)
    return lambda obs: int(rng.integers(0, num_skills))


def baseline_weakest(obs):
    """Эвристика: ең әлсіз тақырыпты оқыт."""
    return int(np.argmin(obs))


def evaluate(env, policy_fn, episodes=50):
    masteries = [run_episode(env, policy_fn)[1] for _ in range(episodes)]
    return float(np.mean(masteries))


def main():
    num_skills = 10
    env = CurriculumEnv(num_skills=num_skills, horizon=50, prereqs=PREREQS, seed=1)
    agent = ReinforceAgent(num_skills, num_skills, lr=0.05, seed=2)

    # Жаттығу
    for ep in range(1, 601):
        _, _, traj = run_episode(env, lambda o: agent.act(o)[0])
        agent.update(traj)
        if ep % 150 == 0:
            m = evaluate(env, lambda o: agent.act_greedy(o))
            print(f"episode {ep:3d} | агент меңгеру: {m:.3f}")

    print("\n=== Соңғы салыстыру (орташа меңгеру) ===")
    print(f"  Кездейсоқ:     {evaluate(env, baseline_random(num_skills)):.3f}")
    print(f"  Ең әлсіз:      {evaluate(env, baseline_weakest):.3f}")
    print(f"  RL агент:      {evaluate(env, lambda o: agent.act_greedy(o)):.3f}")


if __name__ == "__main__":
    main()
