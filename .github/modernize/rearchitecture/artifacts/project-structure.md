# Project Structure: Defesa Civil Defense System

## Overview

Defesa Civil is a cross-platform emergency response and civil defense management system with distinct user flows for mobile field operators and administrative web users.

### Functional Domains

#### Domain: User Management & Authentication
- **User Authentication** (mobile + web): JWT-based login/logout, credential validation against Spring Boot backend
- **User Roles**: Civil Defense Agents (field operators), Administrators (web only)
- **User Profile Management**: Edit personal data, preferences (mobile + web)

#### Domain: Incident Reporting (Core Mobile Feature)
- **Incident Creation**: Capture GPS location, attach photos/videos, categorize incident type, add description
- **Incident Tracking**: Real-time synchronization with backend, status tracking
- **Incident History**: View past incidents, filter by date/location/type

#### Domain: Point of Interest Management
- **POI Creation**: Mark critical infrastructure, resources, water sources on map
- **POI Discovery**: Search, filter, display on map with proximity alerts
- **POI Administration**: (Web-only) Bulk upload, category management

#### Domain: Real-time Geolocation & Mapping
- **Live Map Display**: Shows user position, incidents, POIs, heatmaps
- **Geocoding**: Convert GPS coords ↔ address names
- **Push Notifications**: Real-time incident alerts via OneSignal

#### Domain: Administrative Dashboards (Web Only)
- **Incident Management**: View all incidents, assign to agents, track status
- **User Administration**: Create/edit/deactivate agents and admins
- **Reporting & Analytics**: Generate incident reports, statistical dashboards

---

## Architectural Layers

### Frontend Layer (Client-Side)

**Mobile App** (Flutter for Android/iOS)
- **Presentation** (`screens/`) — User-facing pages (login, map, incident form, history)
- **State Management** (`providers/`) — Provider-based state (Usuario, Ocorrencia, PontoInteresse)
- **Services** (`services/`) — Business logic (API calls, local storage, notifications)
- **Models** (`models/`) — Data structures (User, Incident, POI, Alert)
- **Widgets** (`widgets/`) — Reusable UI components

**Web App** (Flutter Web, compiled from same Dart codebase)
- Same source code as mobile, compiled to JS/WASM
- Responsive layout optimized for admin workflows
- Served via LaunchAgent from macOS Mac mini

### Backend Layer

**Spring Boot 3.5.14 (Java 17)** — REST API
- **Controllers** (`controller/`) — HTTP endpoints (Authentication, Incidents, Users, POIs, Cities, Alerts)
- **Services** (`service/`) — Business logic (Incident processing, User management, Photo upload)
- **Repositories** (`repository/`) — Database access layer (JPA/Hibernate)
- **Models** (`model/`) — JPA entities mapping to PostgreSQL
- **Configuration** (`config/`) — Spring Security, CORS, JWT, MinIO integration

### Data Layer

**PostgreSQL 14** — Persistent storage
- Hosted on macOS Mac mini, accessible only via SSH/Tailscale
- Schema: Users, Incidents, POIs, Cities, Alerts, Photos

**MinIO 8.6.0** — Object storage for photos/attachments
- S3-compatible API, stores incident photos
- Credentials: `admin/defesa@2025` (stored in `application.properties`)
- Endpoints: `localhost:9000` (API), `9001` (console)

---

## Technology Stack by Layer

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile** | Flutter 3.5+, Dart | Cross-platform app for field operators (Android/iOS) |
| **Web** | Flutter Web (Dart→JS) | Admin dashboard, compiled from same codebase as mobile |
| **Backend** | Spring Boot 3.5.14 (Java 17) | REST API, business logic |
| **Database** | PostgreSQL 14 | Relational persistence |
| **Storage** | MinIO 8.6.0 | Photo/attachment storage (S3-compatible) |
| **State Mgmt** | Provider 6.0+ | Client-side state (mobile + web) |
| **HTTP Client** | Dio 5.4, http 1.6 | API communication |
| **Auth** | JJWT 0.12.6 | JWT token generation + validation |
| **Geo** | flutter_map, geolocator, geocoding | Maps, GPS, address lookup |
| **Notifications** | OneSignal 5.5+ | Push notifications (mobile) |
| **Local Storage** | Hive 2.2+, SharedPreferences | Client-side persistent cache |
| **Deployment** | LaunchAgents (macOS) | Process management for backend + web |

---

## Deployment Model

### Current Production Setup

**Infrastructure**: macOS Mac mini (personal) + SSH/Tailscale VPN access only

```
┌─────────────────────────────────────────────────────┐
│ macOS Mac mini (100.109.21.59 via Tailscale)        │
├─────────────────────────────────────────────────────┤
│ Spring Boot (port 8080)                             │
│ ├─ LaunchAgent: com.defesacivil.spring.plist        │
│ ├─ Process: ./mvnw spring-boot:run                  │
│ └─ DB: localhost:5432 (PostgreSQL 14)               │
├─────────────────────────────────────────────────────┤
│ Flutter Web (port 3000 or 8000)                     │
│ ├─ LaunchAgent: com.defesacivil.web.plist           │
│ ├─ Build: flutter build web --release               │
│ └─ Served: build/web/ + cache busting               │
├─────────────────────────────────────────────────────┤
│ MinIO (port 9000/9001)                              │
│ └─ Storage: ~/minio-data                            │
├─────────────────────────────────────────────────────┤
│ n8n Automation (port 5678, daemon)                  │
│ └─ Workflows for incident notifications             │
└─────────────────────────────────────────────────────┘

Mobile Apps (distributed):
├─ Android via Google Play
└─ iOS via Apple App Store
  └─ Both communicate with backend via REST API (8080)
```

### Deployment Scripts

User maintains deployment automation via shell commands (documented in prior conversation):

```bash
# Backend update + restart
cd ~/Defesa && git stash && git pull
cd defesa-backend && ./mvnw clean install -DskipTests
launchctl unload ~/Library/LaunchAgents/com.defesacivil.spring.plist
launchctl load ~/Library/LaunchAgents/com.defesacivil.spring.plist

# Web build + cache busting + restart
cd ~/Defesa && flutter clean && flutter build web --release
cd build/web && sed -i '' "s/main.dart.js/main.dart.js?v=$TS/g" flutter_bootstrap.js
launchctl unload ~/Library/LaunchAgents/com.defesacivil.web.plist
launchctl load ~/Library/LaunchAgents/com.defesacivil.web.plist
```

---

## Legacy/Abandoned Code

The repository contains **obsolete code that is NOT deployed**:

- `package.json`, `vite.config.ts` — Node.js + Vite setup (appears to be remnant from React prototype)
- `server/index.ts` — Express.js server (replaced by Flutter Web build + LaunchAgent)
- Build artifacts: `node_modules/`, `dist/`, `.next/` (if present)

**Recommendation**: Audit for runtime dependencies before deletion. These files are not used in production.

---

## User Experience Differentiation

### Mobile App (Field Operator, General Public)
- **Primary Use Case**: Report incidents from field with real-time GPS, photos
- **Key Workflows**:
  1. Login → Authentication
  2. View live map with incidents/POIs
  3. Create new incident (location, category, photos)
  4. Track incident status in real-time
  5. Push notifications for nearby alerts
- **Design**: Portrait-only, touch-optimized, minimal bandwidth

### Web App (Administrator)
- **Primary Use Case**: Manage incidents, users, resources
- **Key Workflows**:
  1. Login → Authentication (admin role)
  2. Dashboard with incident overview
  3. Assign incidents to agents
  4. Manage users (create, deactivate, permissions)
  5. Generate reports, view analytics
- **Design**: Responsive, keyboard+mouse optimized, detailed dashboards

---

## Open Questions for Validation

1. **n8n Workflows**: Which automations are active? (notifications, webhooks, integrations)
2. **Cloudflared Status**: Tunnel is in error state — is this intentional or misconfiguration?
3. **Python HTTP Server (Port 8085)**: Purpose unclear — serving static files, caching proxy, or dev utility?
4. **Legacy Code Safety**: Are `server/`, `package.json`, `vite.config.ts` referenced by any CI/CD or deployment scripts?

