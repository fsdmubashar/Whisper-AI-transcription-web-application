# 🎙 VoiceScript AI — Whisper Transcription Web Application

A production-grade, containerized audio transcription web application powered by **OpenAI Whisper**, deployed on **AWS EC2** with **Nginx** as a reverse proxy and **Gunicorn** as the WSGI server.

---

## 👤 Author

**Muhammad Mubashar Karamat Ali**  
Junior Cloud DevSecOps Engineer  
`AWS` · `Terraform` · `Jenkins` · `Docker` · `GitHub Actions` · `Python` · `FastAPI`

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| AI Model | OpenAI Whisper (base) |
| Backend | Python 3.10 + FastAPI |
| WSGI Server | Gunicorn + UvicornWorker |
| Database | SQLite (via SQLAlchemy ORM) |
| Reverse Proxy | Nginx |
| Containerization | Docker (Multi-stage Dockerfile) |
| Infrastructure | AWS EC2 (Ubuntu 22.04) |
| CI/CD | GitHub Actions |
| Frontend | HTML5 · CSS3 · Vanilla JS |

---

## ✨ Features

- 🎵 **Multi-file upload** — MP3, WAV, M4A, OGG, FLAC, MP4, WebM
- 🌍 **Auto language detection** — Urdu, English, Arabic and 90+ languages
- 📜 **Transcription history** — Stored in SQLite with delete support
- 📋 **Copy to clipboard** — One-click copy all results
- 🔁 **Auto-restart** — Systemd service with restart on failure
- 🏥 **Health check endpoint** — `/health` for monitoring

---

## 📁 Project Structure

```
whisper-transcription/
├── main.py                    # FastAPI application (core logic)
├── database.py                # SQLAlchemy DB configuration
├── models.py                  # Database table definitions
├── schemas.py                 # Pydantic request/response schemas
├── gunicorn.conf.py           # Production Gunicorn configuration
├── requirements.txt           # Python dependencies
├── Dockerfile                 # Multi-stage Docker build
├── docker-compose.yml         # Full stack (App + Nginx)
├── .env.example               # Environment variables template
├── static/
│   ├── index.html             # Frontend UI
│   ├── style.css              # Dark terminal theme
│   └── script.js             # File upload + API integration
├── nginx/
│   └── nginx.conf             # Reverse proxy configuration
├── scripts/
│   └── deploy_ec2.sh          # Automated EC2 setup script
└── .github/
    └── workflows/
        └── deploy.yml         # GitHub Actions CI/CD pipeline
```

---

## 🚀 Deployment — 3 Methods

### Method 1: Direct EC2 (No Docker)

```bash
# 1. SSH into EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# 2. Install dependencies
sudo apt-get update -y
sudo apt-get install -y python3.10 python3.10-venv git ffmpeg nginx

# 3. Clone & setup
cd /opt && sudo mkdir whisper-app && sudo chown ubuntu:ubuntu whisper-app && cd whisper-app
git clone https://github.com/fsdmubashar/Whisper-AI-transcription-web-application.git .

# 4. Virtual environment
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
pip install "git+https://github.com/openai/whisper.git"

# 5. Configure & start
cp .env.example .env
sudo cp nginx/nginx.conf /etc/nginx/conf.d/whisper.conf
sudo systemctl restart nginx

# 6. Create systemd service & start
sudo systemctl enable whisper-app
sudo systemctl start whisper-app
```

---

### Method 2: Docker Compose (Multi-stage)

```bash
# Clone repo
git clone https://github.com/fsdmubashar/Whisper-AI-transcription-web-application.git
cd Whisper-AI-transcription-web-application

# Environment setup
cp .env.example .env

# Build & run
docker-compose up -d --build

# Verify
curl http://localhost/health
```

---

### Method 3: GitHub Actions CI/CD

Set these **GitHub Secrets** (Settings → Secrets → Actions):

| Secret | Value |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `EC2_HOST` | EC2 Public IP |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_KEY` | Contents of `.pem` file |

```bash
# Push to main → Pipeline triggers automatically
git push origin main
```

**Pipeline flow:**
```
Code Push → Build Docker Image → Push to Docker Hub → SSH to EC2 → Deploy Container → Health Check ✅
```

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Frontend UI |
| `GET` | `/health` | Health check |
| `POST` | `/transcribe` | Upload & transcribe audio files |
| `GET` | `/history` | Fetch transcription history |
| `DELETE` | `/transcription/{id}` | Delete a record |
| `GET` | `/docs` | Swagger API documentation |

---

## ⚙️ Environment Variables

```env
WHISPER_MODEL_SIZE=base        # tiny | base | small | medium | large
PORT=8000
LOG_LEVEL=info
GUNICORN_WORKERS=2
DATABASE_URL=sqlite:///./transcriptions.db
```

---

## 🏗️ Architecture Diagram

```
                         ┌─────────────────────────────┐
                         │         AWS EC2              │
                         │      (Ubuntu 22.04)          │
                         │                              │
Internet ──── Port 80 ──►│   NGINX (Reverse Proxy)      │
                         │          │                   │
                         │          ▼                   │
                         │  Gunicorn (Port 8000)        │
                         │    UvicornWorker             │
                         │          │                   │
                         │          ▼                   │
                         │  FastAPI Application         │
                         │          │                   │
                         │    ┌─────┴──────┐            │
                         │    ▼            ▼            │
                         │ Whisper      SQLite DB       │
                         │ AI Model   (transcriptions)  │
                         └─────────────────────────────┘
```

---

## 📝 License

MIT License — Free to use for learning and personal projects.

---

> **Note:** Monitoring, model versioning, and pipeline orchestration (MLflow, Airflow) are planned for a separate project.
