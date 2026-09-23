<#
.SYNOPSIS
Script para inicializar rapidamente o Docker Swarm e provisionar a infraestrutura do Defesa em Foco.

.DESCRIPTION
Este script realiza o build das imagens (Backend e Frontend) e inicializa um cluster Swarm localmente na sua máquina (Single-node Manager). Em seguida, ele faz o deploy automático da stack definida no docker-compose.yml.
#>

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " Inicializando a configuração do Docker Swarm" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Verifica se o Docker está rodando
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERRO] O Docker não está rodando ou não foi encontrado." -ForegroundColor Red
        Write-Host "Por favor, inicie o Docker Desktop e tente novamente." -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "[ERRO] O comando docker não foi encontrado. Instale o Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Docker está rodando." -ForegroundColor Green

# 2. Build das imagens
Write-Host "`n[1/3] Realizando o build das imagens locais..." -ForegroundColor Yellow

Write-Host "-> Construindo Backend..."
docker build -t defesacivil-backend:latest ./defesa-backend

Write-Host "-> Construindo Frontend..."
docker build -t defesacivil-frontend:latest .

# 3. Inicializa o Swarm (se já não for um manager)
Write-Host "`n[2/3] Verificando status do Docker Swarm..." -ForegroundColor Yellow
$swarmStatus = docker info --format '{{.Swarm.LocalNodeState}}'

if ($swarmStatus -eq 'inactive') {
    Write-Host "-> Inicializando Docker Swarm na sua máquina..."
    docker swarm init
} else {
    Write-Host "-> O Docker Swarm já está ativo." -ForegroundColor Green
}

# 4. Faz o deploy da Stack
Write-Host "`n[3/3] Realizando o deploy da Stack (Infraestrutura como Código)..." -ForegroundColor Yellow
docker stack deploy -c docker-compose.yml defesacivil

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host " DEPLOY CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "Você pode acompanhar o status dos serviços com os comandos:"
Write-Host "  > docker service ls"
Write-Host "  > docker stack ps defesacivil"
Write-Host ""
Write-Host "Para acessar o Visualizer Gráfico:"
Write-Host "  > http://localhost:8081"
Write-Host "=========================================================" -ForegroundColor Cyan
