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
    private final CidadeService cidadeService;

    public AlertaService(AlertaRepository alertaRepository, CidadeService cidadeService) {
        this.alertaRepository = alertaRepository;
        this.cidadeService = cidadeService;
    }

    private String normalizarCodigoCidade(String cidade) {
        return cidadeService.normalizarCodigoCidade(cidade);
    }

    private String obterNomeCidade(String cidade) {
        return cidadeService.obterNomeCidade(cidade);
    }

    public List<Alerta> buscarAlertasAtivos(String cidade) {
        if (cidade != null && !cidade.trim().isEmpty()) {
            String codigo = normalizarCodigoCidade(cidade);
            String nome = obterNomeCidade(cidade);
            return alertaRepository.findByCidadeFlexible(cidade.trim(), codigo, nome);
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

