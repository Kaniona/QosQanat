"""API сұраныс/жауап сұлбалары (pydantic v2)."""
from __future__ import annotations

from pydantic import BaseModel, Field


class Interaction(BaseModel):
    skill: int = Field(ge=0, description="тақырып индексі")
    correct: int = Field(ge=0, le=1, description="дұрыс=1, қате=0")


class PredictRequest(BaseModel):
    interactions: list[Interaction] = Field(default_factory=list)
    top_k: int = Field(default=3, ge=1, le=20)


class SkillScore(BaseModel):
    skill: int
    mastery: float


class PredictResponse(BaseModel):
    mastery: list[float]
    weakest: list[SkillScore]
    dkt_ready: bool


class TutorRequest(BaseModel):
    question: str = Field(min_length=1, max_length=500)
    grade: int = Field(default=8, ge=1, le=11)


class TutorResponse(BaseModel):
    answer: str
    source_title: str | None = None
    grounded: bool
    score: float = 0.0


class Candidate(BaseModel):
    skill: int
    mastery: float = 0.5
    prob_correct: float = 0.5
    due_ratio: float = 0.0
    seen: bool = False


class RecommendRequest(BaseModel):
    candidates: list[Candidate] = Field(default_factory=list)
    top_k: int = Field(default=5, ge=1, le=20)


class RecommendItem(BaseModel):
    skill: int
    score: float


class RecommendResponse(BaseModel):
    recommendations: list[RecommendItem]


class SpacingRequest(BaseModel):
    n_correct: int = Field(ge=0, default=0)
    n_incorrect: int = Field(ge=0, default=0)
    target_recall: float = Field(default=0.9, gt=0.0, lt=1.0)


class SpacingResponse(BaseModel):
    interval_days: float
    half_life_days: float


class GradeRequest(BaseModel):
    student_answer: str = Field(min_length=1, max_length=1000)
    correct_answer: str = Field(min_length=1, max_length=1000)
    accept: float = Field(default=0.7, gt=0.0, lt=1.0)


class GradeResponse(BaseModel):
    score: float
    verdict: str
    feedback: str


class ReadinessRequest(BaseModel):
    mastery: list[float] = Field(default_factory=list)
    target: float = Field(default=0.8, gt=0.0, lt=1.0)


class ReadinessResponse(BaseModel):
    readiness: float
    ready_topics: int
    total: int
    days_to_ready: float | None = None
