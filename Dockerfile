# ── STAGE 1: Builder ──────────────────────────────────────────────
FROM python:3.10-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY requirements.txt .

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Whisper install
RUN pip install --no-cache-dir "git+https://github.com/openai/whisper.git"

# ── STAGE 2: Production ───────────────────────────────────────────
FROM python:3.10-slim AS production

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# -m flag zaroori hai taake /home/appuser directory create ho jaye
RUN groupadd -r appuser && useradd -r -m -g appuser appuser

WORKDIR /app

# Whisper models ke liye directory
RUN mkdir -p /app/whisper_models /app/data && chown -R appuser:appuser /app

# Whisper ko batayein ke models yahan save karein
ENV XDG_CACHE_HOME=/app/whisper_models
ENV PATH="/opt/venv/bin:$PATH"

# Files copy karte waqt hi ownership set kar dein
COPY --from=builder --chown=appuser:appuser /opt/venv /opt/venv
COPY --chown=appuser:appuser main.py database.py models.py schemas.py gunicorn.conf.py ./
COPY --chown=appuser:appuser static/ ./static/

# Switch to non-root user
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["gunicorn", "main:app", "--config", "gunicorn.conf.py"]     