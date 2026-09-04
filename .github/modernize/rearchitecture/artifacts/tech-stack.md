# Tech Stack: Defesa Civil Defense System

## Runtime Versions

| Component | Version | Type | Notes |
|-----------|---------|------|-------|
| **Dart** | 3.5+ (from pubspec.yaml) | Language (Frontend) | Mobile + Web compilation |
| **Flutter** | 3.5+ | Framework (Mobile + Web) | Cross-platform UI framework |
| **Java** | 17 (from pom.xml) | Language (Backend) | Spring Boot runtime |
| **Spring Boot** | 3.5.14 | Framework (Backend) | REST API, dependency injection |
| **PostgreSQL** | 14 | Database | Relational persistence |
| **MinIO** | 8.6.0 | Object Storage | S3-compatible file storage |

---

## Frontend Dependencies (Dart/Flutter)

### Core Frameworks
- **flutter**: 3.5+ — UI framework (mobile + web)
- **provider**: 6.0+ — State management (reactive)
- **go_router**: Latest — Routing (mobile + web)

### API Communication
- **dio**: 5.4 — HTTP client (REST API calls)
- **http**: 1.6 — Alternative HTTP client (legacy, may coexist)

### Geolocation & Mapping
- **geolocator**: Latest — GPS positioning
- **flutter_map**: Latest — Map visualization
- **geocoding**: Latest — Address ↔ GPS conversion
- **latlong2**: Latest — Coordinate handling

### Storage & Caching
- **hive**: 2.2+ — Local key-value storage (offline cache)
- **shared_preferences**: Latest — Simple persistent prefs (authentication tokens)

### Notifications
- **onesignal_flutter**: 5.5+ — Push notifications
- **flutter_local_notifications**: Latest — Local notification display

### Monetization (Mobile-only)
- **google_mobile_ads**: Latest — AdMob integration

### UI Components
- **flutter_spinkit**: — Loading spinners
- **intl**: — Internationalization (date/time formatting)

### Code Generation
- **freezed**: — Data class generation (models)
- **json_serializable**: — JSON serialization (models)

### Testing (Development Only)
- **flutter_test**: — Unit/widget tests
- **mockito**: — Test mocking

---

## Backend Dependencies (Java/Spring Boot)

### Core Spring Ecosystem
- **spring-boot-starter-web**: 3.5.14 — REST API support
- **spring-boot-starter-data-jpa**: 3.5.14 — ORM/Hibernate integration
- **spring-boot-starter-security**: 6.5.10 — Spring Security
- **spring-boot-starter-validation**: 3.5.14 — Bean validation (JSR-380)
- **spring-boot-actuator**: 3.5.14 — Health checks, metrics

### Database & ORM
- **postgresql**: 42.7.11 — PostgreSQL JDBC driver
- **hibernate-core**: 6.6.49.Final — JPA implementation

### Authentication & Security
- **jjwt** (JSON Web Token):
  - jjwt-api: 0.12.6
  - jjwt-impl: 0.12.6
  - jjwt-jackson: 0.12.6
- **spring-security-core**: 6.5.10
- **spring-security-config**: 6.5.10
- **spring-security-web**: 6.5.10

### Rate Limiting
- **bucket4j-core**: 8.10.1 — Token bucket rate limiting
- **caffeine**: 3.1.8 — Cache implementation (bucket4j backend)

### File Upload & Storage
- **minio**: 8.6.0 — S3-compatible object storage client
- **commons-io**: 2.20.0 — File utilities
- **commons-compress**: 1.28.0 — Archive utilities

### HTTP & Serialization
- **okhttp3**: 4.12.0 — HTTP client (MinIO dependency)
- **jackson**:
  - jackson-core: 2.21.2
  - jackson-databind: 2.21.2
  - jackson-datatype-jsr310: 2.21.2 (Java 8 date/time)
  - jackson-datatype-jdk8: 2.21.2

### Email Support
- **spring-boot-starter-mail**: 3.5.14 (if enabled)
- **jakarta.mail**: 2.0.5

### Logging
- **logback-classic**: 1.5.32 — Logging implementation
- **slf4j-api**: 2.0.17 — Logging facade

### Build Tool
- **Apache Maven**: 3.9.14+ (wrapper: `.mvnw`)

---

## Deployment Infrastructure

| Component | Runtime | Hosting | Purpose |
|-----------|---------|---------|---------|
| **Spring Boot API** | JVM (Java 17) | macOS Mac mini (LaunchAgent) | Backend service (port 8080) |
| **Flutter Web** | JavaScript/WASM (via Dart compiler) | macOS Mac mini (LaunchAgent) | Web admin dashboard |
| **PostgreSQL** | Native (C) | macOS Mac mini | Database server (localhost:5432) |
| **MinIO** | Go binary | macOS Mac mini | Object storage (localhost:9000) |
| **n8n** | Node.js | macOS Mac mini (root daemon) | Automation workflows (port 5678) |

**Access**: SSH + Tailscale VPN (100.109.21.59) — no direct internet exposure (except via Cloudflared tunnel)

---

## Frameworks by Concern

### Authentication & Authorization
- **Frontend**: JWT token (Hive storage) + HTTP Bearer header
- **Backend**: Spring Security + JJWT (JWT generation/validation)

### State Management
- **Frontend**: Provider (reactive data flow)
- **Backend**: Spring Context (dependency injection)

### API Communication
- **Frontend**: Dio HTTP client (REST)
- **Backend**: Spring Web (REST controllers)
- **Contract**: JSON (Jackson serialization)

### Database Abstraction
- **Backend**: JPA/Hibernate ORM (JDBC driver: PostgreSQL)

### File Handling
- **Upload**: Multipart HTTP POST (Flutter) → Spring MultipartFile
- **Storage**: MinIO S3-compatible API (backend)
- **Retrieval**: Signed URLs or direct S3 GET (client)

---

## Known Migration Blockers / Technical Debt

1. **OneSignal Dependency** (Push Notifications)
   - Tightly coupled to mobile experience; requires alternative if moving to different backend
   - No equivalent in web (mobile-only feature)

2. **Hive Local Storage** (Client Caching)
   - Dart/Flutter-specific; would require reimplementation if porting to web-only admin panel
   - Currently shared between mobile + web Flutter

3. **MinIO S3 Compatibility**
   - If replacing with cloud storage (AWS S3, Azure Blob), requires endpoint URL + credential updates
   - Backend uses minio-java SDK (compatible with standard S3)

4. **Flutter Full-Stack Approach**
   - Both mobile + web share source code; UI must work for phone (portrait) + desktop (responsive)
   - Diverging UX requirements may require conditional rendering or separate modules (future)

5. **PostgreSQL on Mac mini**
   - No backup/replication strategy evident
   - No failover mechanism
   - **Risk**: Single point of failure for production data

6. **LaunchAgent Deployment**
   - Manual `launchctl` management; no container orchestration
   - Restarts require SSH + manual commands
   - No automated scaling/health recovery

---

## Legacy Code Present (Not Deployed)

| Path | Technology | Status | Recommendation |
|------|-----------|--------|-----------------|
| `package.json` | Node.js + npm | Abandoned | Remove (validate dependencies first) |
| `vite.config.ts` | Vite bundler | Abandoned | Remove with package.json |
| `server/index.ts` | Express.js + TypeScript | Abandoned | Remove (replaced by Flutter Web + LaunchAgent) |
| `node_modules/` | Node.js packages | Orphaned | Remove (re-run npm install only if needed) |
| `dist/` or `.next/` | Built artifacts | Orphaned | Remove (rebuild if needed from source) |

---

## Version Compatibility Matrix

### Known Working Combinations
- Flutter 3.5 + Dart 3.5 + Provider 6.0 + Dio 5.4 → Tested and deployed
- Spring Boot 3.5.14 + Java 17 + PostgreSQL 14 + Hibernate 6.6 → Production
- MinIO 8.6.0 + minio-java 8.6.0 → Tested for photo uploads

### No Major Version Mismatches Detected
- All dependencies are close to latest stable (as of 2024-2025)
- No EOL or unsupported versions in active use

---

## Security Notes

### Secrets Storage
- MinIO credentials: `application.properties` (backend)
- JWT signing key: `application.properties` (backend)
- API endpoints: Hardcoded or environment-based (frontend)

**Action Item**: Consider migrating to external secret management (AWS Secrets Manager, Azure Key Vault, HashiCorp Vault) for production.

### HTTPS/TLS
- Cloudflared tunnel provides TLS termination for external access
- Internal Tailscale traffic is encrypted by default
- Backend API (internal port 8080) is NOT exposed over HTTPS directly

---

## Monitoring & Observability

| Component | Method | Status |
|-----------|--------|--------|
| **Backend Health** | Spring Actuator (`/actuator/health`) | Likely enabled |
| **Application Logs** | Logback to stdout/files | Configured in Spring |
| **Metrics** | Micrometer (Spring Boot Actuator) | Available but integration unclear |
| **Error Tracking** | (None detected in pom.xml) | Not implemented (consider Sentry/DataDog) |
| **APM/Tracing** | (None detected) | Not implemented |

