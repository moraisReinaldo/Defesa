package com.defesacivil.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class RotaEmergenciaRequest {

    @NotBlank(message = "O nome da rota é obrigatório")
    private String nome;

    private String descricao;

    @NotBlank(message = "A cidade é obrigatória")
    private String cidade;

    @NotBlank(message = "Os pontos da rota são obrigatórios")
    private String pontos;

    private String pontosInteresse;

    private Boolean ativa;

    private String alertaVinculadoId;

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getDescricao() { return descricao; }
    public void setDescricao(String descricao) { this.descricao = descricao; }

    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }

    public String getPontos() { return pontos; }
    public void setPontos(String pontos) { this.pontos = pontos; }

    public String getPontosInteresse() { return pontosInteresse; }
    public void setPontosInteresse(String pontosInteresse) { this.pontosInteresse = pontosInteresse; }

    public Boolean getAtiva() { return ativa; }
    public void setAtiva(Boolean ativa) { this.ativa = ativa; }

    public String getAlertaVinculadoId() { return alertaVinculadoId; }
    public void setAlertaVinculadoId(String alertaVinculadoId) { this.alertaVinculadoId = alertaVinculadoId; }
}
