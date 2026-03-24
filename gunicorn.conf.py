"""
Gunicorn Configuration File
Production-grade server settings
"""

import multiprocessing
import os

# ─── Server Socket ──────────────────────────────────────────────────────────
bind      = f"0.0.0.0:{os.getenv('PORT', '8000')}"
backlog   = 2048   # Queue mein wait karne wale connections ki max tadaad

# ─── Worker Processes ────────────────────────────────────────────────────────
# Formula: (2 × CPU cores) + 1
# FastAPI ASGI hai, isliye UvicornWorker use karna ZARURI hai
workers        = int(os.getenv("GUNICORN_WORKERS", multiprocessing.cpu_count() * 2 + 1))
worker_class   = "uvicorn.workers.UvicornWorker"   # ASGI support
worker_connections = 1000
timeout        = 120    # Whisper ko time lagta hai, isliye timeout zyada rakho
keepalive      = 5
max_requests   = 1000   # Memory leak se bachne ke liye worker restart
max_requests_jitter = 100

# ─── Logging ────────────────────────────────────────────────────────────────
accesslog  = "-"        # stdout pe print karo (Docker ke liye best practice)
errorlog   = "-"        # stderr pe print karo
loglevel   = os.getenv("LOG_LEVEL", "info")
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

# ─── Process Naming ─────────────────────────────────────────────────────────
proc_name = "whisper-transcription"

# ─── Security ───────────────────────────────────────────────────────────────
limit_request_line   = 4094
limit_request_fields = 100
