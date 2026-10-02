# ==============================================================
# Dockerfile — PostgreSQL 15 (Defesa Civil)
# ==============================================================
# Imagem customizada do PostgreSQL com:
#   - Scripts de inicialização automática do banco
#   - Configurações de performance otimizadas para container
#   - Labels OCI para rastreabilidade
# ==============================================================

FROM postgres:15-alpine

# ── Labels OCI ───────────────────────────────────────────────
LABEL org.opencontainers.image.title="Defesa Civil Database" \
      org.opencontainers.image.description="PostgreSQL 15 com schema inicial do sistema Defesa em Foco" \
      org.opencontainers.image.vendor="Defesa Civil" \
      org.opencontainers.image.source="https://github.com/moraisReinaldo/Defesa"

# ── Scripts de inicialização ─────────────────────────────────
# O PostgreSQL executa automaticamente todos os .sql e .sh
# dentro de /docker-entrypoint-initdb.d na primeira inicialização
COPY init/ /docker-entrypoint-initdb.d/

# ── Configuração de performance para container ───────────────
# Sobrescreve parâmetros do postgresql.conf padrão
ENV POSTGRES_INITDB_ARGS="--encoding=UTF-8 --lc-collate=pt_BR.UTF-8 --lc-ctype=pt_BR.UTF-8"

# Porta padrão do PostgreSQL
EXPOSE 5432

# Health check nativo
HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=20s \
    CMD pg_isready -U ${POSTGRES_USER:-defesa_user} -d ${POSTGRES_DB:-defesacivil}
