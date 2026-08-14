package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Alerta;
import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.dto.AlertaRequest;
import com.defesacivil.backend.repository.AlertaRepository;
import com.defesacivil.backend.repository.CidadeRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AlertaService {

    private final AlertaRepository alertaRepository;
    private final CidadeRepository cidadeRepository;

    public AlertaService(AlertaRepository alertaRepository, CidadeRepository cidadeRepository) {
        this.alertaRepository = alertaRepository;
        this.cidadeRepository = cidadeRepository;
    }

    private String normalizarCodigoCidade(String cidade) {
        if (cidade == null || cidade.isBlank()) return null;
        String limpa = cidade.trim().toUpperCase();
        return cidadeRepository.findByCodigoIgnoreCase(limpa)
            .or(() -> cidadeRepository.findByNomeIgnoreCase(limpa))
            .map(Cidade::getCodigo)
            .orElse(limpa);
    }

    public List<Alerta> buscarAlertasAtivos(String cidade) {
        String cidadeNorm = normalizarCodigoCidade(cidade);
        if (cidadeNorm != null && !cidadeNorm.isEmpty()) {
            return alertaRepository.findByCidadeIgnoreCaseAndAtivoTrueOrderByDataCriacaoDesc(cidadeNorm);
        }
        return alertaRepository.findByAtivoTrueOrderByDataCriacaoDesc();
    }

    public Alerta emitirAlerta(AlertaRequest request) {
        Alerta alerta = new Alerta(
            normalizarCodigoCidade(request.getCidade()),
            request.getTitulo(),
            request.getMensagem(),
            request.getNivel()
        );
        return alertaRepository.save(alerta);
    }

    public void cancelarAlerta(String id) {
        alertaRepository.findById(id).ifPresent(alerta -> {
            alertaRepository.delete(alerta);
        });
    }
}

