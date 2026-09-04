-- Executar somente apos gerar backup do banco.
-- Preserva usuarios, ocorrencias e historico; reinicia o licenciamento municipal.
BEGIN;

ALTER TABLE pontos_interesse
    ADD COLUMN IF NOT EXISTS disponivel BOOLEAN NOT NULL DEFAULT TRUE;

UPDATE cidades
SET plano = 'BASE_GRATUITO',
    status = 'PENDENTE_APROVACAO',
    trial_inicio = NULL,
    trial_fim = NULL,
    contrato_expiracao = NULL,
    stripe_customer_id = NULL,
    stripe_subscription_id = NULL;

-- O novo ciclo comeca sem equipe privilegiada. O titular sera definido na aprovacao.
UPDATE usuarios
SET role = 'CIDADAO',
    status = 'ATIVO',
    administrador_titular = FALSE
WHERE role IN ('ADMINISTRADOR', 'AGENTE');

-- POIs permanecem armazenados para eventual recontratacao, mas ficam indisponiveis.
UPDATE pontos_interesse
SET disponivel = FALSE;

COMMIT;
