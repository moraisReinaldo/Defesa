#!/bin/bash
# ==============================================================
# setup-swarm-workers.sh - Cluster Swarm de 3 nos no Mac mini
# ==============================================================
# Topologia (Docker-in-Docker dentro da VM Colima):
#   - colima         -> Manager (Leader)  : db, nginx-lb, visualizer
#   - swarm-worker1  -> Worker (DinD)     : backend / frontend
#   - swarm-worker2  -> Worker (DinD)     : backend / frontend
#
# Idempotente: pode rodar quantas vezes quiser (watchdog chama).
#   ./setup-swarm-workers.sh            -> garante 3 nos + imagens
#   ./setup-swarm-workers.sh --sync     -> forca re-envio das imagens
#   ./setup-swarm-workers.sh --cleanup  -> remove os workers
# ==============================================================

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

NET="swarm-dind-net"
SUBNET="172.30.0.0/24"
WORKERS="swarm-worker1 swarm-worker2"
DIND_IMAGE="docker:29-dind"
IMAGES="defesacivil-backend:latest defesacivil-frontend:latest defesacivil-db:latest adminer:4-standalone"
FORCE_SYNC=0

log() { echo "[$(date '+%d/%m/%Y %H:%M:%S')] [Swarm-Workers] $*"; }

if [ "$1" = "--cleanup" ]; then
    for w in $WORKERS; do
        docker exec "$w" docker swarm leave --force >/dev/null 2>&1
        docker rm -f "$w" >/dev/null 2>&1
        docker volume rm "${w}-data" >/dev/null 2>&1
    done
    docker node ls --format '{{.ID}} {{.Hostname}} {{.Status}}' | awk '$3=="Down"{print $1}' | xargs -r docker node rm --force
    docker network rm "$NET" >/dev/null 2>&1
    log "Workers removidos."
    exit 0
fi
[ "$1" = "--sync" ] && FORCE_SYNC=1

docker info >/dev/null 2>&1 || { log "Docker offline."; exit 1; }

# 1. Swarm ativo no manager
if [ "$(docker info --format '{{.Swarm.LocalNodeState}}')" != "active" ]; then
    log "Iniciando Swarm no manager..."
    docker swarm init >/dev/null
fi
MANAGER_ADDR=$(docker info --format '{{.Swarm.NodeAddr}}')
TOKEN=$(docker swarm join-token -q worker)

# 2. Rede bridge para os workers DinD
docker network inspect "$NET" >/dev/null 2>&1 || \
    docker network create --driver bridge --subnet "$SUBNET" "$NET" >/dev/null

# 2.1 Garantir fix de checksum UDP para redes overlay Swarm (VXLAN 4789 em DinD/Colima)
colima ssh -- sudo iptables -C POSTROUTING -t mangle -p udp --dport 4789 -j CHECKSUM --checksum-fill 2>/dev/null || \
    colima ssh -- sudo iptables -A POSTROUTING -t mangle -p udp --dport 4789 -j CHECKSUM --checksum-fill 2>/dev/null || true


# 3. Containers DinD (persistentes: volume proprio + restart always)
for w in $WORKERS; do
    if ! docker ps -a --format '{{.Names}}' | grep -qx "$w"; then
        log "Criando $w..."
        docker run -d --privileged --name "$w" --hostname "$w" \
            --network "$NET" --restart always \
            -v "${w}-data:/var/lib/docker" \
            "$DIND_IMAGE" --storage-driver=overlay2 >/dev/null
    elif [ "$(docker inspect -f '{{.State.Running}}' "$w")" != "true" ]; then
        docker start "$w" >/dev/null
    fi
    # Aguarda o dockerd interno
    for i in $(seq 1 30); do docker exec "$w" docker info >/dev/null 2>&1 && break; sleep 2; done
done

# 4. Join no Swarm (se ainda nao estiver)
for w in $WORKERS; do
    STATE=$(docker exec "$w" docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)
    if [ "$STATE" != "active" ]; then
        docker exec "$w" docker swarm leave --force >/dev/null 2>&1
        # remove registro antigo "Down" com o mesmo hostname
        docker node ls --format '{{.ID}} {{.Hostname}} {{.Status}}' | awk -v h="$w" '$2==h && $3=="Down"{print $1}' | xargs -r docker node rm --force >/dev/null 2>&1
        log "$w entrando no Swarm ($MANAGER_ADDR)..."
        docker exec "$w" docker swarm join --token "$TOKEN" "$MANAGER_ADDR:2377"
    fi
done

# 5. Distribui as imagens customizadas para os workers (sem registry)
for w in $WORKERS; do
    for img in $IMAGES; do
        LOCAL_ID=$(docker image inspect -f '{{.Id}}' "$img" 2>/dev/null)
        REMOTE_ID=$(docker exec "$w" docker image inspect -f '{{.Id}}' "$img" 2>/dev/null)
        if [ -n "$LOCAL_ID" ] && { [ "$LOCAL_ID" != "$REMOTE_ID" ] || [ $FORCE_SYNC = 1 ]; }; then
            log "Enviando $img -> $w..."
            docker save "$img" | docker exec -i "$w" docker load >/dev/null
        fi
    done
done

docker node ls
