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
        String limpa = cidade.trim();
        return cidadeRepository.findByCodigoIgnoreCase(limpa)
            .or(() -> cidadeRepository.findByNomeIgnoreCase(limpa))
            .map(Cidade::getCodigo)
            .orElseGet(() -> {
                String upper = limpa.toUpperCase();
                switch (upper) {
                    case "PIRACAIA": return "PIR";
                    case "JOANOPOLIS":
                    case "JOANÓPOLIS": return "JOA";
                    case "ATIBAIA": return "ATI";
                    case "BRAGANÇA PAULISTA":
                    case "BRAGANCA PAULISTA": return "BP";
                    case "NAZARÉ PAULISTA":
                    case "NAZARE PAULISTA": return "NAZ";
                    case "TUIUTI": return "TUI";
                    case "VARGEM": return "VAR";
                    default: return upper;
                }
            });
    }

    private String obterNomeCidade(String cidade) {
        if (cidade == null || cidade.isBlank()) return null;
        String limpa = cidade.trim();
        return cidadeRepository.findByCodigoIgnoreCase(limpa)
            .or(() -> cidadeRepository.findByNomeIgnoreCase(limpa))
            .map(Cidade::getNome)
            .orElseGet(() -> {
                String upper = limpa.toUpperCase();
                switch (upper) {
                    case "PIR": return "Piracaia";
                    case "JOA": return "Joanópolis";
                    case "ATI": return "Atibaia";
                    case "BP": return "Bragança Paulista";
                    case "NAZ": return "Nazaré Paulista";
                    case "TUI": return "Tuiuti";
                    case "VAR": return "Vargem";
                    default: return limpa;
                }
            });
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

