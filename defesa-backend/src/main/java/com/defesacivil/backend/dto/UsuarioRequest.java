package com.defesacivil.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class UsuarioRequest {
    
    @NotBlank(message = "O nome é obrigatório")
    private String nome;

    @NotBlank(message = "O e-mail é obrigatório")
    @Email(message = "Formato de e-mail inválido")
    private String email;

    private String telefone;

    @NotBlank(message = "A senha é obrigatória")
    @Size(min = 6, message = "A senha deve ter no mínimo 6 caracteres")
    private String senha;

    private String cidade; // Pode ser nulo para cidadãos em certas telas, mas validado no Service para Admins

    @NotBlank(message = "O perfil (role) é obrigatório")
    private String role; // CIDADAO, AGENTE, ADMINISTRADOR

    private boolean concordaLGPD;

    // Getters and Setters
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
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public boolean isConcordaLGPD() { return concordaLGPD; }
    public void setConcordaLGPD(boolean concordaLGPD) { this.concordaLGPD = concordaLGPD; }
}
