# # ── STAGE 1: Builder ──────────────────────────────────────────────
# FROM python:3.10-slim AS builder

# RUN apt-get update && apt-get install -y --no-install-recommends \
#     git \
#     build-essential \
#     && rm -rf /var/lib/apt/lists/*

# WORKDIR /build

# COPY requirements.txt .

# RUN python -m venv /opt/venv
# ENV PATH="/opt/venv/bin:$PATH"

# RUN pip install --upgrade pip && \
#     pip install --no-cache-dir -r requirements.txt

# # Whisper install
# RUN pip install --no-cache-dir "git+https://github.com/openai/whisper.git"

# # ── STAGE 2: Production ───────────────────────────────────────────
# FROM python:3.10-slim AS production

# RUN apt-get update && apt-get install -y --no-install-recommends \
#     ffmpeg \
#     && rm -rf /var/lib/apt/lists/*

# # -m flag zaroori hai taake /home/appuser directory create ho jaye
# RUN groupadd -r appuser && useradd -r -m -g appuser appuser

# WORKDIR /app

# # Whisper models ke liye directory
# RUN mkdir -p /app/whisper_models /app/data && chown -R appuser:appuser /app

# # Whisper ko batayein ke models yahan save karein
# ENV XDG_CACHE_HOME=/app/whisper_models
# ENV PATH="/opt/venv/bin:$PATH"

# # Files copy karte waqt hi ownership set kar dein
# COPY --from=builder --chown=appuser:appuser /opt/venv /opt/venv
# COPY --chown=appuser:appuser main.py database.py models.py schemas.py gunicorn.conf.py ./
# COPY --chown=appuser:appuser static/ ./static/

# # Switch to non-root user
# USER appuser

# EXPOSE 8000

# HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
#     CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# CMD ["gunicorn", "main:app", "--config", "gunicorn.conf.py"]     


# ── STAGE 1: Builder ──────────────────────────────────────────────
FROM python:3.10-slim AS builder

# System dependencies for building
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Requirements copy karein
COPY requirements.txt .

# Virtual environment setup
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Dependencies install karein (NumPy 1.x pin hai requirements mein)
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Whisper install karein
RUN pip install --no-cache-dir "git+https://github.com/openai/whisper.git"

# ── STAGE 2: Production ───────────────────────────────────────────
FROM python:3.10-slim AS production

# Runtime dependencies (ffmpeg zaroori hai)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Non-root user with home directory (-m flag is CRITICAL)
RUN groupadd -r appuser && useradd -r -m -g appuser appuser

WORKDIR /app

# Environment Variables
ENV PATH="/opt/venv/bin:$PATH"
ENV HOME=/home/appuser
ENV XDG_CACHE_HOME=/app/data/.cache
ENV PYTHONUNBUFFERED=1

# Builder se venv copy karein
COPY --from=builder /opt/venv /opt/venv

# Application files copy karein
COPY main.py database.py models.py schemas.py gunicorn.conf.py ./
COPY static/ ./static/

# Sabse important: Directories banayein aur permissions set karein
# Humne /app aur /home/appuser dono ka malik appuser ko bana diya hai
RUN mkdir -p /app/data/.cache /app/whisper_models && \
    chown -R appuser:appuser /app /home/appuser

# Switch to non-root user
USER appuser

# Port expose
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Start Command
CMD ["gunicorn", "main:app", "--config", "gunicorn.conf.py"]