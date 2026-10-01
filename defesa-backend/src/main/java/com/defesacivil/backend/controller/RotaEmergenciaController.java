package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.RotaEmergencia;
import com.defesacivil.backend.dto.RotaEmergenciaRequest;
import com.defesacivil.backend.service.RotaEmergenciaService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/rotas-emergencia")
public class RotaEmergenciaController {

    private final RotaEmergenciaService rotaEmergenciaService;

    public RotaEmergenciaController(RotaEmergenciaService rotaEmergenciaService) {
        this.rotaEmergenciaService = rotaEmergenciaService;
    }

    @GetMapping
    public ResponseEntity<List<RotaEmergencia>> listar(
            @RequestParam(required = false) String cidade,
            @RequestParam(defaultValue = "false") boolean apenasAtivas) {
        return ResponseEntity.ok(rotaEmergenciaService.listarPorCidade(cidade, apenasAtivas));
    }

    @GetMapping("/{id}")
    public ResponseEntity<RotaEmergencia> buscarPorId(@PathVariable String id) {
        RotaEmergencia rota = rotaEmergenciaService.buscarPorId(id);
        return rota != null ? ResponseEntity.ok(rota) : ResponseEntity.notFound().build();
    }

    @PostMapping
    public ResponseEntity<RotaEmergencia> criar(@Valid @RequestBody RotaEmergenciaRequest request) {
        RotaEmergencia criada = rotaEmergenciaService.criarRota(request);
        return ResponseEntity.ok(criada);
    }

    @PutMapping("/{id}")
    public ResponseEntity<RotaEmergencia> atualizar(
            @PathVariable String id,
            @Valid @RequestBody RotaEmergenciaRequest request) {
        RotaEmergencia atualizada = rotaEmergenciaService.atualizarRota(id, request);
        return ResponseEntity.ok(atualizada);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<RotaEmergencia> alternarStatus(
            @PathVariable String id,
            @RequestBody Map<String, Boolean> body) {
        boolean ativa = body != null && Boolean.TRUE.equals(body.get("ativa"));
        RotaEmergencia atualizada = rotaEmergenciaService.alternarStatus(id, ativa);
        return ResponseEntity.ok(atualizada);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable String id) {
        rotaEmergenciaService.deletarRota(id);
        return ResponseEntity.noContent().build();
    }
}
