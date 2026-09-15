package com.defesacivil.backend.util;

/**
 * Mapeamento e resolucao do protocolo COBRADE
 * (Classificacao e Codificacao Brasileira de Desastres)
 * Estabelecido pelo Ministerio da Integracao e do Desenvolvimento Regional (MDR)
 * e utilizado pelo Sistema Integrado de Informacoes sobre Desastres (S2ID).
 */
public class CobradeUtil {

    public static class CobradeInfo {
        private final String codigo;
        private final String descricao;

        public CobradeInfo(String codigo, String descricao) {
            this.codigo = codigo;
            this.descricao = descricao;
        }

        public String getCodigo() {
            return codigo;
        }

        public String getDescricao() {
            return descricao;
        }
    }

    public static CobradeInfo resolverPorTipo(String tipo) {
        if (tipo == null) {
            return new CobradeInfo("9.9.9.9.9", "Outros Desastres e Ocorrências Locais");
        }

        String t = tipo.trim().toLowerCase();
        switch (t) {
            case "alagamento":
                return new CobradeInfo("1.2.3.0.0", "Alagamentos e Inundações Bruscas");
            case "deslizamento":
                return new CobradeInfo("1.3.2.1.1", "Deslizamentos de Solo e/ou Rocha");
            case "queda_arvore":
                return new CobradeInfo("1.3.1.1.1", "Vendavais / Queda de Árvores por Tempestades");
            case "incendio_vegetacao":
                return new CobradeInfo("1.4.1.1.0", "Incêndio Florestal em Áreas de Vegetação");
            case "colapso_estrutural":
                return new CobradeInfo("2.1.2.0.0", "Colapso de Edificações e Estruturas");
            case "vazamento_perigoso":
                return new CobradeInfo("2.2.2.0.0", "Liberação de Substâncias Perigosas / Produtos Químicos");
            case "tempestade":
                return new CobradeInfo("1.3.2.1.4", "Tempestades Convectivas - Chuvas Intensas / Granizo");
            case "animais_peconhentos":
                return new CobradeInfo("1.4.2.1.0", "Infestações e Incidentes Biológicos / Animais Peçonhentos");
            case "obstrucao_via":
                return new CobradeInfo("2.1.1.0.0", "Interrupção de Vias Públicas e Transporte");
            default:
                return new CobradeInfo("9.9.9.9.9", "Outros Desastres e Ocorrências Locais");
        }
    }
}