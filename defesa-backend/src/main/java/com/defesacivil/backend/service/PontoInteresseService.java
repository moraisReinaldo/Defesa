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
        String limpa = cidade.trim().toUpperCase();
        return cidadeRepository.findByCodigoIgnoreCase(limpa)
            .or(() -> cidadeRepository.findByNomeIgnoreCase(limpa))
            .map(Cidade::getCodigo)
            .orElse(limpa);
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

        String cidadeNorm = normalizarCodigoCidade(cidade);
        if (cidadeNorm == null || cidadeNorm.isBlank()) {
            return listarTodos();
        }
        return repository.findByCidadeIgnoreCase(cidadeNorm);
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
