package com.defesacivil.backend.domain;

import com.defesacivil.backend.domain.enums.OcorrenciaStatus;
import com.defesacivil.backend.util.CobradeUtil;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Testes de Unidade da Camada de Domínio (Entidade Ocorrencia, Enums e Protocolo COBRADE).
 */
class OcorrenciaTest {

    @Test
    @DisplayName("Domínio: Deve instanciar e manipular todos os atributos e relacionamentos da entidade Ocorrencia")
    void deveManipularAtributosDaEntidadeOcorrencia() {
        Ocorrencia oc = new Ocorrencia();
        oc.setId("uuid-001");
        oc.setTipo("alagamento");
        oc.setDescricao("Alagamento próximo à ponte");
        oc.setLatitude(-22.9301);
        oc.setLongitude(-46.2701);
        oc.setLatitudeEnvio(-22.9302);
        oc.setLongitudeEnvio(-46.2702);
        oc.setOrigemSuspeita(false);
        oc.setCidade("joanopolis");
        oc.setStatus(OcorrenciaStatus.PENDENTE_APROVACAO.name());
        oc.setCriadoPorAgente(false);
        oc.setAgenteNoLocal(true);
        oc.setDataChegadaAgente("2026-11-10T14:00:00");
        oc.setDataResolucao("2026-11-10T16:00:00");
        oc.setDescricaoSituacao("Situação normalizada");
        oc.setLatitudeIa(-22.93015);
        oc.setLongitudeIa(-46.27015);
        oc.setConfiancaIa(0.95);
        oc.setJustificativaIa("Confirmado por imagem");
        oc.setProcessadaIa(true);
        oc.setTotalRelatosCluster(4);

        Cidade cidade = new Cidade();
        cidade.setNome("Joanópolis");
        oc.setCidadeEntidade(cidade);

        Usuario autor = new Usuario();
        autor.setId("user-01");
        oc.setAutor(autor);
        oc.setAgentesAtribuidos(List.of(autor));

        assertEquals("uuid-001", oc.getId());
        assertEquals("alagamento", oc.getTipo());
        assertEquals(-22.9301, oc.getLatitude());
        assertEquals(-46.2701, oc.getLongitude());
        assertFalse(oc.isOrigemSuspeita());
        assertTrue(oc.isAgenteNoLocal());
        assertTrue(oc.isProcessadaIa());
        assertEquals(0.95, oc.getConfiancaIa());
        assertEquals(4, oc.getTotalRelatosCluster());
        assertEquals("Joanópolis", oc.getCidadeEntidade().getNome());
        assertEquals(1, oc.getAgentesAtribuidos().size());
    }

    @Test
    @DisplayName("RN04 (COBRADE): Deve mapear corretamente todas as naturezas de desastre para o código oficial MDR/S2ID")
    void deveResolverCodigosCobradeCorretamente() {
        assertEquals("1.2.3.0.0", CobradeUtil.resolverPorTipo("alagamento").getCodigo());
        assertEquals("1.3.2.1.1", CobradeUtil.resolverPorTipo("deslizamento").getCodigo());
        assertEquals("1.3.1.1.1", CobradeUtil.resolverPorTipo("queda_arvore").getCodigo());
        assertEquals("1.4.1.1.0", CobradeUtil.resolverPorTipo("incendio_vegetacao").getCodigo());
        assertEquals("2.1.2.0.0", CobradeUtil.resolverPorTipo("colapso_estrutural").getCodigo());
        assertEquals("2.2.2.0.0", CobradeUtil.resolverPorTipo("vazamento_perigoso").getCodigo());
        assertEquals("1.3.2.1.4", CobradeUtil.resolverPorTipo("tempestade").getCodigo());
        assertEquals("1.4.2.1.0", CobradeUtil.resolverPorTipo("animais_peconhentos").getCodigo());
        assertEquals("2.1.1.0.0", CobradeUtil.resolverPorTipo("obstrucao_via").getCodigo());
        assertEquals("9.9.9.9.9", CobradeUtil.resolverPorTipo("outro_qualquer").getCodigo());
        assertEquals("9.9.9.9.9", CobradeUtil.resolverPorTipo(null).getCodigo());
    }
}
