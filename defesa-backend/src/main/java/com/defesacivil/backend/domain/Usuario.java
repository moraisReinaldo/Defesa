package com.defesacivil.backend.domain;

import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.domain.enums.Status;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.LocalDateTime;

public class Usuario {

    private String id; // Em Firestore costuma ser String
    private String nome;
    private String email;
    private String telefone;
    private String senha;
    private String cidade;
    private String especialidade;
    private Role role;
    private Status status;
    @JsonIgnore
    private LocalDateTime dataCriacao;
    private String fcmToken; // Token para Push (FCM)

    public Usuario() {
        this.dataCriacao = LocalDateTime.now();
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
    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }
    public Status getStatus() { return status; }
    public void setStatus(Status status) { this.status = status; }
    public LocalDateTime getDataCriacao() { return dataCriacao; }
    public void setDataCriacao(LocalDateTime dataCriacao) { this.dataCriacao = dataCriacao; }
    public String getFcmToken() { return fcmToken; }
    public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }
}
