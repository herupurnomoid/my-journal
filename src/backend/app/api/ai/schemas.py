from pydantic import BaseModel
from typing import List

class AnalyzeMoodRequest(BaseModel):
    title: str
    content: str

class AnalyzeMoodResponse(BaseModel):
    primaryMood: str
    stressLevel: int
    happinessLevel: int
    emotionSummary: str
    recommendations: List[str]

class JournalEntry(BaseModel):
    title: str
    content: str

class WeeklyInsightsRequest(BaseModel):
    journals: List[JournalEntry]

class WeeklyInsightsResponse(BaseModel):
    weeklySummary: str
