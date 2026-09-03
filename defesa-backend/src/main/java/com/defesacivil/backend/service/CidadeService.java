package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.repository.CidadeRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class CidadeService {

    private final CidadeRepository repository;

    public CidadeService(CidadeRepository repository) {
        this.repository = repository;
    }

    public List<Cidade> listarTodas() {
        return repository.findAll();
    }

    public Optional<Cidade> buscarPorId(String id) {
        return repository.findById(id);
    }
    
    public Optional<Cidade> buscarPorNome(String nome) {
        return repository.findByNomeIgnoreCase(nome);
    }

    public Optional<Cidade> buscarPorCodigo(String codigo) {
        return repository.findByCodigoIgnoreCase(codigo);
    }

    public Cidade salvar(Cidade cidade) {
        return repository.save(cidade);
    }

    public void deletar(String id) {
        repository.deleteById(id);
    }

    public String normalizarCodigoCidade(String cidade) {
        if (cidade == null || cidade.isBlank()) return null;
        String limpa = cidade.trim();
        return repository.findByCodigoIgnoreCase(limpa)
            .or(() -> repository.findByNomeIgnoreCase(limpa))
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

    public String obterNomeCidade(String cidade) {
        if (cidade == null || cidade.isBlank()) return null;
        String limpa = cidade.trim();
        return repository.findByCodigoIgnoreCase(limpa)
            .or(() -> repository.findByNomeIgnoreCase(limpa))
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
}
