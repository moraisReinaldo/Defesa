#!/bin/bash
# ==============================================================
# startup-server.sh — Script de inicialização do Mac Mini Server
# ==============================================================
# Mac Mini 2014 (Intel) — brew em /usr/local/bin/brew
#
# Instalar:
#   sudo cp startup-server.sh /usr/local/bin/startup-server.sh
#   sudo chmod +x /usr/local/bin/startup-server.sh
#   sudo cp com.defesacivil.startup.plist /Library/LaunchDaemons/
#   sudo launchctl load /Library/LaunchDaemons/com.defesacivil.startup.plist
# ==============================================================

USR="reinaldohenriquemorais"
HOME_DIR="/Users/$USR"
LOG="$HOME_DIR/logs/startup.log"
PROPS="$HOME_DIR/Defesa/defesa-backend/src/main/resources/application.properties"
ENV_FILE="$HOME_DIR/logs/tunnel-urls.env"
TAILSCALE="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
ADGUARD="/Applications/AdGuardHome/AdGuardHome"
BACKEND_DIR="$HOME_DIR/Defesa/defesa-backend"
BREW="/usr/local/bin/brew"

# Criar diretório de logs se não existir
mkdir -p "$HOME_DIR/logs"
chown "$USR" "$HOME_DIR/logs"

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG"
}

log_error() {
    echo "[$(date '+%H:%M:%S')] ❌ ERRO: $1" >> "$LOG"
}

log_ok() {
    echo "[$(date '+%H:%M:%S')] ✅ $1" >> "$LOG"
}

# Limpar e iniciar log
cat > "$LOG" <<EOF
========================================
STARTUP - $(date)
Mac Mini 2014 (Intel)
========================================
EOF

# ──────────────────────────────────────
# [0] Aguardar rede (com timeout de 2 min)
# ──────────────────────────────────────
log "Aguardando rede..."
NETWORK_TIMEOUT=120
NETWORK_ELAPSED=0
until ping -c 1 -W 2 8.8.8.8 &>/dev/null; do
    sleep 2
    NETWORK_ELAPSED=$((NETWORK_ELAPSED + 2))
    if [ "$NETWORK_ELAPSED" -ge "$NETWORK_TIMEOUT" ]; then
        log_error "Timeout aguardando rede ($NETWORK_TIMEOUT s). Continuando mesmo assim..."
        break
    fi
done
if [ "$NETWORK_ELAPSED" -lt "$NETWORK_TIMEOUT" ]; then
    log_ok "Rede OK (${NETWORK_ELAPSED}s)"
fi

# ──────────────────────────────────────
# [1] PostgreSQL
# ──────────────────────────────────────
log "[1] PostgreSQL..."
sudo -u "$USR" "$BREW" services start postgresql@14 >> "$LOG" 2>&1

PG_OK=false
for i in $(seq 1 10); do
    if sudo -u "$USR" pg_isready -q 2>/dev/null; then
        PG_OK=true
        break
    fi
    sleep 2
done
if $PG_OK; then
    log_ok "PostgreSQL OK"
else
    log_error "PostgreSQL não respondeu após 20s"
fi

# ──────────────────────────────────────
# [2] AdGuard Home
# ──────────────────────────────────────
log "[2] AdGuard Home..."
AG_OK=false
for i in 1 2 3; do
    STATUS=$("$ADGUARD" -s status 2>&1)
    if echo "$STATUS" | grep -qi "running"; then
        AG_OK=true
        log_ok "AdGuard OK"
        break
    else
        log "AdGuard parado, tentativa $i..."
        "$ADGUARD" -s start >> "$LOG" 2>&1
        sleep 5
    fi
done
if ! $AG_OK; then
    log_error "AdGuard Home não iniciou após 3 tentativas"
fi

# ──────────────────────────────────────
# [3] Tailscale
# ──────────────────────────────────────
log "[3] Tailscale..."
TS_OK=false
for i in 1 2 3 4 5; do
    TS_STATUS=$(sudo -u "$USR" "$TAILSCALE" status 2>&1)
    if echo "$TS_STATUS" | grep -q "100\."; then
        TS_OK=true
        log_ok "Tailscale conectado"
        sudo -u "$USR" "$TAILSCALE" up --advertise-exit-node --accept-routes --exit-node-allow-lan-access >> "$LOG" 2>&1
        log "Tailscale exit node configurado"
        break
    else
        log "Tailscale desconectado, tentativa $i..."
        sudo -u "$USR" open -a /Applications/Tailscale.app
        sleep 10
    fi
done

TS_IP=""
if $TS_OK; then
    TS_IP=$(sudo -u "$USR" "$TAILSCALE" ip -4 2>&1 | head -1)
    log "Tailscale IP: $TS_IP"
else
    log_error "Tailscale não conectou após 5 tentativas"
fi

# ──────────────────────────────────────
# [4] MinIO (já tem RunAtLoad=true no plist, só verificar)
# ──────────────────────────────────────
log "[4] MinIO..."
MINIO_OK=false
for i in $(seq 1 6); do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/minio/health/live 2>/dev/null | grep -q "200"; then
        MINIO_OK=true
        log_ok "MinIO OK"
        break
    fi
    sleep 5
done
if ! $MINIO_OK; then
    log "MinIO não respondeu, tentando reiniciar..."
    MINIO_PLIST="$HOME_DIR/Library/LaunchAgents/com.minio.plist"
    sudo -u "$USR" launchctl unload "$MINIO_PLIST" >> "$LOG" 2>&1
    sleep 2
    sudo -u "$USR" launchctl load "$MINIO_PLIST" >> "$LOG" 2>&1
    sleep 5
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/minio/health/live 2>/dev/null | grep -q "200"; then
        log_ok "MinIO OK (após restart)"
    else
        log_error "MinIO não respondeu mesmo após restart"
    fi
fi

# ──────────────────────────────────────
# [5] Cloudflare Tunnels
# ──────────────────────────────────────
log "[5] Cloudflare Tunnels..."

CF_API_PLIST="$HOME_DIR/Library/LaunchAgents/com.cloudflared.tunnel.plist"
CF_MINIO_PLIST="$HOME_DIR/Library/LaunchAgents/com.cloudflared.minio.plist"
CF_API_LOG="$HOME_DIR/logs/cloudflared-error.log"
CF_MINIO_LOG="$HOME_DIR/logs/cloudflared-minio-error.log"

# Limpar logs anteriores para capturar URLs novas
> "$CF_API_LOG" 2>/dev/null
> "$CF_MINIO_LOG" 2>/dev/null

# Parar tunnels existentes
sudo -u "$USR" launchctl unload "$CF_API_PLIST" >> "$LOG" 2>&1
sudo -u "$USR" launchctl unload "$CF_MINIO_PLIST" >> "$LOG" 2>&1
sleep 3

# Iniciar tunnels
sudo -u "$USR" launchctl load "$CF_API_PLIST" >> "$LOG" 2>&1
sudo -u "$USR" launchctl load "$CF_MINIO_PLIST" >> "$LOG" 2>&1

log "Aguardando URLs do Cloudflare (máx 90s)..."
API_URL=""
MINIO_URL=""
for i in $(seq 1 18); do
    if [ -z "$API_URL" ]; then
        API_URL=$(grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' "$CF_API_LOG" 2>/dev/null | tail -1)
    fi
    if [ -z "$MINIO_URL" ]; then
        MINIO_URL=$(grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' "$CF_MINIO_LOG" 2>/dev/null | tail -1)
    fi
    if [ -n "$API_URL" ] && [ -n "$MINIO_URL" ]; then
        break
    fi
    sleep 5
done

if [ -n "$API_URL" ]; then
    log_ok "API URL: $API_URL"
else
    log_error "Não conseguiu obter API URL do Cloudflare"
fi
if [ -n "$MINIO_URL" ]; then
    log_ok "MinIO URL: $MINIO_URL"
else
    log_error "Não conseguiu obter MinIO URL do Cloudflare"
fi

# ──────────────────────────────────────
# [6] Salvar URLs no arquivo de ambiente
# ──────────────────────────────────────
log "[6] Salvando URLs no arquivo de ambiente..."
cat > "$ENV_FILE" <<ENVEOF
# Gerado automaticamente pelo startup-server.sh em $(date)
# Usado pelo run-spring-boot.sh para configurar o MinIO endpoint
export MINIO_ENDPOINT="${MINIO_URL:-http://localhost:9000}"
export API_URL="${API_URL:-}"
ENVEOF
chown "$USR" "$ENV_FILE"
log_ok "Arquivo de ambiente salvo: $ENV_FILE"

# ──────────────────────────────────────
# [7] Build Spring Boot (só se JAR não existir)
# ──────────────────────────────────────
JAR_FILE="$BACKEND_DIR/target/backend-0.0.1-SNAPSHOT.jar"
if [ ! -f "$JAR_FILE" ]; then
    log "[7] Build Spring Boot (JAR não encontrado)..."
    if [ -d "$BACKEND_DIR" ] && [ -f "$BACKEND_DIR/mvnw" ]; then
        chmod +x "$BACKEND_DIR/mvnw"
        sudo -u "$USR" "$BACKEND_DIR/mvnw" -f "$BACKEND_DIR/pom.xml" package -DskipTests >> "$LOG" 2>&1
        BUILD_EXIT=$?
        if [ $BUILD_EXIT -eq 0 ]; then
            log_ok "Build concluído"
        else
            log_error "Build falhou (exit code: $BUILD_EXIT)"
        fi
    else
        log_error "Diretório do backend ou mvnw não encontrado: $BACKEND_DIR"
    fi
else
    log "[7] Build Spring Boot — JAR já existe, pulando build ✅"
fi

# ──────────────────────────────────────
# [8] Restart Spring Boot
# ──────────────────────────────────────
log "[8] Restart Spring Boot..."
SPRING_PLIST="$HOME_DIR/Library/LaunchAgents/com.defesacivil.spring.plist"
if [ -f "$SPRING_PLIST" ]; then
    sudo -u "$USR" launchctl unload "$SPRING_PLIST" >> "$LOG" 2>&1
    sleep 3
    sudo -u "$USR" launchctl load "$SPRING_PLIST" >> "$LOG" 2>&1
    log "Spring Boot carregado, aguardando inicialização..."
    sleep 20
else
    log_error "Spring Boot plist não encontrado: $SPRING_PLIST"
fi

# ──────────────────────────────────────
# [9] Health Check
# ──────────────────────────────────────
log "[9] Health check..."
HEALTH=""
for i in $(seq 1 6); do
    HEALTH=$(curl -s http://localhost:8080/actuator/health 2>&1)
    if echo "$HEALTH" | grep -qi '"status":"UP"'; then
        log_ok "Backend HEALTHY: $HEALTH"
        break
    fi
    log "Health check tentativa $i — aguardando..."
    sleep 5
done

if ! echo "$HEALTH" | grep -qi '"status":"UP"'; then
    log_error "Backend não está healthy: $HEALTH"
fi

# ──────────────────────────────────────
# RESUMO
# ──────────────────────────────────────
cat >> "$LOG" <<EOF

========================================
RESUMO - $(date)
========================================
Tailscale IP : ${TS_IP:-NÃO DISPONÍVEL}
API URL      : ${API_URL:-NÃO DISPONÍVEL}
MinIO URL    : ${MINIO_URL:-NÃO DISPONÍVEL}
Backend      : ${HEALTH:-NÃO RESPONDEU}
========================================

Para ver as fotos de qualquer lugar, o app usa:
  API  → $API_URL (porta 8080 via Cloudflare)
  Fotos → As URLs presigned do MinIO usam $MINIO_URL

========================================
EOF

log "Script de startup finalizado."
