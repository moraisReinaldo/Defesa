package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Ocorrencia;
import com.defesacivil.backend.dto.OcorrenciaRequest;
import com.defesacivil.backend.service.OcorrenciaService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller de Ocorrências.
 *
 * SEGURANÇA: Nenhum endpoint aceita userId via parâmetro ou header externo.
 * A identidade do usuário é sempre extraída do JWT no SecurityContext,
 * tornando impossível a impersonação.
 */
@RestController
@RequestMapping("/api/ocorrencias")
public class OcorrenciaController {

    private final OcorrenciaService ocorrenciaService;

    public OcorrenciaController(OcorrenciaService ocorrenciaService) {
        this.ocorrenciaService = ocorrenciaService;
    }

    @PostMapping
    public ResponseEntity<Ocorrencia> criar(@Valid @RequestBody OcorrenciaRequest request) {
        Ocorrencia salva = ocorrenciaService.registrarOcorrencia(request);
        return ResponseEntity.ok(salva);
    }

    @GetMapping
    public ResponseEntity<Page<Ocorrencia>> listarHistorico(
            @RequestParam(required = false) String cidade,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Pageable pageable = PageRequest.of(page, size, Sort.by("dataHora").descending());
        return ResponseEntity.ok(ocorrenciaService.buscarPorCidade(cidade, pageable));
    }

    /** Aprovar — apenas ADMINISTRADOR (protegido no SecurityConfig) */
    @PostMapping("/{id}/aprovar")
    public ResponseEntity<Ocorrencia> aprovar(@PathVariable String id) {
        Ocorrencia aprovada = ocorrenciaService.aprovarOcorrencia(id);
        return aprovada != null ? ResponseEntity.ok(aprovada) : ResponseEntity.notFound().build();
    }

    /** Registrar chegada de agente — apenas AGENTE ou ADMINISTRADOR */
    @PostMapping("/{id}/chegada")
    public ResponseEntity<Ocorrencia> registrarChegada(
            @PathVariable String id,
            @RequestBody(required = false) java.util.Map<String, String> body) {
        String parecer = (body != null) ? body.get("parecer") : null;
        Ocorrencia atualizada = ocorrenciaService.registrarChegadaAgente(id, parecer);
        return atualizada != null ? ResponseEntity.ok(atualizada) : ResponseEntity.notFound().build();
    }

    /** Resolver ocorrência — apenas AGENTE ou ADMINISTRADOR */
    @PostMapping("/{id}/resolver")
    public ResponseEntity<Ocorrencia> resolver(
            @PathVariable String id,
            @RequestBody(required = false) java.util.Map<String, String> body) {
        String parecer = (body != null) ? body.get("parecer") : null;
        Ocorrencia atualizada = ocorrenciaService.resolverOcorrencia(id, parecer);
        return atualizada != null ? ResponseEntity.ok(atualizada) : ResponseEntity.notFound().build();
    }

    /** Reativar ocorrência resolvida — apenas AGENTE ou ADMINISTRADOR */
    @PostMapping("/{id}/reativar")
    public ResponseEntity<Ocorrencia> reativar(@PathVariable String id) {
        Ocorrencia atualizada = ocorrenciaService.reativarOcorrencia(id);
        return atualizada != null ? ResponseEntity.ok(atualizada) : ResponseEntity.notFound().build();
    }

    /** Atualizar campos da ocorrência — autenticado */
    @PatchMapping("/{id}")
    public ResponseEntity<Ocorrencia> atualizar(
            @PathVariable String id,
            @RequestBody OcorrenciaRequest request) {
        Ocorrencia atualizada = ocorrenciaService.atualizarOcorrencia(id, request);
        return atualizada != null ? ResponseEntity.ok(atualizada) : ResponseEntity.notFound().build();
    }

    /** Deletar — apenas ADMINISTRADOR (protegido no SecurityConfig) */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable String id) {
        boolean deletado = ocorrenciaService.deletarOcorrencia(id);
        return deletado ? ResponseEntity.ok().<Void>build() : ResponseEntity.notFound().build();
    }
}
