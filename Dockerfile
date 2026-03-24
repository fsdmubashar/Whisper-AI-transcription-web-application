# ══════════════════════════════════════════════════════════════════
#  MULTI-STAGE DOCKERFILE
#  Stage 1 (builder): Dependencies install karo
#  Stage 2 (production): Sirf zaruri cheezein copy karo → chota image
# ══════════════════════════════════════════════════════════════════

# ── STAGE 1: Builder ──────────────────────────────────────────────
FROM python:3.10-slim AS builder

# System dependencies (build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Requirements pehle copy karo (Docker cache optimization ke liye)
# Agar requirements.txt nahi badla, pip install dubara nahi chalega
COPY requirements.txt .

# Virtual environment banao (production best practice)
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Dependencies install karo
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# OpenAI Whisper install karo (GitHub se, latest version)
RUN pip install --no-cache-dir "git+https://github.com/openai/whisper.git"


# ── STAGE 2: Production ───────────────────────────────────────────
FROM python:3.10-slim AS production

# Runtime dependencies (ffmpeg audio processing ke liye ZARURI)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Non-root user banao (Security best practice)
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Builder stage se virtual environment copy karo
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Application code copy karo
COPY main.py database.py models.py schemas.py gunicorn.conf.py ./
COPY static/ ./static/

# Data directory banao database ke liye
RUN mkdir -p /app/data && chown -R appuser:appuser /app

# Non-root user pe switch karo
USER appuser

# Port expose karo
EXPOSE 8000

# Health check (Docker/Kubernetes liveness probe ke liye)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Production server start karo: Gunicorn + UvicornWorker
CMD ["gunicorn", "main:app", \
     "--config", "gunicorn.conf.py"]
