# Especificação da API — Defesa em Foco

## 1. Domínio de Aplicação

**Defesa Civil — Defesa em Foco**

Sistema de gerenciamento de ocorrências de Defesa Civil para registro, acompanhamento e resolução de incidentes urbanos (alagamentos, deslizamentos, incêndios, etc.). A aplicação permite que cidadãos reportem ocorrências geolocalizadas e que agentes e administradores da Defesa Civil gerenciem as respostas.

## 2. Integrantes do Grupo

| Nome | Prontuário |
|------|------------|
| Reinaldo Henrique Morais | BP3052061 |
| Pedro Guedes de Azevedo | BP305165X |

## 3. Entidades e Relacionamentos

### 3.1 Entidades

| # | Entidade | Descrição | Campos Principais |
|---|----------|-----------|-------------------|
| 1 | **Ocorrência** | Registro de um incidente de defesa civil | id, tipo, descricao, latitude, longitude, cidade, caminhoFoto, dataHora, status, dataResolucao, agentes, criadoPorAgente, agenteNoLocal, dataChegadaAgente, descricaoSituacao |
| 2 | **Usuário** | Pessoa cadastrada no sistema (cidadão, agente ou administrador) | id, nome, email, telefone, senha (BCrypt), cidade, especialidade, role, status, dataCriacao, fcmToken |
| 3 | **Cidade** | Município registrado no sistema | id, codigo, nome |
| 4 | **PontoInteresse** | Marcação no mapa (abrigo, hospital, base, etc.) | id, tipo, descricao, latitude, longitude, cidade, criadoPor |

### 3.2 Relacionamentos

```
┌──────────┐    1:N     ┌─────────────┐    N:M    ┌──────────┐
│  Cidade  │───────────▶│  Ocorrência  │◀─────────│  Usuário  │
│          │            │              │           │ (agentes) │
│          │    1:N     │              │   N:1     │           │
│          │───────────▶│              │◀──────────│  (autor)  │
│          │            └──────────────┘           │           │
│          │    1:N                                │           │
│          │───────────────────────────────────────│           │
│          │    1:N     ┌──────────────┐           │           │
│          │───────────▶│PontoInteresse│           │           │
└──────────┘            └──────────────┘           └───────────┘
```

| Tipo | De | Para | Descrição |
|------|----|------|-----------|
| **Um-para-Muitos** | Cidade | Ocorrência | Uma cidade possui muitas ocorrências |
| **Um-para-Muitos** | Cidade | Usuário | Uma cidade possui muitos usuários |
| **Um-para-Muitos** | Cidade | PontoInteresse | Uma cidade possui muitos pontos de interesse |
| **Um-para-Muitos** | Usuário (autor) | Ocorrência | Um usuário pode criar muitas ocorrências |
| **Muitos-para-Muitos** | Ocorrência | Usuário (agentes) | Uma ocorrência pode ter muitos agentes atribuídos, e um agente pode estar em muitas ocorrências (tabela intermediária: `ocorrencia_agentes_atribuidos`) |

---

## 4. Modelagem da API REST

### 4.1 Autenticação (`/api/auth`)

| Verbo HTTP | Path | Body de Requisição | Body de Retorno | Status HTTP Sucesso | Status HTTP Erro |
|------------|------|--------------------|-----------------|---------------------|------------------|
| POST | `/api/auth/cadastro` | `{ "nome": "str", "email": "str", "telefone": "str", "senha": "str", "cidade": "str", "role": "CIDADAO\|ADMINISTRADOR", "concordaLGPD": true }` | `{ "message": "str", "pendente": bool }` | 200 OK | 400 Bad Request (email duplicado / LGPD não aceita) |
| POST | `/api/usuarios/login` | `{ "email": "str", "senha": "str" }` | `{ "usuario": {...}, "token": "jwt" }` | 200 OK | 401 Unauthorized (credenciais inválidas), 403 Forbidden (cadastro pendente) |
| POST | `/api/auth/admin-login` | `{ "senha": "str" }` | `{ "token": "jwt", "message": "str" }` | 200 OK | 401 Unauthorized |
| POST | `/api/auth/logout` | *(vazio)* | `{ "message": "Logout realizado com sucesso" }` | 200 OK | — |

### 4.2 Ocorrências (`/api/ocorrencias`) — CRUD Completo

| Verbo HTTP | Path | Body de Requisição | Body de Retorno | Status HTTP Sucesso | Status HTTP Erro |
|------------|------|--------------------|-----------------|---------------------|------------------|
| **POST** | `/api/ocorrencias` | `{ "tipo": "str", "descricao": "str", "latitude": num, "longitude": num, "cidade": "str", "caminhoFoto": "str\|base64", "dataHora": "str", "criadoPorAgente": bool, "agentes": "str" }` | `Ocorrencia` (JSON) | 200 OK | 400 Bad Request (campos obrigatórios ausentes) |
| **GET** | `/api/ocorrencias` | — | `Page<Ocorrencia>` (JSON paginado) | 200 OK | — |
| **GET** | `/api/ocorrencias/{id}` | — | `Ocorrencia` (JSON) | 200 OK | 404 Not Found |
| **PATCH** | `/api/ocorrencias/{id}` | `{ "tipo": "str?", "descricao": "str?", "latitude": num?, "longitude": num?, ... }` | `Ocorrencia` (JSON) | 200 OK | 404 Not Found |
| **DELETE** | `/api/ocorrencias/{id}` | — | *(vazio)* | 200 OK | 404 Not Found |
| POST | `/api/ocorrencias/{id}/aprovar` | — | `Ocorrencia` (JSON) | 200 OK | 404 Not Found |
| POST | `/api/ocorrencias/{id}/chegada` | `{ "parecer": "str?" }` | `Ocorrencia` (JSON) | 200 OK | 404 Not Found |
| POST | `/api/ocorrencias/{id}/resolver` | `{ "parecer": "str?" }` | `Ocorrencia` (JSON) | 200 OK | 404 Not Found |
| POST | `/api/ocorrencias/{id}/reativar` | — | `Ocorrencia` (JSON) | 200 OK | 404 Not Found |

*Parâmetros de query para GET lista: `cidade` (filtro), `page` (default 0), `size` (default 20)*

### 4.3 Usuários (`/api/usuarios`) — CRUD Completo

| Verbo HTTP | Path | Body de Requisição | Body de Retorno | Status HTTP Sucesso | Status HTTP Erro |
|------------|------|--------------------|-----------------|---------------------|------------------|
| **POST** | `/api/auth/cadastro` | *(ver seção Autenticação)* | *(ver seção Autenticação)* | 200 OK | 400 Bad Request |
| **GET** | `/api/usuarios` | — | `List<Usuario>` (JSON) | 200 OK | 403 Forbidden (não é ADMIN) |
| **GET** | `/api/usuarios/{id}` | — | `Usuario` (JSON) | 200 OK | 404 Not Found |
| **PUT** | `/api/usuarios/{id}` | `{ "nome": "str?", "telefone": "str?", "cidade": "str?", "role": "str?", "senha": "str?", "fcmToken": "str?" }` | `Usuario` (JSON) | 200 OK | 403 Forbidden / 404 Not Found |
| **DELETE** | `/api/usuarios/{id}` | — | *(vazio)* | 200 OK | 404 Not Found |
| GET | `/api/usuarios/agentes` | — | `List<Usuario>` (JSON) | 200 OK | — |
| POST | `/api/usuarios/promover` | `{ "email": "str" }` | `{ "message": "str", "usuario": {...} }` | 200 OK | 400 Bad Request / 404 Not Found |
| POST | `/api/usuarios/esqueci-senha` | `{ "email": "str" }` | `{ "message": "str" }` | 200 OK | — |
| POST | `/api/usuarios/resetar-senha` | `{ "email": "str", "codigo": "str", "novaSenha": "str" }` | `{ "message": "str" }` | 200 OK | 400 Bad Request (código inválido) |

### 4.4 Cidades (`/api/cidades`) — CRUD Completo

| Verbo HTTP | Path | Body de Requisição | Body de Retorno | Status HTTP Sucesso | Status HTTP Erro |
|------------|------|--------------------|-----------------|---------------------|------------------|
| **POST** | `/api/cidades` | `{ "codigo": "str", "nome": "str" }` | `Cidade` (JSON) | 200 OK | — |
| **GET** | `/api/cidades` | — | `List<Cidade>` (JSON) | 200 OK | — |
| **GET** | `/api/cidades/{id}` | — | `Cidade` (JSON) | 200 OK | 404 Not Found |
| **PUT** | `/api/cidades/{id}` | `{ "codigo": "str", "nome": "str" }` | `Cidade` (JSON) | 200 OK | 404 Not Found |
| **DELETE** | `/api/cidades/{id}` | — | *(vazio)* | 204 No Content | 404 Not Found |

### 4.5 Pontos de Interesse / Marcações (`/api/marcacoes`) — CRUD Completo

| Verbo HTTP | Path | Body de Requisição | Body de Retorno | Status HTTP Sucesso | Status HTTP Erro |
|------------|------|--------------------|-----------------|---------------------|------------------|
| **POST** | `/api/marcacoes` | `{ "tipo": "str", "descricao": "str", "latitude": num, "longitude": num, "cidade": "str", "criadoPor": "str?" }` | `PontoInteresse` (JSON) | 201 Created | 400 Bad Request |
| **GET** | `/api/marcacoes` | — | `List<PontoInteresse>` (JSON) | 200 OK | — |
| **PUT** | `/api/marcacoes/{id}` | `{ "tipo": "str", "descricao": "str", "latitude": num, "longitude": num, "cidade": "str" }` | `PontoInteresse` (JSON) | 200 OK | 404 Not Found |
| **DELETE** | `/api/marcacoes/{id}` | — | *(vazio)* | 204 No Content | 404 Not Found |

*Parâmetros de query para GET: `cidade` (filtro opcional)*

---

## 5. Tecnologias Utilizadas

| Componente | Tecnologia |
|------------|------------|
| Back-end | Java 17 + Spring Boot 3.5 + Spring Web |
| Banco de Dados | PostgreSQL |
| ORM | JPA / Hibernate |
| Autenticação | JWT (jjwt 0.12.6) + BCrypt |
| Balanceamento de Carga | NGINX (Docker) |
| Armazenamento de Arquivos | MinIO (S3-compatible) |
| Front-end | Flutter (Dart) |
| Versionamento | Git (GitHub) |
| Containerização | Docker / Docker Compose |

## 6. Autenticação e Segurança

- **JWT (JSON Web Token)**: Tokens de 24h, assinados com HMAC-SHA
- **Senha criptografada**: BCrypt via Spring Security
- **Roles**: CIDADAO, AGENTE, ADMINISTRADOR
- **Rate Limiting**: Bucket4j + Caffeine
- **CORS**: Configurável via variável de ambiente
- **Sanitização**: HtmlUtils.htmlEscape para prevenção de XSS

## 7. Balanceamento de Carga

Configuração com Docker Compose executando:
- 2 instâncias do backend Spring Boot (backend1, backend2)
- 1 NGINX como reverse proxy/load balancer (round-robin)
- PostgreSQL como banco de dados compartilhado

Arquivo de configuração NGINX: `nginx/nginx.conf`
