package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Ocorrencia;
import com.defesacivil.backend.dto.OcorrenciaRequest;
import com.defesacivil.backend.service.OcorrenciaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/ocorrencias")
public class OcorrenciaController {

    @Autowired
    private OcorrenciaService ocorrenciaService;

    @PostMapping
    public ResponseEntity<?> criar(@RequestBody OcorrenciaRequest request) {
        try {
            Ocorrencia salva = ocorrenciaService.registrarOcorrencia(request);
            return ResponseEntity.ok(salva);
        } catch (SecurityException e) {
            Map<String, String> response = new HashMap<>();
            response.put("message", e.getMessage());
            return ResponseEntity.status(403).body(response);
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "Erro ao processar requisição");
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/{id}/aprovar")
    public ResponseEntity<?> aprovar(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        try {
            Ocorrencia aprovada = ocorrenciaService.aprovarOcorrencia(id, userId);
            return aprovada != null ? ResponseEntity.ok(aprovada) : ResponseEntity.notFound().build();
        } catch (SecurityException e) {
            Map<String, String> response = new HashMap<>();
            response.put("message", e.getMessage());
            return ResponseEntity.status(403).body(response);
        }
    }

    @PostMapping("/{id}/chegada")
    public ResponseEntity<?> registrarChegada(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        try {
            Ocorrencia atualizada = ocorrenciaService.registrarChegadaAgente(id, userId);
            return atualizada != null ? ResponseEntity.ok(atualizada) : ResponseEntity.notFound().build();
        } catch (SecurityException e) {
            Map<String, String> response = new HashMap<>();
            response.put("message", e.getMessage());
            return ResponseEntity.status(403).body(response);
        }
    }

    @GetMapping
    public ResponseEntity<List<Ocorrencia>> listarHistorico(@RequestParam(required = false) String cidade) {
        return ResponseEntity.ok(ocorrenciaService.buscarPorCidade(cidade));
    }
}
