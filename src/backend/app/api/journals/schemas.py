from pydantic import BaseModel
from typing import List, Optional

class ExportJournalEntry(BaseModel):
    title: str
    content: str
    date: str
    userMood: Optional[str] = None

class ExportJournalRequest(BaseModel):
    journals: List[ExportJournalEntry]

class ExportJournalResponse(BaseModel):
    downloadUrl: str
