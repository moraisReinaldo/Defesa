package com.defesacivil.backend.dto;


public class OcorrenciaRequest {
    private String tipo;
    private String descricao;
    private double latitude;
    private double longitude;
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
    public double getLatitude() { return latitude; }
    public void setLatitude(double latitude) { this.latitude = latitude; }
    public double getLongitude() { return longitude; }
    public void setLongitude(double longitude) { this.longitude = longitude; }
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
