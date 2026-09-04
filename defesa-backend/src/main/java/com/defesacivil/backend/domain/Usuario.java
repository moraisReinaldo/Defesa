package com.defesacivil.backend.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

import jakarta.persistence.ManyToOne;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.FetchType;

@Entity
@Table(name = "usuarios")
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    private String nome;
    @Column(unique = true, nullable = false)
    private String email;
    private String telefone;
    @JsonIgnore
    private String senha;
    private String cidade;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cidade_id")
    private Cidade cidadeEntidade;

    private String especialidade;
    private String role;
    private String status;
    private Boolean administradorTitular = false;
    @JsonIgnore
    private String dataCriacao;
    @JsonIgnore
    private String fcmToken; // Token para Push (FCM) — nunca expor na API
    @JsonIgnore
    private String resetSenhaCodigo;
    @JsonIgnore
    private LocalDateTime resetSenhaExpiracao;
    @JsonIgnore
    private Integer resetSenhaTentativas = 0;

    public Usuario() {
        this.dataCriacao = LocalDateTime.now().toString();
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getTelefone() {
        return telefone;
    }

    public void setTelefone(String telefone) {
        this.telefone = telefone;
    }

    public String getSenha() {
        return senha;
    }

    public void setSenha(String senha) {
        this.senha = senha;
    }

    public String getCidade() {
        return cidade;
    }

    public void setCidade(String cidade) {
        this.cidade = cidade;
    }

    public String getEspecialidade() {
        return especialidade;
    }

    public void setEspecialidade(String especialidade) {
        this.especialidade = especialidade;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Boolean getAdministradorTitular() {
        return administradorTitular != null && administradorTitular;
    }

    public void setAdministradorTitular(Boolean administradorTitular) {
        this.administradorTitular = administradorTitular;
    }

    public String getDataCriacao() {
        return dataCriacao;
    }

    public void setDataCriacao(String dataCriacao) {
        this.dataCriacao = dataCriacao;
    }

    public String getFcmToken() {
        return fcmToken;
    }

    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }

    public String getResetSenhaCodigo() {
        return resetSenhaCodigo;
    }

    public void setResetSenhaCodigo(String resetSenhaCodigo) {
        this.resetSenhaCodigo = resetSenhaCodigo;
    }

    public LocalDateTime getResetSenhaExpiracao() {
        return resetSenhaExpiracao;
    }

    public void setResetSenhaExpiracao(LocalDateTime resetSenhaExpiracao) {
        this.resetSenhaExpiracao = resetSenhaExpiracao;
    }

    public Cidade getCidadeEntidade() {
        return cidadeEntidade;
    }

    public void setCidadeEntidade(Cidade cidadeEntidade) {
        this.cidadeEntidade = cidadeEntidade;
    }

    public Integer getResetSenhaTentativas() {
        return resetSenhaTentativas != null ? resetSenhaTentativas : 0;
    }

    public void setResetSenhaTentativas(Integer resetSenhaTentativas) {
        this.resetSenhaTentativas = resetSenhaTentativas;
    }

    private Boolean semAnunciosVitalicio = false;

    public Boolean getSemAnunciosVitalicio() {
        return semAnunciosVitalicio != null ? semAnunciosVitalicio : false;
    }

    public void setSemAnunciosVitalicio(Boolean semAnunciosVitalicio) {
        this.semAnunciosVitalicio = semAnunciosVitalicio;
    }
}
