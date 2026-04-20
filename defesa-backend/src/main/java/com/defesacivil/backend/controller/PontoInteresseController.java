package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.PontoInteresse;
import com.defesacivil.backend.service.PontoInteresseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/marcacoes")
public class PontoInteresseController {

    @Autowired
    private PontoInteresseService service;

    @GetMapping
    public List<PontoInteresse> listar(@RequestParam(required = false) String cidade) {
        return service.listarPorCidade(cidade);
    }

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(PontoInteresseController.class);

    @PostMapping
    public PontoInteresse criar(@jakarta.validation.Valid @RequestBody PontoInteresse ponto) {
        log.info("Recebendo requisição para criar Ponto de Interesse: {}", ponto.getDescricao());
        try {
            PontoInteresse salvo = service.salvar(ponto);
            log.info("Ponto de Interesse salvo com sucesso: ID {}", salvo.getId());
            return salvo;
        } catch (Exception e) {
            log.error("Erro ao salvar Ponto de Interesse: {}", e.getMessage());
            throw e;
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable String id) {
        service.deletar(id);
        return ResponseEntity.noContent().build();
    }
}
