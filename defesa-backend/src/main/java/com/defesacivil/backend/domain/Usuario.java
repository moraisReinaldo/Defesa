package com.defesacivil.backend.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "usuarios")
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    private String nome;
    private String email;
    private String telefone;
    @JsonIgnore
    private String senha;
    private String cidade;
    private String especialidade;
    private String role;
    private String status;
    @JsonIgnore
    private String dataCriacao;
    private String fcmToken; // Token para Push (FCM)
    @JsonIgnore
    private String resetSenhaCodigo;
    @JsonIgnore
    private LocalDateTime resetSenhaExpiracao;

    public Usuario() {
        this.dataCriacao = LocalDateTime.now().toString();
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getTelefone() { return telefone; }
    public void setTelefone(String telefone) { this.telefone = telefone; }
    public String getSenha() { return senha; }
    public void setSenha(String senha) { this.senha = senha; }
    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }
    public String getEspecialidade() { return especialidade; }
    public void setEspecialidade(String especialidade) { this.especialidade = especialidade; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getDataCriacao() { return dataCriacao; }
    public void setDataCriacao(String dataCriacao) { this.dataCriacao = dataCriacao; }
    public String getFcmToken() { return fcmToken; }
    public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }
    public String getResetSenhaCodigo() { return resetSenhaCodigo; }
    public void setResetSenhaCodigo(String resetSenhaCodigo) { this.resetSenhaCodigo = resetSenhaCodigo; }
    public LocalDateTime getResetSenhaExpiracao() { return resetSenhaExpiracao; }
    public void setResetSenhaExpiracao(LocalDateTime resetSenhaExpiracao) { this.resetSenhaExpiracao = resetSenhaExpiracao; }
}
