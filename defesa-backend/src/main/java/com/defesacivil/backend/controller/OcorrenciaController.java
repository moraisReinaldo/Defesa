package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Ocorrencia;
import com.defesacivil.backend.dto.OcorrenciaRequest;
import com.defesacivil.backend.service.OcorrenciaService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ocorrencias")
public class OcorrenciaController {

    @Autowired
    private OcorrenciaService ocorrenciaService;

    @PostMapping
    public ResponseEntity<Ocorrencia> criar(@Valid @RequestBody OcorrenciaRequest request) {
        Ocorrencia salva = ocorrenciaService.registrarOcorrencia(request);
        return ResponseEntity.ok(salva);
    }

    @PostMapping("/{id}/aprovar")
    public ResponseEntity<Ocorrencia> aprovar(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        Ocorrencia aprovada = ocorrenciaService.aprovarOcorrencia(id, userId);
        return aprovada != null ? ResponseEntity.ok(aprovada) : ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/chegada")
    public ResponseEntity<Ocorrencia> registrarChegada(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @RequestBody(required = false) java.util.Map<String, String> body) {
        String parecer = (body != null) ? body.get("parecer") : null;
        Ocorrencia atualizada = ocorrenciaService.registrarChegadaAgente(id, userId, parecer);
        return atualizada != null ? ResponseEntity.ok(atualizada) : ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/resolver")
    public ResponseEntity<Ocorrencia> resolver(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @RequestBody(required = false) java.util.Map<String, String> body) {
        String parecer = (body != null) ? body.get("parecer") : null;
        Ocorrencia atualizada = ocorrenciaService.resolverOcorrencia(id, userId, parecer);
        return atualizada != null ? ResponseEntity.ok(atualizada) : ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/reativar")
    public ResponseEntity<Ocorrencia> reativar(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        Ocorrencia atualizada = ocorrenciaService.reativarOcorrencia(id, userId);
        return atualizada != null ? ResponseEntity.ok(atualizada) : ResponseEntity.notFound().build();
    }

    @PatchMapping("/{id}")
    public ResponseEntity<Ocorrencia> atualizar(
            @PathVariable String id,
            @RequestBody OcorrenciaRequest request) {
        Ocorrencia atualizada = ocorrenciaService.atualizarOcorrencia(id, request);
        return atualizada != null ? ResponseEntity.ok(atualizada) : ResponseEntity.notFound().build();
    }

    @GetMapping
    public ResponseEntity<Page<Ocorrencia>> listarHistorico(
            @RequestParam(required = false) String cidade,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Pageable pageable = PageRequest.of(page, size, Sort.by("dataHora").descending());
        return ResponseEntity.ok(ocorrenciaService.buscarPorCidade(cidade, pageable));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        boolean deletado = ocorrenciaService.deletarOcorrencia(id, userId);
        return deletado ? ResponseEntity.ok().build() : ResponseEntity.notFound().build();
    }
}
