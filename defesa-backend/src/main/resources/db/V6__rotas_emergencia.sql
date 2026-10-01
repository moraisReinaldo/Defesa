-- ============================================================
-- V6: Rotas de Emergência e Vínculo com Alerta EXTREMO
-- ============================================================

CREATE TABLE IF NOT EXISTS rotas_emergencia (
    id VARCHAR(36) PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    cidade VARCHAR(100) NOT NULL,
    pontos TEXT NOT NULL,
    pontos_interesse TEXT,
    ativa BOOLEAN DEFAULT FALSE,
    alerta_vinculado_id VARCHAR(36),
    criado_por_id VARCHAR(36),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_rotas_cidade ON rotas_emergencia(cidade);
CREATE INDEX IF NOT EXISTS idx_rotas_ativa ON rotas_emergencia(ativa);

-- Coluna para vincular a rota de emergência ao alerta (nível EXTREMO)
ALTER TABLE tb_alertas ADD COLUMN IF NOT EXISTS rota_emergencia_id VARCHAR(36);
