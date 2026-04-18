package com.defesacivil.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class OcorrenciaRequest {
    @NotBlank(message = "O tipo da ocorrência é obrigatório")
    private String tipo;
    
    @NotBlank(message = "A descrição é obrigatória")
    private String descricao;
    
    @NotNull(message = "A latitude é obrigatória")
    private Double latitude;
    
    @NotNull(message = "A longitude é obrigatória")
    private Double longitude;
    
    @NotBlank(message = "A cidade é obrigatória")
    private String cidade;

    private String caminhoFoto; // pode ser uma URL ou Base64 (simplificado)
    private String usuarioId;
    private String dataHora;
    private boolean criadoPorAgente;
    private String agentes;
    private String status;

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }
    public String getDescricao() { return descricao; }
    public void setDescricao(String descricao) { this.descricao = descricao; }
    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }
    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }
    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }
    public String getCaminhoFoto() { return caminhoFoto; }
    public void setCaminhoFoto(String caminhoFoto) { this.caminhoFoto = caminhoFoto; }
    public String getUsuarioId() { return usuarioId; }
    public void setUsuarioId(String usuarioId) { this.usuarioId = usuarioId; }
    public String getDataHora() { return dataHora; }
    public void setDataHora(String dataHora) { this.dataHora = dataHora; }
    public boolean isCriadoPorAgente() { return criadoPorAgente; }
    public void setCriadoPorAgente(boolean criadoPorAgente) { this.criadoPorAgente = criadoPorAgente; }
    public String getAgentes() { return agentes; }
    public void setAgentes(String agentes) { this.agentes = agentes; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
