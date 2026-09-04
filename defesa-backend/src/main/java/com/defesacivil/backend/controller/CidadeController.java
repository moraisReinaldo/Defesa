package com.defesacivil.backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.dto.CidadeRequest;
import com.defesacivil.backend.service.CidadeService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cidades")
public class CidadeController {

    private final CidadeService service;

    public CidadeController(CidadeService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<Cidade>> listarCidades() {
        return ResponseEntity.ok(service.listarTodas());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Cidade> buscarPorId(@PathVariable String id) {
        return service.buscarPorId(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/codigo/{codigo}")
    public ResponseEntity<Cidade> buscarPorCodigo(@PathVariable String codigo) {
        String codigoNorm = service.normalizarCodigoCidade(codigo);
        return service.buscarPorCodigo(codigoNorm)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Cidade> criar(@Valid @RequestBody CidadeRequest request) {
        Cidade cidade = new Cidade();
        cidade.setNome(request.getNome());
        cidade.setCodigo(request.getCodigo());
        return ResponseEntity.ok(service.salvar(cidade));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Cidade> atualizar(@PathVariable String id, @Valid @RequestBody CidadeRequest request) {
        return service.buscarPorId(id).map(existente -> {
            existente.setNome(request.getNome());
            existente.setCodigo(request.getCodigo());
            return ResponseEntity.ok(service.salvar(existente));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable String id) {
        if (service.buscarPorId(id).isPresent()) {
            service.deletar(id);
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
