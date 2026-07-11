"""REINFORCE (policy gradient) агенті — оқу ретін оңтайландыруды үйренеді.

Сызықтық softmax саясаты (numpy): logits = W·state + b. Эпизод соңындағы
қайтарыммен (return) саясатты жаңартады. Бұл — RL-дың таза, тәуелсіз нұсқасы;
Stable-Baselines3 (PPO) дәл осы CurriculumEnv-ке жалғана алады.
"""
from __future__ import annotations

import numpy as np


class ReinforceAgent:
    def __init__(
        self,
        obs_dim: int,
        action_dim: int,
        lr: float = 0.02,
        gamma: float = 0.99,
        seed: int = 0,
    ) -> None:
        self.rng = np.random.default_rng(seed)
        self.W = self.rng.normal(0.0, 0.1, (action_dim, obs_dim))
        self.b = np.zeros(action_dim)
        self.lr = lr
        self.gamma = gamma
        self.action_dim = action_dim

    def policy(self, obs: np.ndarray) -> np.ndarray:
        logits = self.W @ obs + self.b
        logits -= logits.max()
        e = np.exp(logits)
        return e / e.sum()

    def act(self, obs: np.ndarray):
        p = self.policy(obs)
        action = int(self.rng.choice(self.action_dim, p=p))
        return action, p

    def _returns(self, rewards):
        out = np.zeros(len(rewards))
        running = 0.0
        for t in reversed(range(len(rewards))):
            running = rewards[t] + self.gamma * running
            out[t] = running
        # baseline + нормализация (дисперсияны азайту)
        if out.std() > 1e-8:
            out = (out - out.mean()) / (out.std() + 1e-8)
        return out

    def update(self, trajectory) -> None:
        """trajectory: list[(obs, action, reward)]."""
        if not trajectory:
            return
        obs_list, actions, rewards = zip(*trajectory)
        returns = self._returns(list(rewards))

        gw = np.zeros_like(self.W)
        gb = np.zeros_like(self.b)
        for obs, action, ret in zip(obs_list, actions, returns):
            p = self.policy(obs)
            onehot = np.zeros(self.action_dim)
            onehot[action] = 1.0
            grad_logits = onehot - p  # ∂logπ/∂logits
            gw += ret * np.outer(grad_logits, obs)
            gb += ret * grad_logits

        self.W += self.lr * gw
        self.b += self.lr * gb

    def act_greedy(self, obs: np.ndarray) -> int:
        return int(np.argmax(self.policy(obs)))
