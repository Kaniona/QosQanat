"""Bayesian Knowledge Tracing (BKT) — классикалық білім трекингі (Corbett &
Anderson, 1995). Әр тақырыпқа жасырын «білемін/білмеймін» күйі бар жасырын
Марков моделі (HMM). 4 параметр EM арқылы бағаланады:

  p_init  — басында білу ықтималдығы
  p_learn — білмеуден білуге өту (үйрену) ықтималдығы
  p_guess — білмесе де дұрыс табу (болжау) ықтималдығы
  p_slip  — білсе де қателесу ықтималдығы

DKT-ге қарағанда BKT түсіндірмелі (параметрлердің мағынасы анық).
"""
from __future__ import annotations

import numpy as np


class BKT:
    def __init__(
        self,
        p_init: float = 0.2,
        p_learn: float = 0.2,
        p_guess: float = 0.2,
        p_slip: float = 0.1,
    ) -> None:
        self.p_init = p_init
        self.p_learn = p_learn
        self.p_guess = p_guess
        self.p_slip = p_slip

    def _p_correct_given_known(self, known: float) -> float:
        return known * (1.0 - self.p_slip) + (1.0 - known) * self.p_guess

    def predict_sequence(self, obs):
        """obs: 0/1 тізбегі → әр қадамнан КЕЙІНгі P(білемін) тізбегі."""
        known = self.p_init
        post = []
        for o in obs:
            # Бақылауды ескеру (Bayes): P(білемін | бақылау)
            if o == 1:
                num = known * (1.0 - self.p_slip)
                den = num + (1.0 - known) * self.p_guess
            else:
                num = known * self.p_slip
                den = num + (1.0 - known) * (1.0 - self.p_guess)
            known_post = num / den if den > 1e-12 else known
            # Үйрену өтуі
            known = known_post + (1.0 - known_post) * self.p_learn
            post.append(known)
        return post

    def predict_next_correct(self, obs) -> float:
        """Келесі сұраққа дұрыс жауап беру ықтималдығы."""
        if not obs:
            return self._p_correct_given_known(self.p_init)
        known = self.predict_sequence(obs)[-1]
        return self._p_correct_given_known(known)

    def fit(self, sequences, iterations: int = 30, tol: float = 1e-4):
        """EM арқылы 4 параметрді бағалау (бір тақырыптың тізбектерінен)."""
        for _ in range(iterations):
            # Жинақтаушылар
            init_known = 0.0
            n_seq = 0
            learn_num = learn_den = 0.0
            guess_num = guess_den = 0.0
            slip_num = slip_den = 0.0

            for obs in sequences:
                if not obs:
                    continue
                n_seq += 1
                known = self.p_init
                for t, o in enumerate(obs):
                    # Алдыңғы P(білемін) — бұл қадамға дейін
                    p_known_prior = known
                    if t == 0:
                        init_known += p_known_prior

                    # Бақылау статистикасы (болжау/қателесу)
                    guess_den += (1.0 - p_known_prior)
                    slip_den += p_known_prior
                    if o == 1:
                        guess_num += (1.0 - p_known_prior)
                    else:
                        slip_num += p_known_prior

                    # Постериор + үйрену
                    if o == 1:
                        num = p_known_prior * (1.0 - self.p_slip)
                        den = num + (1.0 - p_known_prior) * self.p_guess
                    else:
                        num = p_known_prior * self.p_slip
                        den = num + (1.0 - p_known_prior) * (1.0 - self.p_guess)
                    post = num / den if den > 1e-12 else p_known_prior

                    learn_den += (1.0 - post)
                    learn_num += (1.0 - post) * self.p_learn
                    known = post + (1.0 - post) * self.p_learn

            new_init = init_known / n_seq if n_seq else self.p_init
            new_learn = learn_num / learn_den if learn_den > 1e-9 else self.p_learn
            new_guess = guess_num / guess_den if guess_den > 1e-9 else self.p_guess
            new_slip = slip_num / slip_den if slip_den > 1e-9 else self.p_slip

            # Тұрақтылық: болжау/қателесу 0.5-тен аспауы тиіс (BKT шарты)
            new_guess = float(np.clip(new_guess, 0.01, 0.5))
            new_slip = float(np.clip(new_slip, 0.01, 0.5))
            new_init = float(np.clip(new_init, 0.01, 0.99))
            new_learn = float(np.clip(new_learn, 0.001, 0.99))

            delta = (
                abs(new_init - self.p_init)
                + abs(new_learn - self.p_learn)
                + abs(new_guess - self.p_guess)
                + abs(new_slip - self.p_slip)
            )
            self.p_init, self.p_learn = new_init, new_learn
            self.p_guess, self.p_slip = new_guess, new_slip
            if delta < tol:
                break
        return self

    def params(self) -> dict:
        return {
            "p_init": self.p_init,
            "p_learn": self.p_learn,
            "p_guess": self.p_guess,
            "p_slip": self.p_slip,
        }


class MultiSkillBKT:
    """Әр тақырыпқа жеке BKT моделі."""

    def __init__(self) -> None:
        self.models: dict[int, BKT] = {}

    def fit(self, sequences_by_skill: dict) -> "MultiSkillBKT":
        for skill, seqs in sequences_by_skill.items():
            self.models[skill] = BKT().fit(seqs)
        return self

    def predict_next_correct(self, skill: int, obs) -> float:
        model = self.models.get(skill) or BKT()
        return model.predict_next_correct(obs)
