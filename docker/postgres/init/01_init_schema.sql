-- ==============================================================
-- 01_init_schema.sql — Schema inicial do banco Defesa Civil
-- ==============================================================
-- Executado automaticamente pelo PostgreSQL na primeira
-- inicialização do container (docker-entrypoint-initdb.d/).
-- ==============================================================

-- Configurações de locale e encoding
SET client_encoding = 'UTF8';

-- Extensões úteis
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- UUIDs nativos
CREATE EXTENSION IF NOT EXISTS "pg_trgm";     -- Busca fuzzy/trigram

-- Configurações de performance para a sessão de init
SET synchronous_commit = 'off';

-- ==============================================================
-- Schema será criado pelo Hibernate/JPA ao iniciar o backend.
-- Este script apenas garante que as extensões estejam prontas.
-- ==============================================================

-- Log de inicialização
DO $$
BEGIN
    RAISE NOTICE '=== Defesa Civil DB: Inicialização concluída ===';
    RAISE NOTICE 'Banco: defesacivil | Extensões: uuid-ossp, pg_trgm';
END $$;
