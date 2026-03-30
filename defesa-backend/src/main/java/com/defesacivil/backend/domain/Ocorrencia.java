package com.defesacivil.backend.domain;

import com.defesacivil.backend.domain.enums.OcorrenciaStatus;
import java.time.LocalDateTime;

public class Ocorrencia {

    private String id;
    private String tipo;
    private String descricao;
    private double latitude;
    private double longitude;
    private String cidade;
    private String caminhoFoto;
    private LocalDateTime dataHora;
    private String usuarioId;
    private OcorrenciaStatus status; // Novo: status de aprovação
    private boolean resolvida;
    private LocalDateTime dataResolucao;
    private String agentes;
    private boolean criadoPorAgente; // Novo: define se precisa de aprovação
    private boolean agenteNoLocal; // Novo: marcação de chegada
    private LocalDateTime dataChegadaAgente; // Novo: data da chegada

    public Ocorrencia() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
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
    public LocalDateTime getDataHora() { return dataHora; }
    public void setDataHora(LocalDateTime dataHora) { this.dataHora = dataHora; }
    public String getUsuarioId() { return usuarioId; }
    public void setUsuarioId(String usuarioId) { this.usuarioId = usuarioId; }
    public OcorrenciaStatus getStatus() { return status; }
    public void setStatus(OcorrenciaStatus status) { this.status = status; }
    public boolean isResolvida() { return resolvida; }
    public void setResolvida(boolean resolvida) { this.resolvida = resolvida; }
    public LocalDateTime getDataResolucao() { return dataResolucao; }
    public void setDataResolucao(LocalDateTime dataResolucao) { this.dataResolucao = dataResolucao; }
    public String getAgentes() { return agentes; }
    public void setAgentes(String agentes) { this.agentes = agentes; }
    public boolean isCriadoPorAgente() { return criadoPorAgente; }
    public void setCriadoPorAgente(boolean criadoPorAgente) { this.criadoPorAgente = criadoPorAgente; }
    public boolean isAgenteNoLocal() { return agenteNoLocal; }
    public void setAgenteNoLocal(boolean agenteNoLocal) { this.agenteNoLocal = agenteNoLocal; }
    public LocalDateTime getDataChegadaAgente() { return dataChegadaAgente; }
    public void setDataChegadaAgente(LocalDateTime dataChegadaAgente) { this.dataChegadaAgente = dataChegadaAgente; }
}
