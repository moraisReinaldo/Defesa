#!/bin/bash
set -e

echo "========================================================="
echo " Inicializando a configuração do Docker Swarm (Mac Mini)"
echo "========================================================="

# 1. Verifica se o Docker está rodando
if ! docker info >/dev/null 2>&1; then
    echo "[ERRO] O Docker não está rodando ou não foi encontrado."
    echo "Por favor, inicie o Docker Desktop e tente novamente."
    exit 1
fi

echo "[OK] Docker está rodando."

# 2. Build das imagens (forçando arquitetura caso tenha M1/M2, mas o seu é Intel então amd64 é nativo)
echo -e "\n[1/3] Realizando o build das imagens locais..."

echo "-> Construindo Backend..."
docker build -t defesacivil-backend:latest ./defesa-backend

echo "-> Construindo Frontend..."
docker build -t defesacivil-frontend:latest .

# 3. Inicializa o Swarm (se já não for um manager)
echo -e "\n[2/3] Verificando status do Docker Swarm..."
swarm_status=$(docker info --format '{{.Swarm.LocalNodeState}}')

if [ "$swarm_status" = "inactive" ]; then
    echo "-> Inicializando Docker Swarm no Mac Mini..."
    docker swarm init
else
    echo "-> O Docker Swarm já está ativo."
fi

# 4. Parar serviços antigos do launchctl (para liberar portas)
echo -e "\n[Extra] Parando serviços antigos do launchctl..."
launchctl unload ~/Library/LaunchAgents/com.defesacivil.spring.plist 2>/dev/null || true
launchctl unload ~/Library/LaunchAgents/com.defesacivil.web.plist 2>/dev/null || true
# MinIO e Tunnel podemos manter ligados se você ainda usar eles por fora do docker,
# caso contrário pode parar também.

# 5. Faz o deploy da Stack
echo -e "\n[3/3] Realizando o deploy da Stack (Docker Swarm)..."
docker stack deploy -c docker-compose.yml defesacivil

echo -e "\n========================================================="
echo " DEPLOY CONCLUÍDO COM SUCESSO NO MAC MINI!"
echo "========================================================="
echo "Você pode acompanhar o status dos serviços com os comandos:"
echo "  > docker service ls"
echo "  > docker stack ps defesacivil"
echo "========================================================="
