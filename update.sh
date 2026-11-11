#!/bin/bash
# ==============================================================
# update.sh — Script de Atualização e Deploy Swarm (Mac mini)
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

# ── 0. Garantir que o Colima (VM Docker) está rodando ─────────
if ! docker info >/dev/null 2>&1; then
    echo "🐳 Iniciando VM Colima..."
    colima start
fi

# ── 1. Git Pull ───────────────────────────────────────────────
echo "📥 1. Sincronizando com o GitHub..."
cd /Users/rhmorais/Defesa
git checkout -- docker-compose.yml 2>/dev/null || true
git pull origin master
echo "✅ Código atualizado."
echo ""

# ── 2. Desativar daemons legados e containers standalone ──────
echo "🧹 2. Limpando serviços legados fora do Swarm..."
mkdir -p ~/Library/LaunchAgents.disabled
for plist in com.defesacivil.spring.plist com.defesacivil.web.plist homebrew.mxcl.postgresql@15.plist; do
    if [ -f ~/Library/LaunchAgents/$plist ]; then
        launchctl unload ~/Library/LaunchAgents/$plist 2>/dev/null || true
        mv ~/Library/LaunchAgents/$plist ~/Library/LaunchAgents.disabled/ 2>/dev/null || true
    fi
done
docker-compose down 2>/dev/null || true
echo "✅ Ambiente limpo."
echo ""

# ── 3. Build Flutter Web ──────────────────────────────────────
echo "🌐 3. Compilando Flutter Web nativamente..."
flutter build web --release --base-href /
echo "✅ Flutter Web compilado."
echo ""

# ── 4. Build das 3 imagens Docker customizadas (Dockerfiles) ──
echo "🐳 4. Construindo imagens customizadas (DB, Backend, Frontend)..."
docker build -t defesacivil-db:latest ./docker/postgres
docker build -t defesacivil-backend:latest ./defesa-backend
docker build -t defesacivil-frontend:latest -f Dockerfile.flutter .
echo "✅ Imagens construídas."
echo ""

# ── 5. Inicializar Swarm (se necessário) e fazer Deploy ───────
echo "🐝 5. Fazendo deploy da Stack no Docker Swarm..."
swarm_status=$(docker info --format '{{.Swarm.LocalNodeState}}')
if [ "$swarm_status" = "inactive" ]; then
    docker swarm init
fi
bash /Users/rhmorais/Defesa/scripts/setup-swarm-workers.sh   # garante 3 nos + envia imagens novas aos workers
docker stack deploy -c /Users/rhmorais/Defesa/docker-compose.yml defesacivil
echo "✅ Stack 'defesacivil' publicada no Swarm."
echo ""

# ── 6. Cloudflare Tunnel ──────────────────────────────────────
echo "🌍 6. Verificando Túnel do Cloudflare..."
cp /Users/rhmorais/Defesa/scripts/cloudflare-config.yml ~/.cloudflared/config.yml 2>/dev/null || true
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.defesacivil.tunnel.plist 2>/dev/null || true
sleep 2
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.defesacivil.tunnel.plist 2>/dev/null || true
echo "✅ Túnel ativo."
echo ""

# ── 7. Aguardar inicialização ─────────────────────────────────
echo "⏳ 7. Aguardando réplicas do Swarm convergirem (~45s)..."
sleep 45

echo "=========================================="
echo "📊 STATUS DO CLUSTER DOCKER SWARM"
echo "=========================================="
docker node ls
echo ""
docker service ls

echo ""
echo "=========================================="
echo "✅ ATUALIZAÇÃO CONCLUÍDA!"
echo "   🌐 Frontend   : https://defesa.rhprogramer.com.br (porta 8000)"
echo "   🔌 API        : https://api.rhprogramer.com.br    (porta 8080)"
echo "   🖼️ Fotos      : https://fotos.rhprogramer.com.br  (porta 9000)"
echo "   📊 Visualizer : http://100.98.5.110:8081          (porta 8081)"
echo "=========================================="
