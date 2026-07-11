"""Оқушыларды сегменттеу — қабілеті/қарқыны бойынша топтарға бөлу (KMeans).
Мұғалімге «кімге қандай көмек» керегін көрсетеді. sklearn болмаса — таза
NumPy KMeans (Lloyd) қолданылады (graceful)."""
from __future__ import annotations

import numpy as np


class StudentSegmenter:
    def __init__(self, n_clusters: int = 4, seed: int = 0) -> None:
        self.n_clusters = n_clusters
        self.seed = seed
        self.centroids = None
        self.labels_ = None

    def fit(self, x: np.ndarray) -> "StudentSegmenter":
        x = np.asarray(x, dtype=np.float64)
        try:
            from sklearn.cluster import KMeans

            km = KMeans(n_clusters=self.n_clusters, random_state=self.seed, n_init=10)
            self.labels_ = km.fit_predict(x)
            self.centroids = km.cluster_centers_
            return self
        except Exception:
            return self._fit_numpy(x)

    def _fit_numpy(self, x: np.ndarray, iters: int = 50) -> "StudentSegmenter":
        rng = np.random.default_rng(self.seed)
        k = min(self.n_clusters, len(x))
        idx = rng.choice(len(x), size=k, replace=False)
        cents = x[idx].copy()
        labels = np.zeros(len(x), dtype=int)
        for _ in range(iters):
            d = ((x[:, None, :] - cents[None, :, :]) ** 2).sum(axis=2)
            new = d.argmin(axis=1)
            if np.array_equal(new, labels):
                break
            labels = new
            for c in range(k):
                if (labels == c).any():
                    cents[c] = x[labels == c].mean(axis=0)
        self.labels_, self.centroids = labels, cents
        return self

    def describe(self, accuracy_idx: int = 1) -> list:
        """Әр кластерді дәлдік центроиді бойынша белгілеу (жоғары→төмен)."""
        if self.centroids is None:
            return []
        order = np.argsort(-self.centroids[:, accuracy_idx])
        names = ["Озат", "Орташа", "Қолдау қажет", "Тәуекел тобы"]
        out = {}
        for rank, c in enumerate(order):
            out[int(c)] = names[min(rank, len(names) - 1)]
        return [out[int(lbl)] for lbl in self.labels_]
