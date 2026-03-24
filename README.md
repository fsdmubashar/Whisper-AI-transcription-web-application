# 🎙️ VoiceScript: AI-Powered Transcription Portal

[![Status](https://img.shields.io/badge/Status-Live-success?style=flat-square)]()
[![Tech Stack](https://img.shields.io/badge/Stack-Python%20|%20FastAPI%20|%20Whisper-blue?style=flat-square)]()
[![DevOps](https://img.shields.io/badge/DevOps-Docker%20|%20AWS-orange?style=flat-square)]()

**VoiceScript** is a high-performance web application designed to transcribe audio and video files into text using **OpenAI's Whisper AI**. The interface is custom-designed as a **Cloud Monitoring Dashboard**, reflecting a professional DevOps engineering environment.

---

## 👤 Developed By
**Muhammad Mubashar Karamat Ali**  
*Junior Cloud DevSecOps Engineer*  
[LinkedIn](https://linkedin.com/in/mubashar-karamat) | [GitHub](https://github.com/fsdmubashar)

---

## 🚀 Key Features

- **Multi-Format Ingestion:** Supports MP3, WAV, M4A, MP4, and FLAC.
- **AI Transcription:** Powered by OpenAI Whisper for high accuracy across multiple languages.
- **DevOps Dashboard UI:** A sleek, dark-themed interface inspired by infrastructure monitoring tools (Grafana/CloudWatch).
- **Live Output Stream:** Real-time transcription logs with time-stamping.
- **Robust Clipboard Engine:** One-click "Copy All" functionality with legacy fallback for all browser environments.
- **Transcription History:** Persistent logs of previous sessions for quick reference.

---

## 🛠️ Tech Stack

- **Backend:** Python, FastAPI
- **AI Engine:** OpenAI Whisper (Base Model)
- **Frontend:** HTML5, CSS3 (Custom Grid Layout), Vanilla JavaScript
- **Deployment & Ops:** Docker, AWS EC2, Terraform (Infrastructure as Code)

---

## 📸 Dashboard Preview

> *[Note: Add your screenshot here by uploading it to GitHub and updating the link below]*
> ![Dashboard Preview](static/screenshot.png)

---

## ⚙️ Installation & Setup

### 1. Prerequisites
- Python 3.9+
- FFmpeg (Required for audio processing)
- Docker (Optional for containerized deployment)

### 2. Local Setup
```bash
# Clone the repository
git clone https://github.com/fsdmubashar/Whisper-AI-transcription-web-application.git

# Navigate to the directory
cd Whisper-AI-transcription-web-application

# Install dependencies
pip install -r requirements.txt

# Run the application
uvicorn main:app --reload
