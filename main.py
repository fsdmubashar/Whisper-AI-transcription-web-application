"""
Whisper Transcription API - Main Application
FastAPI + Gunicorn + OpenAI Whisper
"""

import os
import tempfile
import torch
import whisper
from typing import List

from fastapi import FastAPI, File, UploadFile, HTTPException, Depends
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse
from sqlalchemy.orm import Session
from dotenv import load_dotenv

import models
import schemas
from database import SessionLocal, engine

# .env file load karo
load_dotenv()

# Database tables create karo (agar exist nahi karte)
models.Base.metadata.create_all(bind=engine)

# ─── FastAPI App Instance ───────────────────────────────────────────────────
app = FastAPI(
    title="Whisper Voice Transcription API",
    description="Multiple audio files ko text mein convert karo using OpenAI Whisper",
    version="1.0.0",
)

# ─── Whisper Model Load ──────────────────────────────────────────────────────
# GPU available hai toh CUDA, warna CPU use karo
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# .env se model size lo, default "base"
# Options: tiny, base, small, medium, large
MODEL_SIZE = os.getenv("WHISPER_MODEL_SIZE", "base")

print(f"[INFO] Loading Whisper model '{MODEL_SIZE}' on device '{DEVICE}'...")
whisper_model = whisper.load_model(MODEL_SIZE, device=DEVICE)
print(f"[INFO] Model loaded successfully!")

# Supported audio formats
ALLOWED_EXTENSIONS = {".mp3", ".wav", ".m4a", ".ogg", ".flac", ".mp4", ".webm"}

# ─── Static Files (Frontend) ─────────────────────────────────────────────────
app.mount("/static", StaticFiles(directory="static"), name="static")


# ─── Database Dependency ──────────────────────────────────────────────────────
def get_db():
    """
    Database session generator.
    Har request ke liye ek nayi DB session banao, kaam khatam hone pe band karo.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ─── Routes ───────────────────────────────────────────────────────────────────

@app.get("/", response_class=HTMLResponse, tags=["Frontend"])
async def serve_frontend():
    """
    Root URL pe frontend HTML serve karo.
    """
    with open("static/index.html", encoding="utf-8") as f:
        return HTMLResponse(content=f.read())


@app.get("/health", tags=["Health"])
async def health_check():
    """
    Application health check - deployment verification ke liye.
    """
    return {
        "status": "healthy",
        "device": DEVICE,
        "whisper_model": MODEL_SIZE,
        "cuda_available": torch.cuda.is_available(),
    }


@app.post(
    "/transcribe",
    response_model=List[schemas.TranscriptionResponse],
    tags=["Transcription"],
    summary="Audio files transcribe karo",
)
async def transcribe_audio(
    files: List[UploadFile] = File(..., description="Audio files (mp3, wav, m4a, etc.)"),
    translate: bool = False,
    db: Session = Depends(get_db),
):

    """
    Multiple audio files upload karo aur text transcript hasil karo.
    Database mein save hota hai history ke liye.
    """
    if not files:
        raise HTTPException(status_code=400, detail="Koi file nahi di gayi.")

    results = []

    for file in files:
        # File extension check karo
        ext = os.path.splitext(file.filename)[1].lower()
        if ext not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=400,
                detail=f"'{file.filename}' unsupported format hai. Allowed: {ALLOWED_EXTENSIONS}",
            )

        # Temporary file mein save karo (disk pe likhna zarori hai Whisper ke liye)
        with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name

        try:
            # Whisper se transcribe karo
            task = "translate" if translate else "transcribe"
	    result = whisper_model.transcribe(tmp_path, task=task)

            # Database mein save karo
            db_record = models.Transcription(
                filename=file.filename,
                transcript=result["text"].strip(),
                language=result.get("language", "unknown"),
                file_size_kb=round(len(content) / 1024, 2),
            )
            db.add(db_record)
            db.commit()
            db.refresh(db_record)

            results.append(db_record)

        finally:
            # Temp file delete karo (cleanup)
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    return results


@app.get(
    "/history",
    response_model=List[schemas.TranscriptionResponse],
    tags=["History"],
    summary="Purani transcriptions dekho",
)
async def get_history(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
):
    """
    Database se transcription history retrieve karo.
    Pagination support hai (skip aur limit).
    """
    records = (
        db.query(models.Transcription)
        .order_by(models.Transcription.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return records


@app.delete(
    "/transcription/{record_id}",
    tags=["History"],
    summary="Transcription delete karo",
)
async def delete_transcription(record_id: int, db: Session = Depends(get_db)):
    """
    ID se specific transcription record delete karo.
    """
    record = (
        db.query(models.Transcription)
        .filter(models.Transcription.id == record_id)
        .first()
    )
    if not record:
        raise HTTPException(status_code=404, detail="Record nahi mila.")

    db.delete(record)
    db.commit()
    return {"message": f"Record #{record_id} delete ho gaya."}
