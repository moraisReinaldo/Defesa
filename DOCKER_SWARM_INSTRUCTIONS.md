# Infraestrutura Docker — Sistema Defesa em Foco

> **Disciplina:** Sistemas Distribuídos / Computação em Nuvem  
> **Referência:** *Descomplicando o Docker* — Jeferson Fernando

---

## Arquitetura da Solução

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DOCKER SWARM CLUSTER (3 nós)                     │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     MANAGER NODE                              │   │
│  │   ┌─────────────┐  ┌──────────┐  ┌───────────────────────┐  │   │
│  │   │  PostgreSQL │  │  MinIO   │  │  Nginx Load Balancer  │  │   │
│  │   │  (1 réplica)│  │ (1 répl.)│  │      (1 réplica)      │  │   │
│  │   └─────────────┘  └──────────┘  └───────────────────────┘  │   │
│  │   ┌──────────────────────────────────────────────────────┐   │   │
│  │   │           Docker Visualizer (porta 8081)              │   │   │
│  │   └──────────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────┐  ┌──────────────────────────────┐     │
│  │       WORKER NODE 1       │  │        WORKER NODE 2          │     │
│  │  ┌──────────┐ ┌────────┐ │  │  ┌──────────┐ ┌──────────┐  │     │
│  │  │ Backend  │ │Frontend│ │  │  │ Backend  │ │ Backend  │  │     │
│  │  │ (répl.1) │ │(répl.1)│ │  │  │ (répl.2) │ │ (répl.3) │  │     │
│  │  └──────────┘ └────────┘ │  │  └──────────┘ └──────────┘  │     │
│  │              ┌────────┐  │  │              ┌──────────┐    │     │
│  │              │Frontend│  │  │              └──────────┘    │     │
│  │              │(répl.2)│  │  │                              │     │
│  │              └────────┘  │  │                              │     │
│  └──────────────────────────┘  └──────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
         ▲ Swarm Ingress (roteamento automático entre nós)
```

---

## Imagens Docker (Dockerfiles)

O projeto possui **4 imagens customizadas**, cada uma com Dockerfile próprio:

### 1. `defesacivil-backend:latest` — Spring Boot API

**Arquivo:** [`defesa-backend/Dockerfile`](./defesa-backend/Dockerfile)

| Característica | Detalhe |
|---|---|
| Base (build) | `maven:3.9.9-eclipse-temurin-17-alpine` |
| Base (runtime) | `eclipse-temurin:17-jre-alpine` |
| Estratégia | **Multi-stage build** — build com Maven, runtime mínimo |
| Usuário | Não-root (`appuser`) |
| Health Check | `curl /actuator/health` a cada 30s |
| JVM | `UseContainerSupport` + `MaxRAMPercentage=75` |
| Labels OCI | title, description, vendor, source |

```bash
docker build -t defesacivil-backend:latest ./defesa-backend
```

### 2. `defesacivil-frontend:latest` — Flutter Web + Nginx

**Arquivo:** [`Dockerfile.flutter`](./Dockerfile.flutter)

| Característica | Detalhe |
|---|---|
| Base (build) | `ghcr.io/cirruslabs/flutter:3.22.3` |
| Base (runtime) | `nginx:1.25-alpine` |
| Estratégia | **Multi-stage build** — compila Flutter, serve via Nginx |
| SPA | Configuração `try_files` para roteamento de SPA |
| Cache | Assets com `Cache-Control: public, immutable` |
| Health Check | `wget http://localhost:80/` a cada 30s |

```bash
docker build -t defesacivil-frontend:latest .
```

### 3. `defesacivil-db:latest` — PostgreSQL Customizado

**Arquivo:** [`docker/postgres/Dockerfile`](./docker/postgres/Dockerfile)

| Característica | Detalhe |
|---|---|
| Base | `postgres:15-alpine` |
| Init scripts | `docker/postgres/init/01_init_schema.sql` (extensões) |
| Extensões | `uuid-ossp`, `pg_trgm` |
| Health Check | `pg_isready` a cada 10s |

```bash
docker build -t defesacivil-db:latest ./docker/postgres
```

### 4. `minio/minio:latest` — Object Storage (imagem oficial)

Utilizada diretamente do Docker Hub. Armazena fotos e arquivos do sistema.

---

## Docker Compose — Infraestrutura como Código (IaC)

**Arquivo:** [`docker-compose.yml`](./docker-compose.yml)

### Serviços e Réplicas

| Serviço | Imagem | Réplicas | Nó | Porta |
|---|---|:---:|---|---|
| `db` | `defesacivil-db:latest` | 1 | Manager | — |
| `minio` | `minio/minio:latest` | 1 | Manager | 9000, 9001 |
| `backend` | `defesacivil-backend:latest` | **3** | Workers | — |
| `frontend` | `defesacivil-frontend:latest` | **2** | Workers | — |
| `nginx-lb` | `nginx:1.25-alpine` | 1 | Manager | 80, 8080 |
| `visualizer` | `dockersamples/visualizer:stable` | 1 | Manager | **8081** |

### Rede

- Driver **overlay** (nativa do Swarm, multi-host)
- `attachable: true` — permite containers avulsos conectarem para debug

---

## Docker Swarm — Clusterização com Docker-in-Docker

A abordagem Docker-in-Docker (DinD) simula **múltiplos nós físicos** em containers rodando na mesma máquina, sem necessidade de VMs.

### Inicialização rápida (script automatizado)

```powershell
# Configura o cluster, faz build das imagens e faz o deploy completo:
.\setup-swarm-dind.ps1

# Se as imagens já foram buildadas antes:
.\setup-swarm-dind.ps1 -SkipBuild

# Limpar tudo após a apresentação:
.\setup-swarm-dind.ps1 -CleanUp
```

### Passo a passo manual

#### 1. Build das Imagens

```bash
# Banco de dados customizado
docker build -t defesacivil-db:latest ./docker/postgres

# Backend (Spring Boot)
docker build -t defesacivil-backend:latest ./defesa-backend

# Frontend (Flutter Web)
docker build -t defesacivil-frontend:latest .
```

#### 2. Criar Rede e Nós DinD

```bash
# Rede bridge para comunicação entre os nós DinD
docker network create --driver bridge swarm-dind-net

# Nó Manager (expõe as portas públicas)
docker run -d --privileged \
  --name swarm-manager --hostname swarm-manager \
  --network swarm-dind-net \
  -p 80:80 -p 8080:8080 -p 8081:8081 -p 9000:9000 -p 9001:9001 \
  docker:dind

# Nó Worker 1
docker run -d --privileged \
  --name swarm-worker1 --hostname swarm-worker1 \
  --network swarm-dind-net \
  docker:dind

# Nó Worker 2
docker run -d --privileged \
  --name swarm-worker2 --hostname swarm-worker2 \
  --network swarm-dind-net \
  docker:dind
```

#### 3. Inicializar o Swarm

```bash
# Aguardar os Docker daemons DinD iniciarem
sleep 10

# Inicializar o Swarm no Manager
MANAGER_IP=$(docker inspect swarm-manager \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

docker exec swarm-manager docker swarm init --advertise-addr $MANAGER_IP

# Obter o token de Worker
WORKER_TOKEN=$(docker exec swarm-manager docker swarm join-token -q worker)

# Juntar os Workers ao cluster
docker exec swarm-worker1 docker swarm join \
  --token $WORKER_TOKEN ${MANAGER_IP}:2377

docker exec swarm-worker2 docker swarm join \
  --token $WORKER_TOKEN ${MANAGER_IP}:2377

# Verificar o cluster
docker exec swarm-manager docker node ls
```

#### 4. Transferir Imagens para os Nós

```bash
# Transferir imagens para o Manager e Workers via pipe
docker save defesacivil-db:latest | docker exec -i swarm-manager docker load
docker save defesacivil-backend:latest | docker exec -i swarm-manager docker load
docker save defesacivil-backend:latest | docker exec -i swarm-worker1 docker load
docker save defesacivil-backend:latest | docker exec -i swarm-worker2 docker load
docker save defesacivil-frontend:latest | docker exec -i swarm-manager docker load
docker save defesacivil-frontend:latest | docker exec -i swarm-worker1 docker load
docker save defesacivil-frontend:latest | docker exec -i swarm-worker2 docker load
```

#### 5. Criar Config e Deploy da Stack

```bash
# Copiar arquivos para o Manager
docker cp docker-compose.yml swarm-manager:/docker-compose.yml
docker exec swarm-manager mkdir -p /nginx
docker cp nginx/nginx-lb.conf swarm-manager:/nginx/nginx-lb.conf

# Criar a Docker Config para o Nginx
docker exec swarm-manager sh -c \
  "cat /nginx/nginx-lb.conf | docker config create nginx_lb_conf -"

# DEPLOY DA STACK (Infraestrutura como Código!)
docker exec swarm-manager \
  docker stack deploy -c /docker-compose.yml defesacivil
```

#### 6. Verificação

```bash
# Listar nós do cluster
docker exec swarm-manager docker node ls

# Listar serviços e réplicas
docker exec swarm-manager docker service ls

# Ver onde cada container foi alocado
docker exec swarm-manager docker stack ps defesacivil
```

---

## Demonstração ao Vivo — Variação de Réplicas

```powershell
# Script completo de demonstração (recomendado para a apresentação):
.\demo-scaling.ps1
```

### Comandos individuais de escalonamento

```bash
# Scale UP: Backend de 3 para 5 réplicas
docker exec swarm-manager docker service scale defesacivil_backend=5

# Scale UP: Frontend de 2 para 4 réplicas
docker exec swarm-manager docker service scale defesacivil_frontend=4

# Scale DOWN: Reduzir backend para 3 réplicas
docker exec swarm-manager docker service scale defesacivil_backend=3

# Scale DOWN: Reduzir frontend para 2 réplicas
docker exec swarm-manager docker service scale defesacivil_frontend=2
```

---

## Representação Gráfica — Docker Visualizer

> **Referência:** *Descomplicando o Docker* — Jeferson Fernando

O serviço `visualizer` usa a imagem `dockersamples/visualizer:stable` para exibir graficamente o estado do cluster Swarm.

**Acesse:** [http://localhost:8081](http://localhost:8081)

O Visualizer mostra em tempo real:
- Os **nós** do cluster (Manager e Workers)
- Os **containers** de cada serviço rodando em cada nó
- A **distribuição** das réplicas pelos nós
- O impacto **visual** ao escalar serviços (Scale UP/DOWN)

```yaml
# Trecho do docker-compose.yml — Visualizer
visualizer:
  image: dockersamples/visualizer:stable
  ports:
    - "8081:8080"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  deploy:
    replicas: 1
    placement:
      constraints:
        - node.role == manager   # Fixado no Manager para acesso ao socket
```

---

## Endpoints da Aplicação

| Serviço | URL | Descrição |
|---|---|---|
| Frontend | http://localhost:80 | Flutter Web App |
| Backend API | http://localhost:8080 | Spring Boot REST API |
| **Docker Visualizer** | **http://localhost:8081** | **Painel gráfico do Swarm** |
| MinIO Console | http://localhost:9001 | Object Storage Web UI |
| MinIO API | http://localhost:9000 | API S3-compatível |

---

## Checklist dos Requisitos

- [x] **Dockerfiles customizados** para todos os serviços (Backend, Frontend, PostgreSQL)
- [x] **Docker Swarm** com clusterização usando **Docker-in-Docker** (3 nós: 1 Manager + 2 Workers)
- [x] **Docker Compose** como Infraestrutura como Código (IaC)
- [x] **Variação de réplicas** demonstrada em tempo real (Scale UP/DOWN)
- [x] **Docker Visualizer** (`dockersamples/visualizer`) para representação gráfica
- [x] Referência ao livro *"Descomplicando o Docker"* de Jeferson Fernando
