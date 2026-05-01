package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.PontoInteresse;
import com.defesacivil.backend.service.PontoInteresseService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller de Pontos de Interesse (marcações no mapa).
 * POST e DELETE protegidos por ADMINISTRADOR no SecurityConfig.
 * GET é público.
 */
@RestController
@RequestMapping("/api/marcacoes")
public class PontoInteresseController {

    private static final Logger log = LoggerFactory.getLogger(PontoInteresseController.class);

    private final PontoInteresseService service;

    public PontoInteresseController(PontoInteresseService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<PontoInteresse>> listar(
            @RequestParam(required = false) String cidade) {
        return ResponseEntity.ok(service.listarPorCidade(cidade));
    }

    @PostMapping
    public ResponseEntity<PontoInteresse> criar(@Valid @RequestBody PontoInteresse ponto) {
        log.info("Criando Ponto de Interesse: tipo={}, cidade={}", ponto.getTipo(), ponto.getCidade());
        PontoInteresse salvo = service.salvar(ponto);
        log.info("Ponto de Interesse criado com sucesso: id={}", salvo.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(salvo);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable String id) {
        service.deletar(id);
        return ResponseEntity.noContent().build();
    }
}
