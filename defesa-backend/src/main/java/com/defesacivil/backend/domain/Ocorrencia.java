package com.defesacivil.backend.domain;

import jakarta.persistence.*;
import java.util.List;

@Entity
@Table(name = "ocorrencias")
public class Ocorrencia {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    private String tipo;
    @Column(columnDefinition = "TEXT")
    private String descricao;
    private double latitude;
    private double longitude;
    private String cidade;
    @Column(columnDefinition = "TEXT")
    private String caminhoFoto;
    private String dataHora;
    private String usuarioId;
    private String status; // status de aprovação (armazenado como String)
    private String dataResolucao;
    @Column(columnDefinition = "TEXT")
    private String agentes;
    private boolean criadoPorAgente; // Novo: define se precisa de aprovação
    private boolean agenteNoLocal; // Novo: marcação de chegada
    private String dataChegadaAgente; // Novo: data da chegada
    @Column(columnDefinition = "TEXT")
    private String descricaoSituacao; // Novo: Parecer técnico/situação atual
    private String cobrade; // Código oficial COBRADE (ex: 1.2.3.0.0)
    private String cobradeDescricao; // Descrição oficial do desastre segundo o MDR/S2ID

    // ---- Origem suspeita (GPS do envio vs. ponto reportado) ----
    private Double latitudeEnvio;  // GPS real do cidadão quando enviou
    private Double longitudeEnvio;
    private boolean origemSuspeita; // true se distância > 2km

    // ---- IA (Gemini) ----
    private Double latitudeIa;      // Sugestão calculada pela IA
    private Double longitudeIa;
    private Double confiancaIa;     // Score 0.0 – 1.0
    @Column(columnDefinition = "TEXT")
    private String justificativaIa; // Texto explicativo da IA
    private boolean processadaIa;   // true = resultado já armazenado, não chama Gemini de novo
    private Integer totalRelatosCluster; // Quantos relatos próximos foram agrupados

    @com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cidade_id")
    private Cidade cidadeEntidade;

    @com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "autor_id")
    private Usuario autor;

    @com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "ocorrencia_agentes_atribuidos",
        joinColumns = @JoinColumn(name = "ocorrencia_id"),
        inverseJoinColumns = @JoinColumn(name = "usuario_id")
    )
    private List<Usuario> agentesAtribuidos;

    public Ocorrencia() {
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getTipo() {
        return tipo;
    }

    public void setTipo(String tipo) {
        this.tipo = tipo;
    }

    public String getDescricao() {
        return descricao;
    }

    public void setDescricao(String descricao) {
        this.descricao = descricao;
    }

    public double getLatitude() {
        return latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }

    public String getCidade() {
        return cidade;
    }

    public void setCidade(String cidade) {
        this.cidade = cidade;
    }

    public String getCaminhoFoto() {
        return caminhoFoto;
    }

    public void setCaminhoFoto(String caminhoFoto) {
        this.caminhoFoto = caminhoFoto;
    }

    public String getDataHora() {
        return dataHora;
    }

    public void setDataHora(String dataHora) {
        this.dataHora = dataHora;
    }

    public String getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(String usuarioId) {
        this.usuarioId = usuarioId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getDataResolucao() {
        return dataResolucao;
    }

    public void setDataResolucao(String dataResolucao) {
        this.dataResolucao = dataResolucao;
    }

    public String getAgentes() {
        return agentes;
    }

    public void setAgentes(String agentes) {
        this.agentes = agentes;
    }

    public boolean isCriadoPorAgente() {
        return criadoPorAgente;
    }

    public void setCriadoPorAgente(boolean criadoPorAgente) {
        this.criadoPorAgente = criadoPorAgente;
    }

    public boolean isAgenteNoLocal() {
        return agenteNoLocal;
    }

    public void setAgenteNoLocal(boolean agenteNoLocal) {
        this.agenteNoLocal = agenteNoLocal;
    }

    public String getDataChegadaAgente() {
        return dataChegadaAgente;
    }

    public void setDataChegadaAgente(String dataChegadaAgente) {
        this.dataChegadaAgente = dataChegadaAgente;
    }

    public String getDescricaoSituacao() {
        return descricaoSituacao;
    }

    public void setDescricaoSituacao(String descricaoSituacao) {
        this.descricaoSituacao = descricaoSituacao;
    }

    public Cidade getCidadeEntidade() {
        return cidadeEntidade;
    }

    public void setCidadeEntidade(Cidade cidadeEntidade) {
        this.cidadeEntidade = cidadeEntidade;
    }

    public Usuario getAutor() {
        return autor;
    }

    public void setAutor(Usuario autor) {
        this.autor = autor;
    }

    public List<Usuario> getAgentesAtribuidos() {
        return agentesAtribuidos;
    }

    public void setAgentesAtribuidos(List<Usuario> agentesAtribuidos) {
        this.agentesAtribuidos = agentesAtribuidos;
    }

    public String getCobrade() {
        return cobrade;
    }

    public void setCobrade(String cobrade) {
        this.cobrade = cobrade;
    }

    public String getCobradeDescricao() {
        return cobradeDescricao;
    }

    public void setCobradeDescricao(String cobradeDescricao) {
        this.cobradeDescricao = cobradeDescricao;
    }

    // ---- Origem suspeita ----
    public Double getLatitudeEnvio() { return latitudeEnvio; }
    public void setLatitudeEnvio(Double latitudeEnvio) { this.latitudeEnvio = latitudeEnvio; }
    public Double getLongitudeEnvio() { return longitudeEnvio; }
    public void setLongitudeEnvio(Double longitudeEnvio) { this.longitudeEnvio = longitudeEnvio; }
    public boolean isOrigemSuspeita() { return origemSuspeita; }
    public void setOrigemSuspeita(boolean origemSuspeita) { this.origemSuspeita = origemSuspeita; }

    // ---- IA (Gemini) ----
    public Double getLatitudeIa() { return latitudeIa; }
    public void setLatitudeIa(Double latitudeIa) { this.latitudeIa = latitudeIa; }
    public Double getLongitudeIa() { return longitudeIa; }
    public void setLongitudeIa(Double longitudeIa) { this.longitudeIa = longitudeIa; }
    public Double getConfiancaIa() { return confiancaIa; }
    public void setConfiancaIa(Double confiancaIa) { this.confiancaIa = confiancaIa; }
    public String getJustificativaIa() { return justificativaIa; }
    public void setJustificativaIa(String justificativaIa) { this.justificativaIa = justificativaIa; }
    public boolean isProcessadaIa() { return processadaIa; }
    public void setProcessadaIa(boolean processadaIa) { this.processadaIa = processadaIa; }
    public Integer getTotalRelatosCluster() { return totalRelatosCluster; }
    public void setTotalRelatosCluster(Integer totalRelatosCluster) { this.totalRelatosCluster = totalRelatosCluster; }
}
