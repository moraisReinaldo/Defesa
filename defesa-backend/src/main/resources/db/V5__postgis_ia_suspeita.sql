-- ============================================================
-- V5: PostGIS + Campos de IA + Detecção de Origem Suspeita
-- ============================================================

-- Habilitar extensão PostGIS (necessário apenas uma vez por banco)
CREATE EXTENSION IF NOT EXISTS postgis;

-- ---- Coluna geometry para índice espacial ----
ALTER TABLE ocorrencias ADD COLUMN IF NOT EXISTS geom geometry(Point, 4326);

-- Preencher geometria para registros existentes
UPDATE ocorrencias
SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
WHERE geom IS NULL AND latitude IS NOT NULL AND longitude IS NOT NULL;

-- Índice GIST para consultas de raio (ST_DWithin)
CREATE INDEX IF NOT EXISTS idx_ocorrencias_geom ON ocorrencias USING GIST(geom);

-- ---- Campos de IA (Gemini) ----
ALTER TABLE ocorrencias ADD COLUMN IF NOT EXISTS latitude_ia DOUBLE PRECISION;
ALTER TABLE ocorrencias ADD COLUMN IF NOT EXISTS longitude_ia DOUBLE PRECISION;
ALTER TABLE ocorrencias ADD COLUMN IF NOT EXISTS confianca_ia NUMERIC(4,2);
ALTER TABLE ocorrencias ADD COLUMN IF NOT EXISTS justificativa_ia TEXT;
ALTER TABLE ocorrencias ADD COLUMN IF NOT EXISTS processada_ia BOOLEAN DEFAULT FALSE;
ALTER TABLE ocorrencias ADD COLUMN IF NOT EXISTS total_relatos_cluster INT DEFAULT 1;

-- ---- Campos de origem suspeita ----
-- GPS do cidadão NO MOMENTO do envio (pode diferir da posição reportada)
ALTER TABLE ocorrencias ADD COLUMN IF NOT EXISTS latitude_envio DOUBLE PRECISION;
ALTER TABLE ocorrencias ADD COLUMN IF NOT EXISTS longitude_envio DOUBLE PRECISION;
-- true quando distância entre envio e ponto reportado > 2km
ALTER TABLE ocorrencias ADD COLUMN IF NOT EXISTS origem_suspeita BOOLEAN DEFAULT FALSE;
