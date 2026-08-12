package com.defesacivil.backend.domain;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "tb_alertas")
public class Alerta {

    @Id
    private String id;
    private String cidade;
    private String titulo;
    private String mensagem;
    private String nivel; // INFORMATIVO, ATENCAO, CRITICO
    private LocalDateTime dataCriacao;
    private boolean ativo;

    public Alerta() {
        this.id = UUID.randomUUID().toString();
        this.dataCriacao = LocalDateTime.now();
        this.ativo = true;
    }

    public Alerta(String cidade, String titulo, String mensagem, String nivel) {
        this.id = UUID.randomUUID().toString();
        this.cidade = cidade;
        this.titulo = titulo;
        this.mensagem = mensagem;
        this.nivel = nivel;
        this.dataCriacao = LocalDateTime.now();
        this.ativo = true;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }

    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }

    public String getMensagem() { return mensagem; }
    public void setMensagem(String mensagem) { this.mensagem = mensagem; }

    public String getNivel() { return nivel; }
    public void setNivel(String nivel) { this.nivel = nivel; }

    public LocalDateTime getDataCriacao() { return dataCriacao; }
    public void setDataCriacao(LocalDateTime dataCriacao) { this.dataCriacao = dataCriacao; }

    public boolean isAtivo() { return ativo; }
    public void setAtivo(boolean ativo) { this.ativo = ativo; }
}
