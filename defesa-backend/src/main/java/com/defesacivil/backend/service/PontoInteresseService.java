package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.PontoInteresse;
import com.defesacivil.backend.repository.PontoInteresseRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import com.defesacivil.backend.domain.Usuario;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Optional;

import java.util.List;

@Service
@Transactional
public class PontoInteresseService {

    private final PontoInteresseRepository repository;
    private final UsuarioRepository usuarioRepository;

    public PontoInteresseService(PontoInteresseRepository repository, UsuarioRepository usuarioRepository) {
        this.repository = repository;
        this.usuarioRepository = usuarioRepository;
    }

    private String getAuthenticatedEmail() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return (auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getName())) ? auth.getName() : null;
    }

    private boolean hasRole(String role) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_" + role));
    }

    private String getAdminOrAgentCity() {
        if (hasRole("ADMINISTRADOR") || hasRole("AGENTE")) {
            String email = getAuthenticatedEmail();
            if (email != null) {
                Usuario user = usuarioRepository.findByEmail(email).orElse(null);
                if (user != null) return user.getCidade();
            }
        }
        return null;
    }

    private void checkJurisdiction(String cidadeAlvo) {
        if (cidadeAlvo == null || cidadeAlvo.trim().isEmpty()) return;
        String userCity = getAdminOrAgentCity();
        if (userCity != null && !userCity.trim().isEmpty() && !userCity.equalsIgnoreCase(cidadeAlvo)) {
            throw new SecurityException("Acesso negado: Você só pode gerenciar itens de sua própria cidade.");
        }
    }

    public List<PontoInteresse> listarTodos() {
        return repository.findAll();
    }

    public List<PontoInteresse> listarPorCidade(String cidade) {
        String adminCity = getAdminOrAgentCity();
        String cityToSearch = (adminCity != null && !adminCity.trim().isEmpty()) ? adminCity : cidade;

        if (cityToSearch == null || cityToSearch.isBlank()) {
            if (hasRole("ADMINISTRADOR") || hasRole("AGENTE")) {
                return listarTodos();
            }
            return listarTodos(); // Fallback se ninguém enviou e não é admin
        }
        return repository.findByCidadeIgnoreCase(cityToSearch);
    }

    public PontoInteresse salvar(PontoInteresse ponto) {
        String adminCity = getAdminOrAgentCity();
        if (adminCity != null && !adminCity.trim().isEmpty()) {
            ponto.setCidade(adminCity); // Força a cidade do admin
        } else {
            checkJurisdiction(ponto.getCidade());
        }
        return repository.save(ponto);
    }

    public PontoInteresse atualizar(String id, PontoInteresse dados) {
        PontoInteresse existente = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Ponto de Interesse não encontrado: " + id));
        checkJurisdiction(existente.getCidade());

        existente.setTipo(dados.getTipo());
        existente.setDescricao(dados.getDescricao());
        existente.setLatitude(dados.getLatitude());
        existente.setLongitude(dados.getLongitude());
        
        // Se tentar mudar a cidade e for admin, a checkJurisdiction original passou, 
        // mas devemos validar se a nova cidade também é permitida
        if (dados.getCidade() != null) {
            checkJurisdiction(dados.getCidade());
            existente.setCidade(dados.getCidade());
        }
        return repository.save(existente);
    }

    public void deletar(String id) {
        PontoInteresse existente = repository.findById(id).orElse(null);
        if (existente != null) {
            checkJurisdiction(existente.getCidade());
            repository.deleteById(id);
        }
    }
}
