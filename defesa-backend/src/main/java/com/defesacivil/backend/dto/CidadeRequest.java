package com.defesacivil.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class CidadeRequest {

    @NotBlank(message = "O código da cidade é obrigatório")
    private String codigo;

    @NotBlank(message = "O nome da cidade é obrigatório")
    private String nome;

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }
}
