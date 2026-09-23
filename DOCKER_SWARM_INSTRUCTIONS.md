# Implantação com Docker Swarm

Este guia demonstra como criar a infraestrutura descrita utilizando **Docker Swarm**. Atendendo aos requisitos propostos (como descrito no livro *"Descomplicando o Docker"* do Jeferson Fernando), iremos demonstrar a criação do cluster utilizando Docker-in-Docker (dind) ou VMs, e em seguida realizar o deploy da nossa stack.

## 1. Construção das Imagens

No Swarm, os workers precisam ter acesso às imagens. Para testes locais, você pode fazer o build em cada nó, ou usar um registry local. Como demonstração básica, primeiro garanta que as imagens estão compiladas:

```bash
# Build do backend
docker build -t defesacivil-backend:latest ./defesa-backend

# Build do frontend
docker build -t defesacivil-frontend:latest .
```

> **Nota:** Em produção, você faria um `docker push` para o Docker Hub ou um registry privado (ex: `meu-registry.com/defesacivil-backend:latest`) e alteraria o arquivo `docker-compose.yml` de acordo.

## 2. Inicializando o Cluster Swarm

### Opção A: Clusterização via Docker-in-Docker (DinD)

Podemos simular um cluster de 3 nós (1 Manager e 2 Workers) diretamente na sua máquina usando contêineres Docker rodando Docker:

```bash
# Criar a rede para o cluster
docker network create --driver bridge swarm-network

# Criar o Node Manager
docker run -d --privileged --name manager --hostname manager -p 8080:8080 -p 8081:8081 -p 3000:3000 -v /var/run/docker.sock:/var/run/docker.sock docker:dind

# Entrar no Manager e inicializar o Swarm
docker exec -it manager docker swarm init

# O comando acima retornará o token do worker. Guarde-o (algo como: docker swarm join --token SWMTKN-...)
WORKER_TOKEN=$(docker exec manager docker swarm join-token -q worker)
MANAGER_IP=$(docker exec manager docker info -f "{{.Swarm.NodeAddr}}")

# Criar os Nodes Workers e ingressar no cluster
docker run -d --privileged --name worker1 --hostname worker1 docker:dind
docker exec -it worker1 docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377

docker run -d --privileged --name worker2 --hostname worker2 docker:dind
docker exec -it worker2 docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377
```

### Opção B: Utilizando VMs (Multipass ou Docker Machine)

Se preferir usar máquinas virtuais:

```bash
# Inicializar o swarm na máquina principal (Manager)
docker swarm init

# Copiar o token exibido e colar nas VMs/servidores workers
docker swarm join --token <TOKEN> <IP_DO_MANAGER>:2377
```

## 3. Deploy da Infraestrutura como Código (IaC)

A infraestrutura foi definida no arquivo `docker-compose.yml` da raiz do projeto, que contém:

- **db**: 1 réplica (fixado no manager).
- **backend**: 3 réplicas para alta disponibilidade.
- **frontend**: 2 réplicas.
- **visualizer**: 1 réplica (fixado no manager) para observabilidade gráfica.

Para realizar o deploy no Swarm (Stack):

```bash
# Faça o deploy da stack nomeada "defesacivil"
docker stack deploy -c docker-compose.yml defesacivil
```

## 4. Verificação

Após o deploy, você pode validar o provisionamento:

```bash
# Listar os nós do cluster (verificar manager e workers)
docker node ls

# Listar os serviços rodando (ver as réplicas)
docker service ls

# Ver o detalhe de onde cada réplica está alocada
docker stack ps defesacivil
```

### Representação Gráfica (Docker Visualizer)

Conforme a referência ao livro *"Descomplicando o Docker"*, utilizamos a imagem `dockersamples/visualizer`.

Acesse no seu navegador: **http://localhost:8081** (ou o IP do node manager) e você verá o painel gráfico mostrando o cluster, os nós (Manager e Workers) e como os contêineres do backend (3), frontend (2) e db (1) foram distribuídos entre eles.
