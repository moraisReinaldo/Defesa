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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cidade_id")
    private Cidade cidadeEntidade;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "autor_id")
    private Usuario autor;

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
}
