-- RESET TOTAL: executar somente apos confirmar um backup.
-- Remove dados operacionais e preserva apenas o Super Admin informado.
BEGIN;

DELETE FROM tb_alertas;
DELETE FROM ocorrencias;
DELETE FROM pontos_interesse;

UPDATE usuarios
SET cidade = NULL,
    cidade_id = NULL
WHERE lower(trim(email)) = 'reinaldohm07@gmail.com';

DELETE FROM usuarios
WHERE lower(trim(email)) <> 'reinaldohm07@gmail.com'
   OR email IS NULL;

DELETE FROM cidades;

COMMIT;
