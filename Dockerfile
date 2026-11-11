# ==============================================================
# Dockerfile.flutter — Frontend Flutter Web (Defesa em Foco)
# ==============================================================
# Versão de produção (Mac mini): o Flutter já compilou nativamente
# via update.sh antes deste build. O Docker só serve os arquivos.
#
# Para o seminário (sem Flutter instalado), use:
#   Dockerfile.flutter.swarm  (multi-stage com SDK completo)
#
# Build:
#   flutter build web --release --base-href /
#   docker build -t defesacivil-frontend:latest .
# ==============================================================

FROM nginx:1.25-alpine

# Labels OCI para rastreabilidade
LABEL org.opencontainers.image.title="Defesa Civil Frontend" \
      org.opencontainers.image.description="Flutter Web app do sistema Defesa em Foco" \
      org.opencontainers.image.vendor="Defesa Civil" \
      org.opencontainers.image.source="https://github.com/moraisReinaldo/Defesa"

# Remover HTML padrão e copiar build do Flutter (gerado nativamente)
RUN rm -rf /usr/share/nginx/html/*
COPY build/web /usr/share/nginx/html

# Configuração Nginx para SPA (Single Page Application)
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    server_tokens off;\n\
    gzip on;\n\
    gzip_types text/plain application/javascript text/css application/json;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|wasm|woff2)$ {\n\
        expires 1y;\n\
        add_header Cache-Control "public, immutable";\n\
    }\n\
    location /nginx-health {\n\
        access_log off;\n\
        return 200 "OK";\n\
        add_header Content-Type text/plain;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -qO- http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]

