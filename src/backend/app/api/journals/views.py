from fastapi import APIRouter, Depends
from app.api.journals.schemas import ExportJournalRequest, ExportJournalResponse
from app.api.journals.use_cases import JournalUseCases
from app.api.standard_response import StandardResponse, success_response
from app.api.dependencies import get_current_user

journal_router = APIRouter(tags=["Journals"])

@journal_router.post("/export", response_model=StandardResponse[ExportJournalResponse])
async def export_journals(
    payload: ExportJournalRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Endpoint untuk merender sekumpulan jurnal menjadi file PDF dan menyimpannya di Cloud.
    Mengembalikan tautan unduh (Signed URL) yang berlaku selama 1 jam.
    """
    user_id = current_user.get("uid", "anonymous")
    
    download_url = JournalUseCases.export_to_pdf(user_id, payload.journals)
    
    return success_response(data=ExportJournalResponse(downloadUrl=download_url))
