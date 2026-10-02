<#
.SYNOPSIS
    Script de demonstração ao vivo da variação de réplicas no Docker Swarm.

.DESCRIPTION
    Demonstra em tempo real o escalonamento de serviços no Swarm, mostrando
    como as réplicas são distribuídas pelos nós Manager e Workers.
    Abre o Docker Visualizer no navegador para representação gráfica.

    Referência: "Descomplicando o Docker" — Jeferson Fernando
                Capítulo sobre Docker Swarm e Services

.EXAMPLE
    .\demo-scaling.ps1
    .\demo-scaling.ps1 -ManagerName "swarm-manager"
#>

param(
    [string]$ManagerName = "swarm-manager",
    [string]$StackName   = "defesacivil"
)

# ==============================================================
# Funções
# ==============================================================
function Write-Title($msg) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $($msg.PadRight(56))║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Section($msg) {
    Write-Host ""
    Write-Host "  ── $msg ──" -ForegroundColor Yellow
}

function Show-Services {
    Write-Host ""
    docker exec $ManagerName docker service ls
    Write-Host ""
    docker exec $ManagerName docker stack ps $StackName --no-trunc 2>$null | Select-Object -First 30
}

function Wait-Converge($secs) {
    Write-Host ""
    Write-Host "  ⏳ Aguardando convergência do cluster ($secs s)..." -ForegroundColor DarkCyan
    for ($i = 1; $i -le $secs; $i++) {
        Write-Progress -Activity "Aguardando" -Status "$i/$secs segundos" -PercentComplete (($i / $secs) * 100)
        Start-Sleep -Seconds 1
    }
    Write-Progress -Completed -Activity "Aguardando"
}

# ==============================================================
# Início
# ==============================================================
Write-Title "DEFESA EM FOCO — Demonstração de Escalonamento Swarm"

# Verificar se o Manager está acessível
$nodeCount = docker exec $ManagerName docker node ls --format "{{.ID}}" 2>$null | Measure-Object | Select-Object -ExpandProperty Count
if ($nodeCount -eq 0) {
    Write-Host "  [ERRO] Não foi possível conectar ao Manager '$ManagerName'." -ForegroundColor Red
    Write-Host "  Execute .\setup-swarm-dind.ps1 primeiro." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "  Cluster detectado com $nodeCount nó(s)." -ForegroundColor Green

# ==============================================================
# Abrir Docker Visualizer no navegador
# ==============================================================
Write-Section "Abrindo Docker Visualizer (representação gráfica)"
Write-Host "  URL: http://localhost:8081" -ForegroundColor White
Start-Process "http://localhost:8081"
Start-Sleep -Seconds 2

# ==============================================================
# Estado inicial
# ==============================================================
Write-Section "Estado Inicial da Stack"
Write-Host "  Configuração base:" -ForegroundColor White
Write-Host "    backend:    3 réplicas" -ForegroundColor Gray
Write-Host "    frontend:   2 réplicas" -ForegroundColor Gray
Write-Host "    db:         1 réplica" -ForegroundColor Gray
Write-Host "    minio:      1 réplica" -ForegroundColor Gray
Write-Host "    visualizer: 1 réplica" -ForegroundColor Gray

Show-Services
Read-Host "`n  ► Pressione ENTER para iniciar a demonstração de escalonamento"

# ==============================================================
# Demonstração 1: Scale UP do Backend (3 → 5)
# ==============================================================
Write-Title "DEMO 1: Scale UP — Backend 3 → 5 réplicas"
Write-Host ""
Write-Host "  Comando: docker service scale ${StackName}_backend=5" -ForegroundColor Yellow

docker exec $ManagerName docker service scale "${StackName}_backend=5"

Wait-Converge 20
Write-Section "Status após Scale UP"
Show-Services

Write-Host ""
Write-Host "  Observe no Visualizer (http://localhost:8081):" -ForegroundColor Cyan
Write-Host "    → O backend agora tem 5 containers distribuídos pelos nós" -ForegroundColor White

Read-Host "`n  ► Pressione ENTER para continuar para a próxima demonstração"

# ==============================================================
# Demonstração 2: Scale UP do Frontend (2 → 4)
# ==============================================================
Write-Title "DEMO 2: Scale UP — Frontend 2 → 4 réplicas"
Write-Host ""
Write-Host "  Comando: docker service scale ${StackName}_frontend=4" -ForegroundColor Yellow

docker exec $ManagerName docker service scale "${StackName}_frontend=4"

Wait-Converge 15
Write-Section "Status após Scale UP Frontend"
Show-Services

Read-Host "`n  ► Pressione ENTER para continuar"

# ==============================================================
# Demonstração 3: Scale DOWN (voltando ao normal)
# ==============================================================
Write-Title "DEMO 3: Scale DOWN — Reduzindo réplicas"
Write-Host ""
Write-Host "  Comandos:" -ForegroundColor Yellow
Write-Host "    docker service scale ${StackName}_backend=3" -ForegroundColor Yellow
Write-Host "    docker service scale ${StackName}_frontend=2" -ForegroundColor Yellow

docker exec $ManagerName docker service scale "${StackName}_backend=3"
docker exec $ManagerName docker service scale "${StackName}_frontend=2"

Wait-Converge 20
Write-Section "Estado Final (configuração original restaurada)"
Show-Services

# ==============================================================
# Demonstração 4: Tolerância a falhas (simular queda de container)
# ==============================================================
Write-Title "DEMO 4: Tolerância a Falhas — Auto-recuperação Swarm"
Write-Host ""
Write-Host "  O Swarm detecta containers com falha e reinicia automaticamente." -ForegroundColor White
Write-Host ""

# Pegar ID de um container do backend rodando
$backendContainer = docker exec $ManagerName docker ps --filter "label=com.docker.swarm.service.name=${StackName}_backend" --format "{{.ID}}" 2>$null | Select-Object -First 1

if ($backendContainer) {
    Write-Host "  Container backend encontrado: $backendContainer" -ForegroundColor Yellow
    Write-Host "  Simulando falha (docker stop)..." -ForegroundColor Red

    docker exec $ManagerName docker stop $backendContainer 2>&1 | Out-Null
    Write-Host "  Container parado! Aguardando Swarm detectar e recuperar..." -ForegroundColor Yellow

    Wait-Converge 20
    Write-Section "Status após recuperação automática (o Swarm reiniciou a réplica!)"
    Show-Services
} else {
    Write-Host "  [AVISO] Nenhum container de backend encontrado para simular falha." -ForegroundColor Yellow
}

# ==============================================================
# Resumo final
# ==============================================================
Write-Title "DEMONSTRAÇÃO CONCLUÍDA"
Write-Host ""
Write-Host "  Conceitos demonstrados:" -ForegroundColor White
Write-Host "    ✓ Cluster Swarm: 1 Manager + 2 Workers (Docker-in-Docker)" -ForegroundColor Green
Write-Host "    ✓ Escalonamento horizontal (Scale UP/DOWN) em tempo real" -ForegroundColor Green
Write-Host "    ✓ Representação gráfica com Docker Visualizer" -ForegroundColor Green
Write-Host "    ✓ Tolerância a falhas e auto-recuperação de containers" -ForegroundColor Green
Write-Host "    ✓ Balanceamento de carga via Nginx + Swarm ingress" -ForegroundColor Green
Write-Host ""
Write-Host "  Referência: Descomplicando o Docker — Jeferson Fernando" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Para encerrar: .\setup-swarm-dind.ps1 -CleanUp" -ForegroundColor Yellow
Write-Host ""
