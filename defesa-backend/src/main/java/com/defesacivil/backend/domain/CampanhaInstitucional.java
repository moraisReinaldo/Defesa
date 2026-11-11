package com.defesacivil.backend.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "tb_campanhas_institucionais")
public class CampanhaInstitucional {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(nullable = false)
    private String titulo;

    @Column(columnDefinition = "TEXT")
    private String descricao;

    private String orgaoResponsavel; // Ex: "Defesa Civil", "Secretaria de Saúde"
    private String cidade; // Nome da cidade ou "GLOBAL"
    private String tipo; // VACINACAO, DENGUE, CHUVA_FORTE, ABRIGO, INSTITUCIONAL
    private String linkExterno; // Link para mais informações
    private String icone; // Nome do ícone para Flutter (ex: "health_and_safety", "campaign")
    private LocalDateTime dataCriacao;
    private boolean ativo;

    public CampanhaInstitucional() {
        this.dataCriacao = LocalDateTime.now();
        this.ativo = true;
    }

    public CampanhaInstitucional(String titulo, String descricao, String orgaoResponsavel, String cidade, String tipo, String icone) {
        this();
        this.titulo = titulo;
        this.descricao = descricao;
        this.orgaoResponsavel = orgaoResponsavel;
        this.cidade = cidade;
        this.tipo = tipo;
        this.icone = icone;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }

    public String getDescricao() { return descricao; }
    public void setDescricao(String descricao) { this.descricao = descricao; }

    public String getOrgaoResponsavel() { return orgaoResponsavel; }
    public void setOrgaoResponsavel(String orgaoResponsavel) { this.orgaoResponsavel = orgaoResponsavel; }

    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }

    public String getLinkExterno() { return linkExterno; }
    public void setLinkExterno(String linkExterno) { this.linkExterno = linkExterno; }

    public String getIcone() { return icone; }
    public void setIcone(String icone) { this.icone = icone; }

    public LocalDateTime getDataCriacao() { return dataCriacao; }
    public void setDataCriacao(LocalDateTime dataCriacao) { this.dataCriacao = dataCriacao; }

    public boolean isAtivo() { return ativo; }
    public void setAtivo(boolean ativo) { this.ativo = ativo; }
}
