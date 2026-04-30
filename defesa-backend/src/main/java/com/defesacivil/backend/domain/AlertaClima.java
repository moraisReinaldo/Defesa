package com.defesacivil.backend.domain;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "alertas_clima")
public class AlertaClima {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @jakarta.persistence.Column(name = "mensagem", columnDefinition = "TEXT", nullable = false)
    private String mensagem;

    @jakarta.persistence.Column(name = "gravidade", nullable = false)
    private String gravidade; // BAIXA, MEDIA, ALTA, EXTREMA

    @jakarta.persistence.Column(name = "cidade", nullable = false)
    private String cidade;

    @jakarta.persistence.Column(name = "data_criacao")
    private LocalDateTime dataCriacao = LocalDateTime.now();

    @jakarta.persistence.Column(name = "data_expiracao", nullable = false)
    private LocalDateTime dataExpiracao;

    @jakarta.persistence.Column(name = "criado_por")
    private String criadoPor;

    public AlertaClima() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getMensagem() { return mensagem; }
    public void setMensagem(String mensagem) { this.mensagem = mensagem; }
    public String getGravidade() { return gravidade; }
    public void setGravidade(String gravidade) { this.gravidade = gravidade; }
    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }
    public LocalDateTime getDataCriacao() { return dataCriacao; }
    public void setDataCriacao(LocalDateTime dataCriacao) { this.dataCriacao = dataCriacao; }
    public LocalDateTime getDataExpiracao() { return dataExpiracao; }
    public void setDataExpiracao(LocalDateTime dataExpiracao) { this.dataExpiracao = dataExpiracao; }
    public String getCriadoPor() { return criadoPor; }
    public void setCriadoPor(String criadoPor) { this.criadoPor = criadoPor; }
}
