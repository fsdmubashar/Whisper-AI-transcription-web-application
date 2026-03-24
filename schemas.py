"""
Pydantic Schemas - Request/Response Validation
API ke input/output ka structure define karta hai
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class TranscriptionResponse(BaseModel):
    """
    API response ka format - client ko yahi milega
    """
    id:           int
    filename:     str
    transcript:   str
    language:     str
    file_size_kb: float
    created_at:   datetime

    class Config:
        # SQLAlchemy objects ko automatically Pydantic models mein convert karo
        from_attributes = True
