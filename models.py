"""
Database Models - SQLAlchemy ORM
Database table ka Python representation
"""

from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, Float, DateTime
from database import Base


class Transcription(Base):
    """
    Transcription table:
    Har audio file ki transcription yahan store hogi.
    """
    __tablename__ = "transcriptions"

    id           = Column(Integer, primary_key=True, index=True, autoincrement=True)
    filename     = Column(String(255), nullable=False)           # Original file naam
    transcript   = Column(Text, nullable=False)                  # Transcribed text
    language     = Column(String(50), default="unknown")         # Detected language
    file_size_kb = Column(Float, default=0.0)                    # File size in KB
    created_at   = Column(DateTime, default=datetime.utcnow)     # Upload timestamp

    def __repr__(self):
        return f"<Transcription id={self.id} file={self.filename}>"
