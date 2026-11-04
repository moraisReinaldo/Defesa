#!/bin/bash
# ==============================================================
# watchdog-defesa.sh — Auto-Boot & Health Guard (Mac mini)
# ==============================================================
# Executado automaticamente no boot/login e a cada 2 minutos via
# LaunchAgent (com.defesacivil.watchdog.plist).
# Garante:
#   1. Proteção de disco (trunca logs > 50 MB para nunca lotar o SSD)
#   2. VM Colima ativa + Docker Swarm ativo
#   3. Stack 'defesacivil' (DB, Backend x3, Frontend x2, Nginx LB, Visualizer) no ar
#   4. Portal Docker Swarm (:8090), MinIO (:9000) e Cloudflare Tunnel ativos
# ==============================================================

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
HOME_DIR="/Users/rhmorais"
DEFESA_DIR="$HOME_DIR/Defesa"
LOG_FILE="$HOME_DIR/logs/watchdog.log"

mkdir -p "$HOME_DIR/logs"

# 1. Proteção anti-disco-cheio: truncar qualquer .log > 50MB
find "$HOME_DIR/logs" /usr/local/var/log -name "*.log" -size +50M -exec truncate -s 5M {} \; 2>/dev/null || true

# 2. Garantir que os plists legados (fora do Docker) nunca subam junto
mkdir -p "$HOME_DIR/Library/LaunchAgents.disabled"
for legacy in com.defesacivil.spring.plist com.defesacivil.web.plist homebrew.mxcl.postgresql@15.plist; do
    if [ -f "$HOME_DIR/Library/LaunchAgents/$legacy" ]; then
        launchctl unload "$HOME_DIR/Library/LaunchAgents/$legacy" 2>/dev/null || true
        mv "$HOME_DIR/Library/LaunchAgents/$legacy" "$HOME_DIR/Library/LaunchAgents.disabled/" 2>/dev/null || true
    fi
done

# 3. Garantir que o Colima (Docker VM) está rodando
if ! docker info >/dev/null 2>&1; then
    echo "[$(date '+%d/%m/%Y %H:%M:%S')] [Watchdog] Colima offline. Iniciando Colima..." >> "$LOG_FILE"
    rm -f "$HOME_DIR/.colima/_lima/colima/"*.pid "$HOME_DIR/.colima/_lima/colima/"*.sock 2>/dev/null || true
    colima start >> "$LOG_FILE" 2>&1
fi

# 4. Garantir que o Docker Swarm está ativo e a stack 'defesacivil' está rodando
if docker info >/dev/null 2>&1; then
    SWARM_STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)
    if [ "$SWARM_STATE" = "inactive" ]; then
        echo "[$(date '+%d/%m/%Y %H:%M:%S')] [Watchdog] Inicializando Docker Swarm..." >> "$LOG_FILE"
        docker swarm init >> "$LOG_FILE" 2>&1
    fi

    # 4.1 Garantir cluster de 3 nos (Manager + 2 Workers DinD)
    READY_NODES=$(docker node ls --format '{{.Status}}' 2>/dev/null | grep -c Ready)
    if [ "$READY_NODES" -lt 3 ]; then
        echo "[$(date '+%d/%m/%Y %H:%M:%S')] [Watchdog] Cluster com $READY_NODES/3 nos. Subindo workers DinD..." >> "$LOG_FILE"
        bash "$DEFESA_DIR/scripts/setup-swarm-workers.sh" >> "$LOG_FILE" 2>&1
    fi

    SERVICES_COUNT=$(docker service ls --filter "name=defesacivil_" -q 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SERVICES_COUNT" -lt 5 ]; then
        echo "[$(date '+%d/%m/%Y %H:%M:%S')] [Watchdog] Stack incompleta ($SERVICES_COUNT/5). Fazendo deploy da stack defesacivil..." >> "$LOG_FILE"
        cd "$DEFESA_DIR" && docker stack deploy -c "$DEFESA_DIR/docker-compose.yml" defesacivil >> "$LOG_FILE" 2>&1
    fi
fi

# 5. Garantir Portal Docker Swarm (:8090) ativo
if ! curl -sf http://127.0.0.1:8090/healthz >/dev/null 2>&1; then
    echo "[$(date '+%d/%m/%Y %H:%M:%S')] [Watchdog] Iniciando Portal Docker Swarm (:8090)..." >> "$LOG_FILE"
    pkill -f "docker-portal/server.py" 2>/dev/null || true
    nohup python3 "$DEFESA_DIR/docker-portal/server.py" >> "$HOME_DIR/logs/docker-portal.log" 2>&1 &
fi

# 6. Garantir MinIO (:9000) ativo
if ! curl -sf http://127.0.0.1:9000/minio/health/live >/dev/null 2>&1; then
    echo "[$(date '+%d/%m/%Y %H:%M:%S')] [Watchdog] MinIO offline. Reiniciando..." >> "$LOG_FILE"
    launchctl kickstart -k "gui/$(id -u)/com.defesacivil.minio" 2>/dev/null || \
        launchctl load "$HOME_DIR/Library/LaunchAgents/com.defesacivil.minio.plist" 2>/dev/null || true
fi

# 7. Garantir Cloudflare Tunnel ativo
if ! pgrep -f "cloudflared.*tunnel" >/dev/null 2>&1; then
    echo "[$(date '+%d/%m/%Y %H:%M:%S')] [Watchdog] Cloudflare Tunnel offline. Reiniciando..." >> "$LOG_FILE"
    cp "$DEFESA_DIR/scripts/cloudflare-config.yml" "$HOME_DIR/.cloudflared/config.yml" 2>/dev/null || true
    launchctl kickstart -k "gui/$(id -u)/com.defesacivil.tunnel" 2>/dev/null || \
        launchctl load "$HOME_DIR/Library/LaunchAgents/com.defesacivil.tunnel.plist" 2>/dev/null || true
fi
