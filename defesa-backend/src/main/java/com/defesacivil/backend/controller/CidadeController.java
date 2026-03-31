package com.defesacivil.backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;

@RestController
@RequestMapping("/api/cidades")
public class CidadeController {

    /**
     * Retorna a lista de cidades suportadas pelo sistema.
     * Usar uma lista fixa evita erros de digitação e problemas de visibilidade.
     */
    @GetMapping
    public List<CidadeDTO> listarCidades() {
        return Arrays.asList(
            new CidadeDTO("ATI", "Atibaia"),
            new CidadeDTO("BP", "Bragança Paulista"),
            new CidadeDTO("JOA", "Joanópolis"),
            new CidadeDTO("NAZ", "Nazaré Paulista"),
            new CidadeDTO("PIR", "Piracaia"),
            new CidadeDTO("TUI", "Tuiuti"),
            new CidadeDTO("VAR", "Vargem")
        );
    }

    public static class CidadeDTO {
        private String codigo;
        private String nome;

        public CidadeDTO(String codigo, String nome) {
            this.codigo = codigo;
            this.nome = nome;
        }

        public String getCodigo() { return codigo; }
        public String getNome() { return nome; }
    }
}
