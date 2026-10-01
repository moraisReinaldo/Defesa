package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.domain.RotaEmergencia;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.dto.RotaEmergenciaRequest;
import com.defesacivil.backend.repository.RotaEmergenciaRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class RotaEmergenciaService {

    private final RotaEmergenciaRepository rotaEmergenciaRepository;
    private final CidadeService cidadeService;
    private final UsuarioRepository usuarioRepository;

    public RotaEmergenciaService(RotaEmergenciaRepository rotaEmergenciaRepository,
                                 CidadeService cidadeService,
                                 UsuarioRepository usuarioRepository) {
        this.rotaEmergenciaRepository = rotaEmergenciaRepository;
        this.cidadeService = cidadeService;
        this.usuarioRepository = usuarioRepository;
    }

    private String getAuthenticatedEmail() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return (auth != null && auth.isAuthenticated()) ? auth.getName() : null;
    }

    private boolean hasRole(String role) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_" + role));
    }

    private boolean isSuperAdmin() {
        return hasRole("SUPER_ADMIN");
    }

    private void checkJurisdiction(String cidadeRota) {
        if (cidadeRota == null || cidadeRota.trim().isEmpty()) {
            return;
        }

        if (isSuperAdmin()) {
            return;
        }

        if (hasRole("ADMINISTRADOR") || hasRole("AGENTE")) {
            String email = getAuthenticatedEmail();
            if (email == null) {
                throw new SecurityException("Acesso negado: Usuário não autenticado.");
            }

            Usuario usuario = usuarioRepository.findByEmail(email).orElse(null);
            if (usuario == null || usuario.getCidade() == null || usuario.getCidade().isBlank()) {
                throw new SecurityException("Acesso negado: Usuário sem cidade configurada.");
            }

            String cidUser = cidadeService.normalizarCodigoCidade(usuario.getCidade());
            String cidRota = cidadeService.normalizarCodigoCidade(cidadeRota);
            if (cidUser != null && cidRota != null && !cidUser.equalsIgnoreCase(cidRota)) {
                throw new SecurityException("Acesso negado: Você só pode gerenciar rotas da sua própria cidade.");
            }
        }
    }

    private void validarPlanoCidade(String cidadeCodigo) {
        if (isSuperAdmin()) return;

        Cidade cidade = cidadeService.buscarPorCodigo(cidadeCodigo).orElse(null);
        if (cidade != null && !cidade.isRecursoRotasEmergenciaLiberado()) {
            throw new IllegalStateException(
                "O recurso de Rotas de Emergência requer o plano Gestão Municipal ou PRO Municipal."
            );
        }
    }

    @Transactional(readOnly = true)
    public List<RotaEmergencia> listarPorCidade(String cidade, boolean apenasAtivas) {
        if (cidade != null && !cidade.trim().isEmpty()) {
            String codigo = cidadeService.normalizarCodigoCidade(cidade);
            String nome = cidadeService.obterNomeCidade(cidade);
            if (apenasAtivas) {
                return rotaEmergenciaRepository.findAtivasByCidadeFlexible(cidade.trim(), codigo, nome);
            }
            return rotaEmergenciaRepository.findByCidadeFlexible(cidade.trim(), codigo, nome);
        }
        if (apenasAtivas) {
            return rotaEmergenciaRepository.findByAtivaTrueOrderByDataCriacaoDesc();
        }
        return rotaEmergenciaRepository.findAll();
    }

    @Transactional(readOnly = true)
    public RotaEmergencia buscarPorId(String id) {
        return rotaEmergenciaRepository.findById(id).orElse(null);
    }

    public RotaEmergencia criarRota(RotaEmergenciaRequest request) {
        String cidadeNormalizada = cidadeService.normalizarCodigoCidade(request.getCidade());
        checkJurisdiction(cidadeNormalizada);
        validarPlanoCidade(cidadeNormalizada);

        RotaEmergencia rota = new RotaEmergencia();
        rota.setNome(request.getNome());
        rota.setDescricao(request.getDescricao());
        rota.setCidade(cidadeNormalizada);
        rota.setPontos(request.getPontos());
        rota.setPontosInteresse(request.getPontosInteresse());
        rota.setAtiva(request.getAtiva() != null ? request.getAtiva() : false);
        rota.setAlertaVinculadoId(request.getAlertaVinculadoId());

        cidadeService.buscarPorCodigo(cidadeNormalizada).ifPresent(rota::setCidadeEntidade);

        String email = getAuthenticatedEmail();
        if (email != null) {
            usuarioRepository.findByEmail(email).ifPresent(u -> rota.setCriadoPorId(u.getId()));
        }

        return rotaEmergenciaRepository.save(rota);
    }

    public RotaEmergencia atualizarRota(String id, RotaEmergenciaRequest request) {
        RotaEmergencia rota = rotaEmergenciaRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Rota não encontrada com o ID: " + id));

        checkJurisdiction(rota.getCidade());
        validarPlanoCidade(rota.getCidade());

        if (request.getNome() != null) rota.setNome(request.getNome());
        if (request.getDescricao() != null) rota.setDescricao(request.getDescricao());
        if (request.getPontos() != null) rota.setPontos(request.getPontos());
        if (request.getPontosInteresse() != null) rota.setPontosInteresse(request.getPontosInteresse());
        if (request.getAtiva() != null) rota.setAtiva(request.getAtiva());
        if (request.getAlertaVinculadoId() != null) rota.setAlertaVinculadoId(request.getAlertaVinculadoId());

        rota.setDataAtualizacao(LocalDateTime.now());
        return rotaEmergenciaRepository.save(rota);
    }

    public RotaEmergencia alternarStatus(String id, boolean ativa) {
        RotaEmergencia rota = rotaEmergenciaRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Rota não encontrada com o ID: " + id));

        checkJurisdiction(rota.getCidade());
        if (ativa) {
            validarPlanoCidade(rota.getCidade());
        }

        rota.setAtiva(ativa);
        rota.setDataAtualizacao(LocalDateTime.now());
        return rotaEmergenciaRepository.save(rota);
    }

    public void deletarRota(String id) {
        RotaEmergencia rota = rotaEmergenciaRepository.findById(id).orElse(null);
        if (rota != null) {
            checkJurisdiction(rota.getCidade());
            rotaEmergenciaRepository.delete(rota);
        }
    }
}
