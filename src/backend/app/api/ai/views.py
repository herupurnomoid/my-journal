from fastapi import APIRouter, Depends
from app.api.ai.schemas import AnalyzeMoodRequest, AnalyzeMoodResponse, WeeklyInsightsRequest, WeeklyInsightsResponse
from app.api.ai.use_cases import AIUseCases
from app.api.standard_response import StandardResponse, success_response
from app.api.dependencies import get_current_user

ai_router = APIRouter(tags=["Artificial Intelligence"])

@ai_router.post("/analyze-mood", response_model=StandardResponse[AnalyzeMoodResponse])
async def analyze_mood(
    payload: AnalyzeMoodRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Endpoint untuk menganalisis judul dan konten jurnal menggunakan Gemini AI.
    Membutuhkan autentikasi Bearer token (Kecuali di environment development).
    """
    ai_result = AIUseCases.analyze_mood(payload.title, payload.content)
    return success_response(data=ai_result)

@ai_router.post("/weekly-insights", response_model=StandardResponse[WeeklyInsightsResponse])
async def weekly_insights(
    payload: WeeklyInsightsRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Endpoint untuk merangkum dan mengevaluasi kumpulan jurnal mingguan menggunakan AI.
    Membutuhkan list dari object jurnal yang terdiri dari title dan content.
    """
    ai_result = AIUseCases.get_weekly_insights(payload.journals)
    return success_response(data=ai_result)
