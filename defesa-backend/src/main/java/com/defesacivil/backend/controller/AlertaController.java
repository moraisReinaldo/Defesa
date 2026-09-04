package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Alerta;
import com.defesacivil.backend.dto.AlertaRequest;
import com.defesacivil.backend.service.AlertaService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/alertas")
public class AlertaController {

    private final AlertaService alertaService;

    public AlertaController(AlertaService alertaService) {
        this.alertaService = alertaService;
    }

    @GetMapping
    public ResponseEntity<List<Alerta>> buscarAlertasAtivos(@RequestParam(required = false) String cidade) {
        return ResponseEntity.ok(alertaService.buscarAlertasAtivos(cidade));
    }

    @PostMapping
    public ResponseEntity<Alerta> emitirAlerta(@Valid @RequestBody AlertaRequest request) {
        Alerta salvo = alertaService.emitirAlerta(request);
        return ResponseEntity.ok(salvo);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> cancelarAlerta(@PathVariable String id) {
        alertaService.cancelarAlerta(id);
        return ResponseEntity.noContent().build();
    }
}

