package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Alerta;
import com.defesacivil.backend.repository.AlertaRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AlertaService {

    private final AlertaRepository alertaRepository;

    public AlertaService(AlertaRepository alertaRepository) {
        this.alertaRepository = alertaRepository;
    }

    public List<Alerta> buscarAlertasAtivos(String cidade) {
        if (cidade != null && !cidade.trim().isEmpty()) {
            return alertaRepository.findByCidadeAndAtivoTrueOrderByDataCriacaoDesc(cidade.trim());
        }
        return alertaRepository.findByAtivoTrueOrderByDataCriacaoDesc();
    }

    public Alerta emitirAlerta(Alerta alerta) {
        if (alerta.getId() == null || alerta.getId().trim().isEmpty()) {
            alerta.setId(java.util.UUID.randomUUID().toString());
        }
        if (alerta.getDataCriacao() == null) {
            alerta.setDataCriacao(java.time.LocalDateTime.now());
        }
        alerta.setAtivo(true);
        return alertaRepository.save(alerta);
    }

    public void cancelarAlerta(String id) {
        alertaRepository.findById(id).ifPresent(alerta -> {
            alerta.setAtivo(false);
            alertaRepository.save(alerta);
        });
    }
}
