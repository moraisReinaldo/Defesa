<#
.SYNOPSIS
    Script completo para inicialização do cluster Docker Swarm com Docker-in-Docker (DinD).

.DESCRIPTION
    Implementa um cluster Docker Swarm com 3 nós (1 Manager + 2 Workers) usando
    containers Docker-in-Docker (dind). Em seguida, realiza o build das imagens,
    distribui para os nós e faz o deploy da stack completa do sistema Defesa em Foco.

    Serviços da stack:
      - db          (PostgreSQL 15)          → 1 réplica, fixada no Manager
      - minio       (MinIO Object Storage)   → 1 réplica, fixada no Manager
      - backend     (Spring Boot API REST)   → 3 réplicas, nos Workers
      - frontend    (Flutter Web + Nginx)    → 2 réplicas, nos Workers
      - nginx-lb    (Nginx Load Balancer)    → 1 réplica, fixada no Manager
      - visualizer  (Docker Visualizer)      → 1 réplica, fixada no Manager

.NOTES
    Pré-requisitos:
      - Docker Desktop instalado e rodando
      - Estar na raiz do repositório Defesa ao executar

.EXAMPLE
    .\setup-swarm-dind.ps1
    .\setup-swarm-dind.ps1 -SkipBuild
    .\setup-swarm-dind.ps1 -CleanUp
#>

param(
    [switch]$SkipBuild,   # Pula o build das imagens (usa as existentes)
    [switch]$CleanUp      # Remove todos os recursos criados por este script
)

# ==============================================================
# Configuração
# ==============================================================
$STACK_NAME     = "defesacivil"
$MANAGER_NAME   = "swarm-manager"
$WORKER1_NAME   = "swarm-worker1"
$WORKER2_NAME   = "swarm-worker2"
$NETWORK_NAME   = "swarm-dind-net"
$BACKEND_IMAGE  = "defesacivil-backend:latest"
$FRONTEND_IMAGE = "defesacivil-frontend:latest"
$DB_IMAGE       = "defesacivil-db:latest"

# ==============================================================
# Funções auxiliares
# ==============================================================
function Write-Step($step, $msg) {
    Write-Host "`n[$step] $msg" -ForegroundColor Cyan
}

function Write-OK($msg) {
    Write-Host "  [OK] $msg" -ForegroundColor Green
}

function Write-Warn($msg) {
    Write-Host "  [!]  $msg" -ForegroundColor Yellow
}

function Write-Fail($msg) {
    Write-Host "  [ERRO] $msg" -ForegroundColor Red
    exit 1
}

function Invoke-Docker($args) {
    $output = docker @args 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host $output -ForegroundColor Red
        return $false
    }
    return $true
}

# ==============================================================
# Modo: Limpeza
# ==============================================================
if ($CleanUp) {
    Write-Host "==========================================================" -ForegroundColor Magenta
    Write-Host " MODO LIMPEZA — Removendo todos os recursos Swarm DinD" -ForegroundColor Magenta
    Write-Host "==========================================================" -ForegroundColor Magenta

    Write-Warn "Removendo stack '$STACK_NAME'..."
    docker exec $MANAGER_NAME docker stack rm $STACK_NAME 2>$null

    Write-Warn "Removendo containers DinD ($MANAGER_NAME, $WORKER1_NAME, $WORKER2_NAME)..."
    docker rm -f $MANAGER_NAME $WORKER1_NAME $WORKER2_NAME 2>$null

    Write-Warn "Removendo rede $NETWORK_NAME..."
    docker network rm $NETWORK_NAME 2>$null

    Write-OK "Limpeza concluída!"
    exit 0
}

# ==============================================================
# Cabeçalho
# ==============================================================
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   DEFESA EM FOCO — Deploy Docker Swarm (DinD)" -ForegroundColor Cyan
Write-Host "   Cluster: 1 Manager + 2 Workers (Docker-in-Docker)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# ==============================================================
# Passo 0: Verificar Docker
# ==============================================================
Write-Step "0/6" "Verificando pré-requisitos..."

try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "Docker não está rodando. Inicie o Docker Desktop." }
} catch {
    Write-Fail "Comando 'docker' não encontrado. Instale o Docker Desktop."
}

Write-OK "Docker está rodando."

# ==============================================================
# Passo 1: Build das imagens
# ==============================================================
if (-not $SkipBuild) {
    Write-Step "1/6" "Realizando build das imagens Docker..."

    Write-Warn "Construindo imagem do Banco de Dados (PostgreSQL customizado)..."
    docker build -t $DB_IMAGE ./docker/postgres
    if ($LASTEXITCODE -ne 0) { Write-Fail "Falha no build da imagem do banco." }
    Write-OK "Imagem '$DB_IMAGE' criada."

    Write-Warn "Construindo imagem do Backend (Spring Boot)..."
    docker build -t $BACKEND_IMAGE ./defesa-backend
    if ($LASTEXITCODE -ne 0) { Write-Fail "Falha no build da imagem do backend." }
    Write-OK "Imagem '$BACKEND_IMAGE' criada."

    Write-Warn "Construindo imagem do Frontend (Flutter Web + Nginx)..."
    docker build -t $FRONTEND_IMAGE .
    if ($LASTEXITCODE -ne 0) { Write-Fail "Falha no build da imagem do frontend." }
    Write-OK "Imagem '$FRONTEND_IMAGE' criada."
} else {
    Write-Step "1/6" "Build ignorado (--SkipBuild). Usando imagens existentes."
}

# ==============================================================
# Passo 2: Criar rede bridge para comunicação entre nós DinD
# ==============================================================
Write-Step "2/6" "Criando rede Docker para os nós DinD..."

$netExists = docker network ls --filter "name=$NETWORK_NAME" --format "{{.Name}}" 2>$null
if ($netExists -eq $NETWORK_NAME) {
    Write-Warn "Rede '$NETWORK_NAME' já existe. Reutilizando."
} else {
    docker network create --driver bridge $NETWORK_NAME 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao criar a rede '$NETWORK_NAME'." }
    Write-OK "Rede '$NETWORK_NAME' criada."
}

# ==============================================================
# Passo 3: Criar os nós do cluster (DinD)
# ==============================================================
Write-Step "3/6" "Provisionando nós do cluster (Docker-in-Docker)..."

# Função para criar um container DinD
function New-DinDNode($name, $ports) {
    $existing = docker ps -a --filter "name=^${name}$" --format "{{.Names}}" 2>$null
    if ($existing -eq $name) {
        Write-Warn "Container '$name' já existe. Reutilizando."
        docker start $name 2>&1 | Out-Null
        return
    }

    $runArgs = @(
        "run", "-d",
        "--privileged",
        "--name", $name,
        "--hostname", $name,
        "--network", $NETWORK_NAME
    )

    foreach ($p in $ports) { $runArgs += @("-p", $p) }

    $runArgs += @(
        "-v", "/var/lib/docker",   # Volume interno para o Docker daemon do DinD
        "--restart", "unless-stopped",
        "docker:dind"
    )

    docker @runArgs 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao criar o nó '$name'." }
    Write-OK "Nó '$name' criado."
}

# Manager: expõe todas as portas públicas da stack
New-DinDNode $MANAGER_NAME @("80:80", "8080:8080", "8081:8081", "9000:9000", "9001:9001")

# Workers: sem ports (tráfego roteado via Swarm ingress)
New-DinDNode $WORKER1_NAME @()
New-DinDNode $WORKER2_NAME @()

# Aguardar Docker daemon dentro dos containers DinD iniciar
Write-Warn "Aguardando Docker daemon dentro dos nós DinD (10s)..."
Start-Sleep -Seconds 10

# ==============================================================
# Passo 4: Inicializar o Swarm no Manager
# ==============================================================
Write-Step "4/6" "Inicializando Docker Swarm no nó Manager..."

# Verificar se Swarm já está ativo no manager
$swarmState = docker exec $MANAGER_NAME docker info --format '{{.Swarm.LocalNodeState}}' 2>$null

if ($swarmState -eq "active") {
    Write-Warn "Swarm já ativo no Manager. Reutilizando cluster existente."
} else {
    # Pegar IP do container manager na rede DinD
    $MANAGER_IP = docker inspect $MANAGER_NAME --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>$null
    Write-Warn "IP do Manager: $MANAGER_IP"

    docker exec $MANAGER_NAME docker swarm init --advertise-addr $MANAGER_IP 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao inicializar o Swarm no Manager." }
    Write-OK "Swarm inicializado. Manager: $MANAGER_NAME ($MANAGER_IP)"
}

# Obter token de worker
$WORKER_TOKEN = docker exec $MANAGER_NAME docker swarm join-token -q worker 2>$null
$MANAGER_ADDR = docker exec $MANAGER_NAME docker info --format '{{.Swarm.NodeAddr}}' 2>$null

Write-OK "Token de Worker obtido."

# ==============================================================
# Juntar Workers ao Swarm
# ==============================================================
foreach ($worker in @($WORKER1_NAME, $WORKER2_NAME)) {
    $state = docker exec $worker docker info --format '{{.Swarm.LocalNodeState}}' 2>$null
    if ($state -eq "active") {
        Write-Warn "Nó '$worker' já faz parte do Swarm."
    } else {
        docker exec $worker docker swarm join --token $WORKER_TOKEN "${MANAGER_ADDR}:2377" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Falha ao ingressar '$worker' no Swarm. Tentando com IP do Manager..."
            $MANAGER_IP = docker inspect $MANAGER_NAME --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
            docker exec $worker docker swarm join --token $WORKER_TOKEN "${MANAGER_IP}:2377" 2>&1 | Out-Null
        }
        Write-OK "Nó '$worker' ingressou no cluster."
    }
}

# Exibir status do cluster
Write-Host "`n  Status do cluster:" -ForegroundColor White
docker exec $MANAGER_NAME docker node ls

# ==============================================================
# Passo 5: Transferir imagens para o Manager
# ==============================================================
Write-Step "5/6" "Transferindo imagens para o nó Manager (via docker save | docker load)..."

foreach ($img in @($DB_IMAGE, $BACKEND_IMAGE, $FRONTEND_IMAGE)) {
    Write-Warn "Transferindo '$img'..."
    docker save $img | docker exec -i $MANAGER_NAME docker load 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Falha ao transferir '$img'. O Manager pode não ter a imagem."
    } else {
        Write-OK "'$img' transferida para o Manager."
    }
}

# Transferir para Workers também
foreach ($worker in @($WORKER1_NAME, $WORKER2_NAME)) {
    foreach ($img in @($BACKEND_IMAGE, $FRONTEND_IMAGE)) {
        Write-Warn "Transferindo '$img' → '$worker'..."
        docker save $img | docker exec -i $worker docker load 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-OK "'$img' → '$worker'"
        }
    }
}

# ==============================================================
# Passo 6: Deploy da Stack
# ==============================================================
Write-Step "6/6" "Realizando deploy da Stack '$STACK_NAME' no Swarm..."

# Copiar o docker-compose.yml e o nginx-lb.conf para o Manager
docker cp docker-compose.yml "${MANAGER_NAME}:/docker-compose.yml" 2>&1 | Out-Null
docker exec $MANAGER_NAME mkdir -p /nginx 2>&1 | Out-Null
docker cp nginx/nginx-lb.conf "${MANAGER_NAME}:/nginx/nginx-lb.conf" 2>&1 | Out-Null

# Criar a Docker Config para o Nginx LB (necessário no Swarm)
$configExists = docker exec $MANAGER_NAME docker config ls --filter "name=nginx_lb_conf" --format "{{.Name}}" 2>$null
if ($configExists -eq "nginx_lb_conf") {
    Write-Warn "Config 'nginx_lb_conf' já existe. Removendo e recriando..."
    docker exec $MANAGER_NAME docker config rm nginx_lb_conf 2>&1 | Out-Null
}
docker exec $MANAGER_NAME sh -c "cat /nginx/nginx-lb.conf | docker config create nginx_lb_conf -" 2>&1 | Out-Null
Write-OK "Docker Config 'nginx_lb_conf' criada no Swarm."

# Deploy da stack
docker exec $MANAGER_NAME docker stack deploy -c /docker-compose.yml $STACK_NAME 2>&1
if ($LASTEXITCODE -ne 0) { Write-Fail "Falha no deploy da stack." }

# ==============================================================
# Resultado Final
# ==============================================================
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  DEPLOY CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Cluster Swarm:" -ForegroundColor White
Write-Host "    Manager : $MANAGER_NAME" -ForegroundColor Gray
Write-Host "    Worker 1: $WORKER1_NAME" -ForegroundColor Gray
Write-Host "    Worker 2: $WORKER2_NAME" -ForegroundColor Gray
Write-Host ""
Write-Host "  Portas disponíveis:" -ForegroundColor White
Write-Host "    http://localhost:80    → Frontend (Flutter Web)" -ForegroundColor Gray
Write-Host "    http://localhost:8080  → Backend API (Spring Boot)" -ForegroundColor Gray
Write-Host "    http://localhost:8081  → Docker Visualizer (painel gráfico)" -ForegroundColor Gray
Write-Host "    http://localhost:9000  → MinIO API (Object Storage)" -ForegroundColor Gray
Write-Host "    http://localhost:9001  → MinIO Console Web" -ForegroundColor Gray
Write-Host ""
Write-Host "  Comandos úteis para a apresentação:" -ForegroundColor White
Write-Host "    # Ver todos os serviços e réplicas:" -ForegroundColor DarkGray
Write-Host "    docker exec $MANAGER_NAME docker service ls" -ForegroundColor Yellow
Write-Host ""
Write-Host "    # Ver distribuição dos containers pelos nós:" -ForegroundColor DarkGray
Write-Host "    docker exec $MANAGER_NAME docker stack ps $STACK_NAME" -ForegroundColor Yellow
Write-Host ""
Write-Host "    # ESCALAR o backend para 5 réplicas (demonstração ao vivo):" -ForegroundColor DarkGray
Write-Host "    docker exec $MANAGER_NAME docker service scale ${STACK_NAME}_backend=5" -ForegroundColor Yellow
Write-Host ""
Write-Host "    # Reduzir de volta para 3 réplicas:" -ForegroundColor DarkGray
Write-Host "    docker exec $MANAGER_NAME docker service scale ${STACK_NAME}_backend=3" -ForegroundColor Yellow
Write-Host ""
Write-Host "    # Remover tudo após a apresentação:" -ForegroundColor DarkGray
Write-Host "    .\setup-swarm-dind.ps1 -CleanUp" -ForegroundColor Yellow
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green

# Aguardar serviços subirem e mostrar status final
Write-Host "`nAguardando serviços inicializarem (30s)..." -ForegroundColor Cyan
Start-Sleep -Seconds 30
docker exec $MANAGER_NAME docker service ls
