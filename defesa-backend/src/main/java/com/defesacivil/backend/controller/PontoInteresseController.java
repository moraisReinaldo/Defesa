package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.PontoInteresse;
import com.defesacivil.backend.service.PontoInteresseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pontos-interesse")
public class PontoInteresseController {

    @Autowired
    private PontoInteresseService service;

    @GetMapping
    public List<PontoInteresse> listar(@RequestParam(required = false) String cidade) {
        return service.listarPorCidade(cidade);
    }

    @PostMapping
    public PontoInteresse criar(@RequestBody PontoInteresse ponto) {
        return service.salvar(ponto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable String id) {
        service.deletar(id);
        return ResponseEntity.noContent().build();
    }
}
