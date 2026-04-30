package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.AlertaClima;
import com.defesacivil.backend.service.AlertaClimaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/alertas")
public class AlertaClimaController {

    private final AlertaClimaService alertaClimaService;

    public AlertaClimaController(AlertaClimaService alertaClimaService) {
        this.alertaClimaService = alertaClimaService;
    }

    @GetMapping("/ativos/{cidade}")
    public ResponseEntity<List<AlertaClima>> getAlertasAtivos(@PathVariable String cidade) {
        return ResponseEntity.ok(alertaClimaService.getAlertasAtivos(cidade));
    }

    @PostMapping
    public ResponseEntity<AlertaClima> criarAlerta(@RequestBody AlertaClima alerta) {
        return ResponseEntity.ok(alertaClimaService.criarAlerta(alerta));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletarAlerta(@PathVariable String id) {
        alertaClimaService.deletarAlerta(id);
        return ResponseEntity.noContent().build();
    }
}
