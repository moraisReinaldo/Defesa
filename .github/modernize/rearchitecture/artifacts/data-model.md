# Data Model: Defesa Civil Defense System

## Entity Relationship Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     DEFESA CIVIL DATA MODEL                      │
└──────────────────────────────────────────────────────────────────┘

Users
├── id (UUID/Long)
├── email (unique)
├── password_hash (bcrypt)
├── nome (full name)
├── cpf (CPF, unique)
├── role (AGENT, ADMIN)
├── active (boolean)
├── created_at (timestamp)
├── updated_at (timestamp)
└── [1:M] → Ocorrencia (author)
    └── [1:M] → Alerta (recipient)

Ocorrencia (Incidents)
├── id (UUID/Long)
├── usuario_id (FK → Users)
├── titulo (title)
├── descricao (description)
├── tipo_ocorrencia (category: ACIDENTE, INCÊNDIO, etc.)
├── latitude (GPS)
├── longitude (GPS)
├── status (ABERTO, EM_PROGRESSO, RESOLVIDO, CANCELADO)
├── prioridade (BAIXA, MÉDIA, ALTA, CRÍTICA)
├── foto_ids (FK → Fotos[])
├── created_at
├── updated_at
├── [M:1] → Usuario (author)
├── [1:M] → Foto (attachments)
└── [1:M] → Alerta (triggered_to_agents)

Foto (Attachments)
├── id (UUID/Long)
├── ocorrencia_id (FK → Ocorrencia)
├── url (MinIO object URL)
├── tipo (JPEG, PNG, MOV, MP4)
├── tamanho (bytes)
├── created_at
└── [M:1] → Ocorrencia (parent)

PontoInteresse (POI - Points of Interest)
├── id (UUID/Long)
├── nome (name)
├── descricao (description)
├── tipo_poi (category: HIDRANTE, HOSPITAL, DELEGACIA, etc.)
├── latitude (GPS)
├── longitude (GPS)
├── endereco (address)
├── cidade_id (FK → Cidade)
├── created_at
├── updated_at
├── [M:1] → Cidade (location)
└── [1:M] → Alerta (triggered_by_proximity)

Cidade (City/Municipality)
├── id (UUID/Long)
├── nome (city name)
├── estado (state abbreviation)
├── cep_inicial (postal code range start)
├── cep_final (postal code range end)
├── created_at
└── [1:M] → PontoInteresse (locations)

Alerta (Alerts/Notifications)
├── id (UUID/Long)
├── usuario_id (FK → Users)
├── ocorrencia_id (FK → Ocorrencia, nullable)
├── ponto_interesse_id (FK → PontoInteresse, nullable)
├── tipo_alerta (NOVO_INCIDENTE, PROXIMIDADE_POI, ATRIBUICAO, etc.)
├── mensagem (alert message)
├── lido (boolean - read status)
├── enviado_via (PUSH, EMAIL, IN_APP)
├── created_at
├── [M:1] → Usuario (recipient)
├── [M:1] → Ocorrencia (source, nullable)
└── [M:1] → PontoInteresse (source, nullable)
```

---

## Table Details

### Users

**Purpose**: Authentication, role-based access control

| Column | Type | Constraints | Meaning |
|--------|------|-----------|---------|
| id | UUID/Long | PK | Unique identifier |
| email | String(255) | UNIQUE, NOT NULL | Login credential |
| password_hash | String(255) | NOT NULL | Bcrypt-hashed password |
| nome | String(255) | NOT NULL | Full name |
| cpf | String(11) | UNIQUE, NOT NULL | Brazilian CPF (national ID) |
| role | Enum(AGENT, ADMIN) | NOT NULL | AGENT = field operator, ADMIN = web admin |
| active | Boolean | NOT NULL, default=true | Soft delete flag |
| created_at | Timestamp | NOT NULL, default=NOW() | Account creation |
| updated_at | Timestamp | NOT NULL, default=NOW() | Last modification |

**Indexes**: email (unique), cpf (unique), role, active

**Queries**:
- Login: `SELECT * FROM users WHERE email = ? AND password_hash = ?`
- List agents: `SELECT * FROM users WHERE role = 'AGENT' AND active = true`
- Permissions: `SELECT role FROM users WHERE id = ?`

---

### Ocorrencia (Incidents)

**Purpose**: Core business entity; central to all workflows

| Column | Type | Constraints | Meaning |
|--------|------|-----------|---------|
| id | UUID/Long | PK | Unique identifier |
| usuario_id | UUID/Long | FK(Users), NOT NULL | Author (field operator) |
| titulo | String(255) | NOT NULL | Incident title |
| descricao | Text | | Detailed description |
| tipo_ocorrencia | Enum | NOT NULL | Category (ACIDENTE, INCÊNDIO, ALAGAMENTO, etc.) |
| latitude | Double | NOT NULL | GPS latitude |
| longitude | Double | NOT NULL | GPS longitude |
| status | Enum(ABERTO, EM_PROGRESSO, RESOLVIDO, CANCELADO) | NOT NULL, default=ABERTO | Lifecycle state |
| prioridade | Enum(BAIXA, MÉDIA, ALTA, CRÍTICA) | NOT NULL, default=MÉDIA | Urgency level |
| created_at | Timestamp | NOT NULL, default=NOW() | Report creation time |
| updated_at | Timestamp | NOT NULL, default=NOW() | Last status update |

**Indexes**: usuario_id (FK), status, tipo_ocorrencia, created_at (for sorting), (latitude, longitude) (for geo queries)

**Queries**:
- List all open incidents: `SELECT * FROM ocorrencia WHERE status IN ('ABERTO', 'EM_PROGRESSO')`
- By user: `SELECT * FROM ocorrencia WHERE usuario_id = ?`
- By type: `SELECT * FROM ocorrencia WHERE tipo_ocorrencia = ?`
- Geo-proximity: `SELECT * FROM ocorrencia WHERE ST_Distance(ST_Point(latitude, longitude), ST_Point(?, ?)) < ?`

---

### Foto (Attachments)

**Purpose**: Store references to photos/videos uploaded to MinIO

| Column | Type | Constraints | Meaning |
|--------|------|-----------|---------|
| id | UUID/Long | PK | Unique identifier |
| ocorrencia_id | UUID/Long | FK(Ocorrencia), NOT NULL | Parent incident |
| url | String(512) | NOT NULL | MinIO S3 object URL (full path) |
| tipo | Enum(JPEG, PNG, MOV, MP4, etc.) | NOT NULL | File type |
| tamanho | Long | NOT NULL | File size in bytes |
| created_at | Timestamp | NOT NULL, default=NOW() | Upload timestamp |

**Indexes**: ocorrencia_id (FK), created_at

**Queries**:
- List photos for incident: `SELECT * FROM foto WHERE ocorrencia_id = ? ORDER BY created_at DESC`
- Total size per incident: `SELECT SUM(tamanho) FROM foto WHERE ocorrencia_id = ?`

---

### PontoInteresse (POI)

**Purpose**: Mark critical infrastructure & resources on map

| Column | Type | Constraints | Meaning |
|--------|------|-----------|---------|
| id | UUID/Long | PK | Unique identifier |
| nome | String(255) | NOT NULL | POI name (e.g., "Hidrante Centro") |
| descricao | Text | | Detailed description |
| tipo_poi | Enum | NOT NULL | Type (HIDRANTE, HOSPITAL, DELEGACIA, BOMBEIROS, CENTRO_CIVIL_DEFENSE, etc.) |
| latitude | Double | NOT NULL | GPS latitude |
| longitude | Double | NOT NULL | GPS longitude |
| endereco | String(512) | NOT NULL | Street address |
| cidade_id | UUID/Long | FK(Cidade), NOT NULL | Associated city |
| created_at | Timestamp | NOT NULL, default=NOW() | Creation time |
| updated_at | Timestamp | NOT NULL, default=NOW() | Last update |

**Indexes**: cidade_id (FK), tipo_poi, (latitude, longitude) (for geo queries)

**Queries**:
- List POIs by type: `SELECT * FROM ponto_interesse WHERE tipo_poi = ?`
- By city: `SELECT * FROM ponto_interesse WHERE cidade_id = ?`
- Geo-proximity (near incident): `SELECT * FROM ponto_interesse WHERE ST_Distance(ST_Point(latitude, longitude), ST_Point(?, ?)) < 5000`

---

### Cidade (City)

**Purpose**: Geographic hierarchy for POI management

| Column | Type | Constraints | Meaning |
|--------|------|-----------|---------|
| id | UUID/Long | PK | Unique identifier |
| nome | String(255) | NOT NULL | City name (e.g., "São Paulo") |
| estado | String(2) | NOT NULL | State abbreviation (e.g., "SP") |
| cep_inicial | String(8) | NOT NULL | Postal code range start |
| cep_final | String(8) | NOT NULL | Postal code range end |
| created_at | Timestamp | NOT NULL, default=NOW() | Creation time |

**Indexes**: estado, (cep_inicial, cep_final)

**Queries**:
- Lookup by postal code: `SELECT * FROM cidade WHERE cep_inicial <= ? AND cep_final >= ?`
- All cities in state: `SELECT * FROM cidade WHERE estado = ?`

---

### Alerta (Alerts)

**Purpose**: Notify users of incidents & important events (push notifications, in-app)

| Column | Type | Constraints | Meaning |
|--------|------|-----------|---------|
| id | UUID/Long | PK | Unique identifier |
| usuario_id | UUID/Long | FK(Users), NOT NULL | Alert recipient |
| ocorrencia_id | UUID/Long | FK(Ocorrencia), nullable | Related incident (if triggered by incident) |
| ponto_interesse_id | UUID/Long | FK(PontoInteresse), nullable | Related POI (if proximity alert) |
| tipo_alerta | Enum | NOT NULL | Type (NOVO_INCIDENTE, PROXIMIDADE_POI, ATRIBUICAO, etc.) |
| mensagem | String(512) | NOT NULL | Alert message text |
| lido | Boolean | NOT NULL, default=false | Read status |
| enviado_via | Enum(PUSH, EMAIL, IN_APP) | NOT NULL | Delivery channel |
| created_at | Timestamp | NOT NULL, default=NOW() | Alert creation time |

**Indexes**: usuario_id (FK), ocorrencia_id (FK), lido, tipo_alerta, created_at (for feed ordering)

**Queries**:
- User's unread alerts: `SELECT * FROM alerta WHERE usuario_id = ? AND lido = false ORDER BY created_at DESC`
- Mark read: `UPDATE alerta SET lido = true WHERE id = ?`
- Alert feed: `SELECT * FROM alerta WHERE usuario_id = ? ORDER BY created_at DESC LIMIT 50`

---

## Data Flow Patterns

### Incident Creation Workflow

```
1. Mobile: User clicks "Report Incident"
   → Captures GPS, takes photo(s)
   → Sends POST /api/ocorrencia + multipart photos

2. Backend (Spring): UsuarioController.createIncident()
   → Validates JWT token (user identity)
   → Saves Ocorrencia row + metadata to PostgreSQL
   → Uploads photos to MinIO (S3 API)
   → Saves Foto rows linking back to Ocorrencia
   → Returns 201 + incident_id + photo URLs

3. Backend → n8n: Trigger webhook "novo_incidente"
   → Send push notification via OneSignal to admins

4. Mobile: Polls incident status
   → GET /api/ocorrencia/{id}
   → Displays status + attachments from URLs

5. Web (Admin): Dashboard polls incidents
   → GET /api/ocorrencia?status=ABERTO
   → Displays list + photos
```

### Photo Upload Details

```
POST /api/ocorrencia/{id}/upload
├─ Request: multipart/form-data (1+ files)
├─ Backend Processing:
│   ├─ Validate: user_id matches incident author OR admin
│   ├─ Store to MinIO: s3://defesa/incidents/{ocorrencia_id}/{filename}
│   ├─ Save Foto row: url = MinIO endpoint + object path
│   └─ Response: 201 + array of photo_ids + URLs
└─ Frontend: Displays thumbnails immediately (polling for completion)
```

### JWT Token Lifecycle

```
1. Login:  POST /api/auth/login {email, password}
   → Backend validates password
   → Generates JWT (exp: 1 hour by default)
   → Returns token

2. Client: Stores JWT in Hive (Flutter) → Bearer header in subsequent requests

3. Token Refresh: GET /api/auth/refresh
   → Backend validates current JWT (not expired?)
   → Returns new JWT

4. Logout: POST /api/auth/logout
   → Client: Delete JWT from Hive
   → Backend: (optional) Token revocation list
```

---

## Key Entities Summary

| Entity | Purpose | Owner | Lifecycle |
|--------|---------|-------|-----------|
| **Users** | Authentication + RBAC | Admin (web) creates agents | Long-lived (months/years) |
| **Ocorrencia** | Incident reports | Field operator creates, admin manages | Transient (days → resolved) |
| **Foto** | Photo attachments | Auto-linked to Ocorrencia | Tied to parent incident |
| **PontoInteresse** | Map landmarks | Admin (web) manages | Long-lived (reference data) |
| **Cidade** | Geographic hierarchy | System (seeded on init) | Static (rarely changes) |
| **Alerta** | Notifications | System (generated by events) | Transient (archived after read) |

---

## Known Data Concerns

1. **Photo Storage Growth**
   - MinIO disk space is on Mac mini local storage (limited capacity)
   - No archival/cleanup policy evident
   - **Action**: Implement photo retention policy (e.g., delete after 90 days)

2. **Geo Queries**
   - PostgreSQL does not include PostGIS extension (based on pom.xml + project-structure findings)
   - Current geo queries likely use raw `SQRT((lat1-lat2)^2 + (lon1-lon2)^2)` math
   - **Issue**: Not accurate (Haversine/vincenty distance > accuracy needed for emergency response)
   - **Action**: Consider adding PostGIS extension + spatial indexes

3. **Backup Strategy**
   - No backup/replication apparent in deployment scripts
   - **Risk**: Data loss if Mac mini fails
   - **Action**: Implement daily backup to external storage or cloud

4. **Soft Deletes**
   - `active` flag on Users suggests soft-delete pattern
   - May affect list queries if not filtering `WHERE active = true`
   - **Action**: Audit all queries for soft-delete consistency

