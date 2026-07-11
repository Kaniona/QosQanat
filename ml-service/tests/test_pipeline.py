"""DKT құбыры + RAG ұстаз тесттері (deps орнатылғанда жұмыс істейді)."""
import json

from app.dkt.data import encode_sequence, synthetic_dataset
from app.dkt.service import DKTService
from app.tutor.rag import TutorService


def test_encode_sequence():
    seq = [(0, 1), (1, 0), (0, 1)]
    x, tgt_skill, tgt_correct, mask = encode_sequence(seq, num_skills=3)
    assert x.shape == (3, 6)
    # бірінші қадамда (тақырып 0, дұрыс=1) → индекс 0 + 3 = 3
    assert x[0, 3] == 1.0
    # соңғы қадамда мақсат жоқ
    assert mask[0] == 1.0 and mask[-1] == 0.0
    # t=0 мақсаты — t=1 интеракциясы (тақырып 1, қате)
    assert tgt_skill[0] == 1 and tgt_correct[0] == 0.0


def test_synthetic_dataset():
    seqs = synthetic_dataset(num_students=12, num_skills=5, seed=1)
    assert len(seqs) == 12
    assert all(len(s) >= 2 for s in seqs)


def test_dkt_heuristic_fallback():
    svc = DKTService(model_path=None, num_skills=5)
    assert svc.ready is False
    mastery = svc.predict_mastery([(0, 1), (0, 1), (1, 0)])
    assert mastery.shape == (5,)
    # 0-тақырып дұрыс жауаптар → 1-тақырыптан жоғары меңгеру
    assert mastery[0] > mastery[1]
    weak = svc.recommend([(0, 1), (0, 1), (1, 0)], k=2)
    assert len(weak) == 2


def test_tutor_grounded(tmp_path):
    path = tmp_path / "lessons.json"
    path.write_text(
        json.dumps(
            [
                {"title": "Септік жалғаулары", "intro": "Қазақ тілінде 7 септік бар"},
                {"title": "Present Perfect", "intro": "have/has + V3"},
            ],
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    tutor = TutorService(str(path))
    res = tutor.ask("септік дегеніміз не?")
    assert res["grounded"] is True
    assert "Септік" in res["source_title"]
