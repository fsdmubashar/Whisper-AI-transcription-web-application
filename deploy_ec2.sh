#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  EC2 Direct Deployment Script (Step 1 - No Docker)
#  Amazon Linux 2 / Ubuntu 22.04 pe run karo
#  Usage: chmod +x deploy_ec2.sh && ./deploy_ec2.sh
# ══════════════════════════════════════════════════════════════════

set -e  # Koi bhi command fail hone pe script rok do

echo "============================================"
echo "  Whisper Transcription App - EC2 Setup"
echo "============================================"

# ── 1. System Update ──────────────────────────────────
echo "[1/8] System update kar raha hai..."
sudo apt-get update -y && sudo apt-get upgrade -y

# ── 2. System Dependencies ────────────────────────────
echo "[2/8] Dependencies install kar raha hai..."
sudo apt-get install -y \
    python3.10 \
    python3.10-venv \
    python3-pip \
    git \
    ffmpeg \
    nginx \
    curl

# ── 3. App Directory ──────────────────────────────────
echo "[3/8] App directory bana raha hai..."
sudo mkdir -p /opt/whisper-app
sudo chown $USER:$USER /opt/whisper-app
cd /opt/whisper-app

# ── 4. Clone Repository ───────────────────────────────
echo "[4/8] Code clone kar raha hai..."
# Agar already cloned hai toh pull karo
if [ -d ".git" ]; then
    git pull origin main
else
    git clone https://github.com/YOUR_USERNAME/whisper-transcription.git .
fi

# ── 5. Virtual Environment ────────────────────────────
echo "[5/8] Python virtual environment setup kar raha hai..."
python3 -m venv venv
source venv/bin/activate

# ── 6. Python Dependencies ────────────────────────────
echo "[6/8] Python packages install kar raha hai (this may take a while)..."
pip install --upgrade pip
pip install -r requirements.txt
pip install "git+https://github.com/openai/whisper.git"

# ── 7. Environment File ───────────────────────────────
echo "[7/8] Environment setup kar raha hai..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "  ⚠️  .env file banayi gayi. Zaruri values edit karo: nano .env"
fi

# ── 8. Systemd Service ────────────────────────────────
echo "[8/8] Systemd service create kar raha hai..."
sudo tee /etc/systemd/system/whisper-app.service > /dev/null <<EOF
[Unit]
Description=Whisper Transcription App (Gunicorn)
After=network.target

[Service]
User=$USER
WorkingDirectory=/opt/whisper-app
EnvironmentFile=/opt/whisper-app/.env
ExecStart=/opt/whisper-app/venv/bin/gunicorn main:app --config gunicorn.conf.py
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Nginx config copy karo
sudo cp nginx/nginx.conf /etc/nginx/conf.d/whisper.conf
sudo nginx -t && sudo systemctl reload nginx

# Service enable aur start karo
sudo systemctl daemon-reload
sudo systemctl enable whisper-app
sudo systemctl start whisper-app

echo ""
echo "============================================"
echo "  ✅ Deployment Complete!"
echo "  App URL: http://$(curl -s ifconfig.me)"
echo "  Status:  sudo systemctl status whisper-app"
echo "  Logs:    sudo journalctl -u whisper-app -f"
echo "============================================"
