"""QosQanat ML микросервисі (FastAPI).

Эндпоинттер:
  GET  /health        — күй
  POST /dkt/predict   — оқушы тарихынан меңгеру болжамы + әлсіз тақырыптар
  POST /tutor/ask     — оқу бағдарламасына негізделген AI ұстаз (RAG)

Қосымша OFFLINE-FIRST: бұл сервис — БОНУС (онлайн болғанда күштірек адаптив +
семантикалық ұстаз). Жетпесе, қосымша өзінің офлайн логикасымен жұмыс істей береді.
"""
from __future__ import annotations

import os
from pathlib import Path

from fastapi import FastAPI

from .dkt.service import DKTService
from .forecast.readiness import ReadinessForecaster
from .models.spacing import HalfLifeRegression, review_features
from .nlp.grading import AnswerGrader
from .recommend import AdaptiveRecommender
from .schemas import (
    GradeRequest,
    GradeResponse,
    PredictRequest,
    PredictResponse,
    ReadinessRequest,
    ReadinessResponse,
    RecommendItem,
    RecommendRequest,
    RecommendResponse,
    SkillScore,
    SpacingRequest,
    SpacingResponse,
    TutorRequest,
    TutorResponse,
)
from .tutor.rag import TutorService

BASE = Path(__file__).resolve().parent
MODEL_PATH = os.getenv("DKT_MODEL", str(BASE.parent / "model.pt"))
LESSONS_PATH = os.getenv("LESSONS_JSON", str(BASE / "data" / "lessons.sample.json"))
NUM_SKILLS = int(os.getenv("NUM_SKILLS", "98"))

app = FastAPI(
    title="QosQanat ML Service",
    version="0.1.0",
    description="Deep Knowledge Tracing (PyTorch) + curriculum-grounded RAG tutor",
)

_dkt = DKTService(model_path=MODEL_PATH, num_skills=NUM_SKILLS)
_tutor = TutorService(LESSONS_PATH)
_recommender = AdaptiveRecommender()
_grader = AnswerGrader()
_forecaster = ReadinessForecaster()
# Әдепкі HLR: жаттыққан дерек жоқта да саналы интервал береді
# (h = 2^(0.5 + √correct − 0.8·√incorrect)).
_hlr = HalfLifeRegression(n_features=3)
_hlr.theta[:] = [0.5, 1.0, -0.8]


@app.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "dkt_ready": _dkt.ready,
        "num_skills": _dkt.num_skills,
        "lessons": len(_tutor.lessons),
    }


@app.post("/dkt/predict", response_model=PredictResponse)
def predict(req: PredictRequest) -> PredictResponse:
    interactions = [(i.skill, i.correct) for i in req.interactions]
    mastery = _dkt.predict_mastery(interactions)
    weak = _dkt.recommend(interactions, k=req.top_k)
    return PredictResponse(
        mastery=[float(x) for x in mastery],
        weakest=[SkillScore(skill=s, mastery=m) for s, m in weak],
        dkt_ready=_dkt.ready,
    )


@app.post("/tutor/ask", response_model=TutorResponse)
def ask(req: TutorRequest) -> TutorResponse:
    return TutorResponse(**_tutor.ask(req.question, grade=req.grade))


@app.post("/recommend", response_model=RecommendResponse)
def recommend(req: RecommendRequest) -> RecommendResponse:
    cands = [c.model_dump() for c in req.candidates]
    ranked = _recommender.rank(cands, top_k=req.top_k)
    return RecommendResponse(
        recommendations=[RecommendItem(skill=s, score=sc) for s, sc in ranked]
    )


@app.post("/spacing/interval", response_model=SpacingResponse)
def spacing(req: SpacingRequest) -> SpacingResponse:
    x = review_features(req.n_correct, req.n_incorrect)
    half_life = float(_hlr.half_life(x.reshape(1, -1))[0])
    interval = _hlr.optimal_interval(x, target_recall=req.target_recall)
    return SpacingResponse(interval_days=interval, half_life_days=half_life)


@app.post("/nlp/grade", response_model=GradeResponse)
def grade(req: GradeRequest) -> GradeResponse:
    return GradeResponse(
        **_grader.grade(req.student_answer, req.correct_answer, accept=req.accept)
    )


@app.post("/forecast/readiness", response_model=ReadinessResponse)
def readiness(req: ReadinessRequest) -> ReadinessResponse:
    res = _forecaster.exam_readiness(req.mastery, target=req.target)
    return ReadinessResponse(
        readiness=res["readiness"],
        ready_topics=res["ready_topics"],
        total=res["total"],
        days_to_ready=res["days_to_ready"],
    )
