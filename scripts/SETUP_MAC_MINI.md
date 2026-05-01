# 🖥️ Setup Mac Mini 2014 — Servidor Defesa Civil

Guia completo para configurar o Mac Mini 2014 (Intel) como servidor self-hosted do backend Defesa Civil.

## Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    MAC MINI 2014 (Intel)                     │
│                                                             │
│  ┌──────────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │ PostgreSQL   │  │  MinIO   │  │  Spring Boot (8080)  │  │
│  │   (5432)     │  │  (9000)  │  │  defesa-backend.jar  │  │
│  └──────┬───────┘  └────┬─────┘  └──────────┬───────────┘  │
│         │               │                   │               │
│         │    ┌──────────┴───────────────────┘               │
│         │    │                                              │
│  ┌──────┴────┴──────────────────────────────────────────┐   │
│  │              Cloudflare Quick Tunnels                │   │
│  │  API:  https://xxxx.trycloudflare.com → :8080        │   │
│  │  MinIO: https://yyyy.trycloudflare.com → :9000       │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │  Tailscale   │  │  AdGuard     │                        │
│  │  (VPN mesh)  │  │  Home (DNS)  │                        │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
          │
          │  Internet (Cloudflare Tunnel)
          ▼
┌─────────────────────┐
│  App Flutter (móvel) │
│  Acessa de qualquer  │
│  lugar do mundo      │
└─────────────────────┘
```

## Pré-requisitos

Instalar via Homebrew (se ainda não estiver):

```bash
# Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Java 17
brew install openjdk@17
sudo ln -sfn /usr/local/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk

# PostgreSQL 14
brew install postgresql@14
brew services start postgresql@14

# MinIO
brew install minio

# Cloudflared
brew install cloudflare/cloudflare/cloudflared

# Verificar instalações
java -version
psql --version
minio --version
cloudflared --version
```

## 1. Configurar PostgreSQL

```bash
# Criar banco de dados
createdb defesacivil_db

# Criar usuário (troque a senha)
psql -d defesacivil_db -c "CREATE USER defesacivil WITH PASSWORD 'SUA_SENHA_DB';"
psql -d defesacivil_db -c "GRANT ALL PRIVILEGES ON DATABASE defesacivil_db TO defesacivil;"
psql -d defesacivil_db -c "GRANT ALL ON SCHEMA public TO defesacivil;"

# Testar conexão
psql -U defesacivil -d defesacivil_db -c "SELECT 1;"
```

## 2. Configurar MinIO

```bash
# Criar diretório de dados
mkdir -p ~/minio-data

# Testar manualmente primeiro
MINIO_ROOT_USER=admin MINIO_ROOT_PASSWORD=SUA_SENHA_MINIO minio server ~/minio-data --console-address :9001

# Abrir http://localhost:9001 no navegador para acessar o console
# Criar o bucket "defesa-civil" no console web
```

## 3. Configurar application.properties

```bash
cd ~/Defesa/defesa-backend/src/main/resources/

# Copiar template
cp application.properties.example application.properties

# Editar com seus valores reais
nano application.properties
```

Valores que **DEVEM** ser alterados:

| Propriedade | Valor |
|---|---|
| `spring.datasource.username` | Seu usuário PostgreSQL |
| `spring.datasource.password` | Sua senha PostgreSQL |
| `minio.endpoint` | `http://localhost:9000` (será atualizado pelo script) |
| `minio.secret-key` | Sua senha do MinIO |
| `app.admin.password` | Senha master do admin (BCrypt em produção) |
| `app.jwt.secret` | String aleatória 32+ caracteres |
| `spring.mail.username` | Seu Gmail (para notificações) |
| `spring.mail.password` | App password do Gmail |
| `app.admin.notification.email` | Seu email para receber alertas |

## 4. Build e Teste Manual

```bash
cd ~/Defesa/defesa-backend

# Dar permissão ao Maven Wrapper
chmod +x mvnw

# Build
./mvnw package -DskipTests

# Testar manualmente
java -jar target/backend-0.0.1-SNAPSHOT.jar

# Em outro terminal, testar:
curl http://localhost:8080/actuator/health
# Deve retornar: {"status":"UP"}

curl http://localhost:8080/api/health
# Deve retornar: {"status":"UP"}
```

## 5. Instalar LaunchAgents e LaunchDaemon

```bash
cd ~/Defesa/scripts/

# ⚠️  IMPORTANTE: Editar com.minio.plist e trocar MINIO_ROOT_PASSWORD
nano com.minio.plist

# Copiar LaunchAgents (rodam como seu usuário)
cp com.minio.plist ~/Library/LaunchAgents/
cp com.cloudflared.tunnel.plist ~/Library/LaunchAgents/
cp com.cloudflared.minio.plist ~/Library/LaunchAgents/
cp com.defesacivil.spring.plist ~/Library/LaunchAgents/

# Copiar LaunchDaemon (roda como root no boot)
sudo cp com.defesacivil.startup.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/com.defesacivil.startup.plist
sudo chmod 644 /Library/LaunchDaemons/com.defesacivil.startup.plist

# Copiar script de startup
sudo cp startup-server.sh /usr/local/bin/startup-server.sh
sudo chmod +x /usr/local/bin/startup-server.sh

# Criar diretório de logs
mkdir -p ~/logs
```

## 6. Testar Cada Serviço

```bash
# Carregar MinIO
launchctl load ~/Library/LaunchAgents/com.minio.plist
sleep 3
curl -s http://localhost:9000/minio/health/live && echo "MinIO OK"

# Carregar Cloudflare Tunnel API
launchctl load ~/Library/LaunchAgents/com.cloudflared.tunnel.plist
sleep 10
grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' ~/logs/cloudflared-error.log | tail -1

# Carregar Cloudflare Tunnel MinIO
launchctl load ~/Library/LaunchAgents/com.cloudflared.minio.plist
sleep 10
grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' ~/logs/cloudflared-minio-error.log | tail -1

# Carregar Spring Boot
launchctl load ~/Library/LaunchAgents/com.defesacivil.spring.plist
sleep 20
curl -s http://localhost:8080/actuator/health
```

## 7. Testar o Boot Completo

```bash
# Carregar o daemon de startup
sudo launchctl load /Library/LaunchDaemons/com.defesacivil.startup.plist

# Ou reiniciar o Mac Mini para testar de verdade:
sudo reboot

# Após o boot, verificar o log:
cat ~/logs/startup.log
```

## Troubleshooting

### Verificar se um serviço está rodando
```bash
launchctl list | grep -E "minio|cloudflared|defesacivil|spring"
```

### Ver logs de um serviço
```bash
tail -50 ~/logs/startup.log          # Log geral do startup
tail -50 ~/logs/spring-boot-stderr.log  # Log do Spring Boot
tail -50 ~/logs/minio-stderr.log        # Log do MinIO
tail -50 ~/logs/cloudflared-error.log   # Log do Cloudflare (API)
```

### Reiniciar um serviço manualmente
```bash
# Parar
launchctl unload ~/Library/LaunchAgents/com.defesacivil.spring.plist

# Iniciar
launchctl load ~/Library/LaunchAgents/com.defesacivil.spring.plist
```

### PostgreSQL não conecta
```bash
brew services list
brew services restart postgresql@14
pg_isready
```

### Spring Boot não sobe
```bash
# Verificar se a porta 8080 está em uso
lsof -i :8080

# Matar processo na porta
kill $(lsof -t -i :8080)

# Rebuild
cd ~/Defesa/defesa-backend && ./mvnw clean package -DskipTests
```

### MinIO não responde
```bash
# Verificar porta
lsof -i :9000

# Verificar se o diretório de dados existe
ls -la ~/minio-data/
```

### URLs do Cloudflare não aparecem
```bash
# Verificar se cloudflared está rodando
ps aux | grep cloudflared

# Verificar logs
cat ~/logs/cloudflared-error.log
cat ~/logs/cloudflared-minio-error.log

# Reiniciar tunnel
launchctl unload ~/Library/LaunchAgents/com.cloudflared.tunnel.plist
launchctl load ~/Library/LaunchAgents/com.cloudflared.tunnel.plist
```

## Estrutura de Arquivos no Mac Mini

```
/Users/reinaldohenriquemorais/
├── Defesa/
│   └── defesa-backend/
│       ├── src/main/resources/
│       │   ├── application.properties          ← SUAS CONFIGS (ignorado pelo git)
│       │   └── application.properties.example  ← Template
│       └── target/
│           └── backend-0.0.1-SNAPSHOT.jar      ← JAR compilado
├── minio-data/                                 ← Dados do MinIO
├── logs/
│   ├── startup.log                            ← Log principal
│   ├── spring-boot-stdout.log
│   ├── spring-boot-stderr.log
│   ├── minio-stdout.log
│   ├── minio-stderr.log
│   ├── cloudflared-error.log                  ← URL da API aqui
│   └── cloudflared-minio-error.log            ← URL do MinIO aqui
└── Library/LaunchAgents/
    ├── com.minio.plist
    ├── com.cloudflared.tunnel.plist
    ├── com.cloudflared.minio.plist
    └── com.defesacivil.spring.plist

/usr/local/bin/startup-server.sh               ← Script de boot
/Library/LaunchDaemons/com.defesacivil.startup.plist  ← Daemon de boot
```
