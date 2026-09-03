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
    private final CidadeService cidadeService;

    public PontoInteresseService(PontoInteresseRepository repository,
                                 UsuarioRepository usuarioRepository,
                                 CidadeService cidadeService) {
        this.repository = repository;
        this.usuarioRepository = usuarioRepository;
        this.cidadeService = cidadeService;
    }

    private String normalizarCodigoCidade(String cidade) {
        return cidadeService.normalizarCodigoCidade(cidade);
    }

    private String obterNomeCidade(String cidade) {
        return cidadeService.obterNomeCidade(cidade);
    }

    public List<PontoInteresse> listarTodos() {
        return repository.findAll();
    }

    public List<PontoInteresse> listarPorCidade(String cidade) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isSuperAdmin = auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));

        // SUPER_ADMIN: sem restrição — vê todos os POIs de todas as cidades
        if (isSuperAdmin) {
            if (cidade != null && !cidade.isBlank()) {
                String codigo = normalizarCodigoCidade(cidade);
                String nome = obterNomeCidade(cidade);
                return repository.findByCidadeFlexible(cidade.trim(), codigo, nome);
            }
            return listarTodos();
        }

        // Resolver cidade do usuário autenticado se não informada (Isolamento Geográfico Estrito)
        if (cidade == null || cidade.trim().isEmpty()) {
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

        // Bloqueio de POIs para municípios fora do Plano PRO Municipal ou Trial ativo
        if (!isSuperAdmin) {
            Optional<Cidade> cidOpt = cidadeService.buscarPorCodigo(codigo);
            if (cidOpt.isPresent() && !cidOpt.get().isRecursoPoiLiberado()) {
                return List.of(); // POIs nem existem no Plano Base e são desativados no Gestão
            }
        }

        return repository.findByCidadeFlexible(cidade.trim(), codigo, nome);
    }

    public PontoInteresse salvar(PontoInteresse ponto) {
        if (ponto.getCidade() != null) {
            String norm = normalizarCodigoCidade(ponto.getCidade());
            ponto.setCidade(norm);
            if (norm != null) {
                Cidade cid = cidadeService.buscarOuCriarCidade(norm);
                ponto.setCidadeEntidade(cid);

                Authentication auth = SecurityContextHolder.getContext().getAuthentication();
                boolean isSuper = auth != null && auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));
                if (!isSuper && !cid.isRecursoPoiLiberado()) {
                    throw new IllegalArgumentException("Pontos de Apoio e Abrigos (POIs) são exclusivos do Plano PRO Municipal.");
                }
            }
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
            String norm = normalizarCodigoCidade(dados.getCidade());
            existente.setCidade(norm);
            if (norm != null) {
                cidadeService.buscarPorCodigo(norm).ifPresent(existente::setCidadeEntidade);
            }
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
