package com.defesacivil.backend.domain;

import java.time.LocalDateTime;

public class Comentario {

    private String id;
    private String ocorrenciaId;
    private String texto;
    private String usuarioId;
    private String nomeUsuario;
    private boolean isAgente;
    private LocalDateTime dataHora;

    public Comentario() {
        this.dataHora = LocalDateTime.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getOcorrenciaId() { return ocorrenciaId; }
    public void setOcorrenciaId(String ocorrenciaId) { this.ocorrenciaId = ocorrenciaId; }
    public String getTexto() { return texto; }
    public void setTexto(String texto) { this.texto = texto; }
    public String getUsuarioId() { return usuarioId; }
    public void setUsuarioId(String usuarioId) { this.usuarioId = usuarioId; }
    public String getNomeUsuario() { return nomeUsuario; }
    public void setNomeUsuario(String nomeUsuario) { this.nomeUsuario = nomeUsuario; }
    public boolean isAgente() { return isAgente; }
    public void setAgente(boolean agente) { isAgente = agente; }
    public LocalDateTime getDataHora() { return dataHora; }
    public void setDataHora(LocalDateTime dataHora) { this.dataHora = dataHora; }
}
