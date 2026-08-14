package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.domain.PontoInteresse;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.repository.CidadeRepository;
import com.defesacivil.backend.repository.PontoInteresseRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class PontoInteresseService {

    private final PontoInteresseRepository repository;
    private final UsuarioRepository usuarioRepository;
    private final CidadeRepository cidadeRepository;

    public PontoInteresseService(PontoInteresseRepository repository,
                                 UsuarioRepository usuarioRepository,
                                 CidadeRepository cidadeRepository) {
        this.repository = repository;
        this.usuarioRepository = usuarioRepository;
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

    public List<PontoInteresse> listarTodos() {
        return repository.findAll();
    }

    public List<PontoInteresse> listarPorCidade(String cidade) {
        // Resolver cidade do usuário autenticado se não informada (Isolamento Geográfico Estrito)
        if (cidade == null || cidade.trim().isEmpty()) {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getName())) {
                String email = auth.getName();
                Optional<Usuario> usuario = usuarioRepository.findByEmail(email);
                if (usuario.isPresent() && usuario.get().getCidade() != null) {
                    cidade = usuario.get().getCidade();
                }
            }
        }

        if (cidade == null || cidade.isBlank()) {
            return listarTodos();
        }

        String codigo = normalizarCodigoCidade(cidade);
        String nome = obterNomeCidade(cidade);
        return repository.findByCidadeFlexible(cidade.trim(), codigo, nome);
    }

    public PontoInteresse salvar(PontoInteresse ponto) {
        if (ponto.getCidade() != null) {
            ponto.setCidade(normalizarCodigoCidade(ponto.getCidade()));
        }
        return repository.save(ponto);
    }

    public PontoInteresse atualizar(String id, PontoInteresse dados) {
        PontoInteresse existente = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Ponto de Interesse não encontrado: " + id));
        existente.setTipo(dados.getTipo());
        existente.setDescricao(dados.getDescricao());
        existente.setLatitude(dados.getLatitude());
        existente.setLongitude(dados.getLongitude());
        if (dados.getCidade() != null) {
            existente.setCidade(normalizarCodigoCidade(dados.getCidade()));
        }
        return repository.save(existente);
    }

    public void deletar(String id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Ponto de Interesse não encontrado: " + id);
        }
        repository.deleteById(id);
    }
}
