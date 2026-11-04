#!/bin/bash
set -e

export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

echo "========================================================="
echo " Inicializando Cluster Docker Swarm + Visualizer (Mac Mini)"
echo "========================================================="

if ! docker info >/dev/null 2>&1; then
    echo "-> Iniciando VM Colima..."
    colima start
fi

cd /Users/rhmorais/Defesa

echo -e "\n[1/4] Construindo as 3 imagens Docker customizadas (Dockerfiles)..."
docker build -t defesacivil-db:latest ./docker/postgres
docker build -t defesacivil-backend:latest ./defesa-backend
docker build -t defesacivil-frontend:latest .

echo -e "\n[2/4] Verificando status do Docker Swarm..."
swarm_status=$(docker info --format '{{.Swarm.LocalNodeState}}')
if [ "$swarm_status" = "inactive" ]; then
    docker swarm init
fi

echo -e "\n[3/4] Limpando processos antigos fora do Swarm..."
mkdir -p ~/Library/LaunchAgents.disabled
for plist in com.defesacivil.spring.plist com.defesacivil.web.plist homebrew.mxcl.postgresql@15.plist; do
    if [ -f ~/Library/LaunchAgents/$plist ]; then
        launchctl unload ~/Library/LaunchAgents/$plist 2>/dev/null || true
        mv ~/Library/LaunchAgents/$plist ~/Library/LaunchAgents.disabled/ 2>/dev/null || true
    fi
done
docker-compose down 2>/dev/null || true

echo -e "\n[4/4] Fazendo deploy da Stack 'defesacivil' no Docker Swarm..."
bash /Users/rhmorais/Defesa/scripts/setup-swarm-workers.sh
docker stack deploy -c /Users/rhmorais/Defesa/docker-compose.yml defesacivil

echo -e "\n========================================================="
echo " DEPLOY SWARM CONCLUÍDO COM SUCESSO NO MAC MINI!"
echo "========================================================="
echo "Comandos de demonstração (Variação de Réplicas & Visualizer):"
echo "  > docker node ls"
echo "  > docker service ls"
echo "  > docker service scale defesacivil_backend=5"
echo "  > docker service scale defesacivil_backend=3"
echo "  > Visualizer: http://100.98.5.110:8081 (ou http://localhost:8081)"
echo "========================================================="
