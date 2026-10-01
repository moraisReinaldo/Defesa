package com.defesacivil.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class AlertaRequest {

    @NotBlank(message = "A cidade é obrigatória")
    private String cidade;

    @NotBlank(message = "O título é obrigatório")
    private String titulo;

    @NotBlank(message = "A mensagem é obrigatória")
    private String mensagem;

    @NotBlank(message = "O nível é obrigatório")
    private String nivel; // INFORMATIVO, ATENCAO, CRITICO, EXTREMO

    private String rotaEmergenciaId; // ID da rota de emergência vinculada (obrigatório se nivel == EXTREMO)

    // Getters and Setters
    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }
    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }
    public String getMensagem() { return mensagem; }
    public void setMensagem(String mensagem) { this.mensagem = mensagem; }
    public String getNivel() { return nivel; }
    public void setNivel(String nivel) { this.nivel = nivel; }
    public String getRotaEmergenciaId() { return rotaEmergenciaId; }
    public void setRotaEmergenciaId(String rotaEmergenciaId) { this.rotaEmergenciaId = rotaEmergenciaId; }
}
