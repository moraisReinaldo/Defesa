# ==============================================================
# Dockerfile — Defesa Civil Backend (Spring Boot)
# ==============================================================
# Multi-stage build: Maven (build) → JRE Alpine (runtime)
# ==============================================================

# ── Stage 1: Build ────────────────────────────────────────────
FROM maven:3.9.9-eclipse-temurin-17-alpine AS build
WORKDIR /app

# Cache de dependências (só re-baixa se pom.xml mudar)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar source e compilar
COPY src ./src
RUN mvn clean package -DskipTests -B

# ── Stage 2: Runtime ──────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine AS runtime
WORKDIR /app

# Labels OCI para metadata da imagem
LABEL org.opencontainers.image.title="Defesa Civil Backend" \
      org.opencontainers.image.description="API REST do sistema Defesa em Foco" \
      org.opencontainers.image.vendor="Defesa Civil" \
      org.opencontainers.image.source="https://github.com/moraisReinaldo/Defesa"

# Instalar curl para health check e criar usuário não-root
RUN apk add --no-cache curl \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup

# Copiar JAR do stage de build
COPY --from=build /app/target/*.jar app.jar

# Ajustar permissões
RUN chown appuser:appgroup app.jar

# Rodar como usuário não-root
USER appuser

# Porta da aplicação
EXPOSE 8080

# Health check nativo do Docker
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:8080/actuator/health || exit 1

# JVM tuning para container:
#   - UseContainerSupport: respeita os limits de CPU/memória do container
#   - MaxRAMPercentage=75: usa até 75% da RAM disponível no container
#   - urandom: evita bloqueio de entropia em containers
ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-Dserver.port=8080", \
    "-jar", "app.jar"]
