#!/bin/bash
# ==============================================================
# update.sh — Script de Atualização do Servidor (Mac mini)
# ==============================================================

set -e

export PATH="/usr/local/bin:/usr/local/share/flutter/bin:/opt/homebrew/bin:$PATH"
source ~/.zprofile 2>/dev/null || true
source ~/.zshrc 2>/dev/null || true

echo "=========================================="
echo "🚀 INICIANDO ATUALIZAÇÃO — DEFESA EM FOCO"
echo "=========================================="
echo "⏰ $(date '+%d/%m/%Y %H:%M:%S')"
echo ""

# ── 1. Git Pull ───────────────────────────────────────────────
echo "📥 1. Sincronizando com o GitHub..."
cd /Users/rhmorais/Defesa
git checkout -- docker-compose.yml 2>/dev/null || true
git pull origin master
echo "✅ Código atualizado."
echo ""

# ── 2. Derrubar containers antigos ───────────────────────────
echo "🧹 2. Derrubando containers antigos..."
launchctl unload ~/Library/LaunchAgents/com.defesacivil.spring.plist 2>/dev/null || true
launchctl unload ~/Library/LaunchAgents/com.defesacivil.web.plist 2>/dev/null || true
launchctl unload ~/Library/LaunchAgents/com.defesacivil.tunnel.plist 2>/dev/null || true
docker-compose down 2>/dev/null || true
sleep 3
echo "✅ Containers derrubados."
echo ""

# ── 3. Build Flutter Web ──────────────────────────────────────
echo "🌐 3. Compilando Flutter Web nativamente..."
flutter build web --release --base-href /
echo "✅ Flutter Web compilado."
echo ""

# ── 4. Build e subida dos containers ─────────────────────────
echo "🐳 4. Reconstruindo imagens e subindo containers..."
docker-compose up -d --build
echo "✅ Containers no ar."
echo ""

# ── 5. Cloudflare Tunnel ──────────────────────────────────────
echo "🌍 5. Reiniciando o Túnel do Cloudflare..."
cp /Users/rhmorais/Defesa/scripts/cloudflare-config.yml ~/.cloudflared/config.yml 2>/dev/null || true
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.defesacivil.tunnel.plist 2>/dev/null || true
sleep 2
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.defesacivil.tunnel.plist
echo "✅ Túnel reiniciado."
echo ""

# ── 6. Aguardar inicialização ─────────────────────────────────
echo "⏳ 6. Aguardando serviços inicializarem (~60s)..."
sleep 60

echo "=========================================="
echo "📊 STATUS DOS CONTAINERS"
echo "=========================================="
docker-compose ps

echo ""
echo "=========================================="
echo "✅ ATUALIZAÇÃO CONCLUÍDA!"
echo "   🌐 Frontend : https://defesa.rhprogramer.com.br"
echo "   🔌 API      : https://api.rhprogramer.com.br"
echo "   🖼️ Fotos    : https://fotos.rhprogramer.com.br"
echo "=========================================="
