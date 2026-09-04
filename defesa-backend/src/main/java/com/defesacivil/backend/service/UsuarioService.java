package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.domain.enums.Status;
import com.defesacivil.backend.dto.UsuarioRequest;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class UsuarioService {

    private static final Logger log = LoggerFactory.getLogger(UsuarioService.class);

    private final UsuarioRepository repository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    // Carregada de variável de ambiente — nunca hardcoded
    @Value("${app.admin.password:}")
    private String adminPasswordHash;

    private final CidadeService cidadeService;
    private final StripeService stripeService;

    public UsuarioService(UsuarioRepository repository,
                          CidadeService cidadeService,
                          EmailService emailService,
                          PasswordEncoder passwordEncoder,
                          StripeService stripeService) {
        this.repository = repository;
        this.cidadeService = cidadeService;
        this.emailService = emailService;
        this.passwordEncoder = passwordEncoder;
        this.stripeService = stripeService;
    }

    public String normalizarCodigoCidade(String cidade) {
        return cidadeService.normalizarCodigoCidade(cidade);
    }

    public Usuario cadastrarUsuario(UsuarioRequest request) {
        if (repository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("E-mail já cadastrado!");
        }
        if (!request.isConcordaLGPD()) {
            throw new RuntimeException("É obrigatório concordar com os Termos de Privacidade (LGPD).");
        }

        validarSenhaMinima(request.getSenha());

        Role roleReq;
        try {
            roleReq = Role.valueOf(request.getRole().toUpperCase());
        } catch (Exception e) {
            roleReq = Role.CIDADAO;
        }

        // Prevenir Role Injection: apenas admins autenticados podem criar outros admins/agentes
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isSuperAdminSolicitante = auth != null && auth.isAuthenticated() &&
            auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));
        boolean isSolicitanteAdmin = isSuperAdminSolicitante;
        if (!isSolicitanteAdmin && auth != null && auth.isAuthenticated() &&
            auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"))) {
            Usuario solicitante = repository.findByEmail(auth.getName()).orElse(null);
            isSolicitanteAdmin = solicitante != null && solicitante.getAdministradorTitular();
        }

        if (!isSolicitanteAdmin) {
            if (roleReq == Role.AGENTE) {
                throw new RuntimeException("Apenas administradores podem cadastrar novos agentes.");
            }
            if (roleReq != Role.CIDADAO && roleReq != Role.ADMINISTRADOR) {
                roleReq = Role.CIDADAO;
            }
        }

        // Auto-cadastro de Admin fica PENDENTE; admin criado por outro admin ou agente criado por admin fica ATIVO
        Status statusInicial = (roleReq == Role.ADMINISTRADOR && !isSolicitanteAdmin)
            ? Status.PENDENTE : Status.ATIVO;

        String cidNorm = normalizarCodigoCidade(request.getCidade());
        if (isSolicitanteAdmin && roleReq != Role.CIDADAO && !isSuperAdminSolicitante) {
            String adminEmail = auth.getName();
            Usuario admin = repository.findByEmail(adminEmail).orElse(null);
            if (admin != null && admin.getCidade() != null && !admin.getCidade().isBlank()) {
                cidNorm = normalizarCodigoCidade(admin.getCidade());
            }
        }

        Cidade cidadeEntidade = null;
        if (cidNorm != null) {
            cidadeEntidade = cidadeService.buscarOuCriarCidade(cidNorm);
        }

        // Validação de Limites por Plano de Cidade
        if (roleReq == Role.ADMINISTRADOR && cidadeEntidade != null) {
            long gestoresExistentes = repository.countByCidadeIgnoreCaseAndRole(cidadeEntidade.getCodigo(), Role.ADMINISTRADOR.name());
            int limite = cidadeEntidade.getLimiteGestores();
            if (gestoresExistentes >= limite) {
                throw new IllegalArgumentException("Limite de gestores atingido para o município de " + cidadeEntidade.getNome() + 
                    " (" + limite + " gestor(es) no plano " + cidadeEntidade.getPlanoEfetivo() + ").");
            }
        } else if (roleReq == Role.AGENTE && cidadeEntidade != null) {
            if (!cidadeEntidade.isRecursoAgentesLiberado()) {
                throw new IllegalArgumentException("O plano atual do município (" + cidadeEntidade.getPlanoEfetivo() + 
                    ") não permite agentes de campo. É necessário o Plano PRO Municipal.");
            }
        }

        Usuario usuario = new Usuario();
        usuario.setNome(request.getNome());
        usuario.setEmail(request.getEmail());
        usuario.setTelefone(request.getTelefone());
        usuario.setSenha(passwordEncoder.encode(request.getSenha()));
        usuario.setEspecialidade(request.getEspecialidade());
        usuario.setCidade(cidNorm);
        if (cidadeEntidade != null) {
            usuario.setCidadeEntidade(cidadeEntidade);
        }

        usuario.setRole(roleReq.name());
        usuario.setStatus(statusInicial.name());

        Usuario salvo;
        try {
            salvo = repository.saveAndFlush(usuario);
        } catch (DataIntegrityViolationException e) {
            throw new IllegalArgumentException("E-mail já cadastrado!");
        }

        if (roleReq == Role.ADMINISTRADOR && !isSolicitanteAdmin) {
            emailService.enviarEmailAprovacaoAdmin(salvo);
        }

        return salvo;
    }

    public LoginAttemptResult validarLogin(String email, String senhaDigitada) {
        Optional<Usuario> usuarioOpt = repository.findByEmail(email)
            .filter(u -> passwordEncoder.matches(senhaDigitada, u.getSenha()));

        if (usuarioOpt.isEmpty()) {
            return LoginAttemptResult.invalid();
        }

        Usuario usuario = usuarioOpt.get();
        if (!Status.ATIVO.name().equalsIgnoreCase(usuario.getStatus())) {
            return LoginAttemptResult.blocked(usuario, obterMensagemStatusNaoAtivo(usuario.getStatus()));
        }

        return LoginAttemptResult.success(usuario);
    }

    private String obterMensagemStatusNaoAtivo(String status) {
        if (status == null || status.isBlank()) {
            return "Sua conta não está ativa.";
        }

        return switch (status.trim().toUpperCase()) {
            case "PENDENTE" -> "Seu cadastro está pendente de aprovação.";
            case "BLOQUEADO" -> "Sua conta está bloqueada.";
            case "REJEITADO" -> "Seu cadastro foi rejeitado.";
            default -> "Sua conta não está ativa.";
        };
    }

    @Transactional(readOnly = true)
    public List<Usuario> listarTodos() {
        return repository.findAll();
    }

    @Transactional(readOnly = true)
    public Usuario buscarPorId(String id) {
        Usuario usuario = repository.findById(id).orElse(null);
        if (usuario == null) {
            return null;
        }
        validarAcessoLeituraUsuario(usuario);
        return usuario;
    }

    /**
     * Valida a senha master do administrador.
     * A senha deve ser um hash BCrypt válido configurado via variável de ambiente.
     */
    public boolean validarSenhaAdmin(String senhaDigitada) {
       if (adminPasswordHash == null || adminPasswordHash.isBlank()) {
           log.warn("Senha de admin não configurada em app.admin.password!");
           return false;
       }
       if (!adminPasswordHash.startsWith("$2")) {
           throw new IllegalStateException("app.admin.password deve ser um hash BCrypt válido configurado via variável de ambiente.");
       }
       return passwordEncoder.matches(senhaDigitada, adminPasswordHash);
    }

    public List<Usuario> buscarUsuariosPorRole(String role, String cidade) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isAdmin = auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));
        boolean isAgente = auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_AGENTE"));
        boolean isSuperAdmin = auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));

        String cidadeBusca;
        if (isSuperAdmin) {
            cidadeBusca = normalizarCodigoCidade(cidade);
        } else {
            Usuario usuarioAutenticado = obterUsuarioAutenticado(auth);
            if ((isAdmin || isAgente) && (usuarioAutenticado == null || usuarioAutenticado.getCidade() == null || usuarioAutenticado.getCidade().isBlank())) {
                return List.of();
            }
            cidadeBusca = (isAdmin || isAgente)
                ? normalizarCodigoCidade(usuarioAutenticado.getCidade())
                : normalizarCodigoCidade(cidade);
        }

        return repository.findByCidadeAndRole(cidadeBusca, role);
    }

    @Transactional(readOnly = true)
    public List<Usuario> listarPendentes() {
        return repository.findByStatus(Status.PENDENTE.name());
    }

    public Usuario aprovarUsuario(String id) {
        Usuario usuario = repository.findById(id)
            .orElseThrow(() -> new RuntimeException("Usuário não encontrado: " + id));
        checkUserJurisdiction(usuario);
        usuario.setStatus(Status.ATIVO.name());
        return repository.save(usuario);
    }

    /**
     * Promove um cidadão/usuário a AGENTE.
     * Proteção por ADMINISTRADOR garantida no SecurityConfig.
     */
    public Usuario promoverParaAgente(String email) {
        Usuario usuario = repository.findByEmail(email)
            .orElseThrow(() -> new RuntimeException("Usuário não encontrado com e-mail: " + email));
        checkUserJurisdiction(usuario);

        if (usuario.getCidade() != null) {
            Cidade cidade = cidadeService.buscarPorCodigo(usuario.getCidade()).orElse(null);
            if (cidade != null && !cidade.isRecursoAgentesLiberado()) {
                throw new IllegalArgumentException("O plano do município (" + cidade.getPlanoEfetivo() + 
                    ") não contempla agentes de campo. É necessário o Plano PRO Municipal.");
            }
        }

        usuario.setRole(Role.AGENTE.name());
        usuario.setStatus(Status.ATIVO.name());
        return repository.save(usuario);
    }

    private void checkUserJurisdiction(Usuario targetUser) {
        if (targetUser == null || targetUser.getCidade() == null || targetUser.getCidade().trim().isEmpty()) return;
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        // SUPER_ADMIN: sem restrição geográfica — gerencia usuários de todas as cidades
        boolean isSuperAdmin = auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));
        if (isSuperAdmin) return;

        boolean isAdmin = auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));
        
        if (isAdmin && auth != null) {
            String adminEmail = auth.getName();
            Usuario admin = repository.findByEmail(adminEmail).orElse(null);
            if (admin != null && admin.getCidade() != null && !admin.getCidade().trim().isEmpty()) {
                String adminCid = normalizarCodigoCidade(admin.getCidade());
                String targetCid = normalizarCodigoCidade(targetUser.getCidade());
                if (adminCid != null && targetCid != null && !adminCid.equalsIgnoreCase(targetCid)) {
                    throw new SecurityException("Acesso negado: Você só pode modificar usuários da sua própria cidade.");
                }
            }
        }
    }

    /**
     * Deleta um usuário.
     * Proteção por ADMINISTRADOR garantida no SecurityConfig.
     */
    public boolean deletarUsuario(String id) {
        Usuario usuario = repository.findById(id).orElse(null);
        if (usuario == null) return false;
        checkUserJurisdiction(usuario);
        repository.deleteById(id);
        return true;
    }

    /**
     * Exclui a própria conta do usuário autenticado.
     * Em vez de DELETE físico (quebraria FKs com ocorrências),
     * anonimiza todos os dados pessoais (LGPD) e marca como DELETADO.
     */
    public void excluirPropriaConta(String email) {
        Usuario usuario = repository.findByEmail(email)
            .orElseThrow(() -> new RuntimeException("Usuário não encontrado."));

        log.info("Exclusão de conta solicitada pelo usuário: {} (id: {})", email, usuario.getId());

        // Anonimização LGPD — remove todos os dados pessoais
        usuario.setNome("Usuário Removido");
        usuario.setEmail("deletado_" + usuario.getId() + "@removed.local");
        usuario.setTelefone(null);
        usuario.setSenha(passwordEncoder.encode(java.util.UUID.randomUUID().toString()));
        usuario.setFcmToken(null);
        usuario.setResetSenhaCodigo(null);
        usuario.setResetSenhaExpiracao(null);
        usuario.setStatus("DELETADO");

        repository.save(usuario);
        log.info("Conta anonimizada com sucesso (id: {})", usuario.getId());
    }

    public Usuario atualizarUsuario(String id, UsuarioRequest request) {
        Usuario usuario = repository.findById(id)
            .orElseThrow(() -> new RuntimeException("Usuário não encontrado!"));

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isSuperAdmin = auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));
        boolean isAdmin = auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));
        boolean isProprio = auth != null && auth.getName().equals(usuario.getEmail());

        if (!isAdmin && !isSuperAdmin && !isProprio) {
            throw new SecurityException("Você não tem permissão para editar este perfil.");
        }

        if (isAdmin && !isProprio) {
            checkUserJurisdiction(usuario);
        }

        if (request.getNome() != null) usuario.setNome(request.getNome());
        if (request.getTelefone() != null) usuario.setTelefone(request.getTelefone());
        if (request.getCidade() != null) {
            String norm = normalizarCodigoCidade(request.getCidade());
            usuario.setCidade(norm);
            if (norm != null) {
                cidadeService.buscarPorCodigo(norm).ifPresent(usuario::setCidadeEntidade);
            }
        }
        if (request.getFcmToken() != null) usuario.setFcmToken(request.getFcmToken());

        // Apenas admins podem mudar a role de outros usuários
        if ((isAdmin || isSuperAdmin) && request.getRole() != null) {
            String novaRole;
            try {
                novaRole = Role.valueOf(request.getRole().trim().toUpperCase()).name();
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Role inválida.");
            }
            if (Role.SUPER_ADMIN.name().equals(novaRole) && !isSuperAdmin) {
                throw new SecurityException("Apenas SUPER_ADMIN pode definir a role SUPER_ADMIN.");
            }
            if (!isSuperAdmin
                && !Role.CIDADAO.name().equals(novaRole)
                && !Role.AGENTE.name().equals(novaRole)
                && !Role.ADMINISTRADOR.name().equals(novaRole)) {
                throw new SecurityException("ADMINISTRADOR só pode definir roles entre CIDADAO, AGENTE e ADMINISTRADOR.");
            }
            usuario.setRole(novaRole);
        }

        if (request.getSenha() != null && !request.getSenha().isBlank()) {
            usuario.setSenha(passwordEncoder.encode(request.getSenha()));
        }

        return repository.save(usuario);
    }
    public boolean solicitarResetSenha(String email) {
        Optional<Usuario> userOpt = repository.findByEmail(email);
        if (userOpt.isEmpty()) return false;

        Usuario user = userOpt.get();
        // Gerar código de 6 dígitos
        String codigo = String.format("%06d", new java.security.SecureRandom().nextInt(999999));
        user.setResetSenhaCodigo(codigo);
        user.setResetSenhaExpiracao(LocalDateTime.now().plusMinutes(15));
        user.setResetSenhaTentativas(0); // Reinicia contador ao solicitar novo código
        repository.save(user);

        emailService.enviarEmailRecuperacaoSenha(email, codigo);
        return true;
    }

    public boolean resetarSenha(String email, String codigo, String novaSenha) {
        Optional<Usuario> userOpt = repository.findByEmail(email);
        if (userOpt.isEmpty()) return false;

        Usuario user = userOpt.get();

        // SEGURANÇA (VULN-08): Bloquear se já excedeu 5 tentativas
        if (user.getResetSenhaTentativas() >= 5) {
            user.setResetSenhaCodigo(null);
            user.setResetSenhaExpiracao(null);
            repository.save(user);
            return false;
        }

        if (user.getResetSenhaExpiracao() == null || user.getResetSenhaExpiracao().isBefore(LocalDateTime.now())) {
            user.setResetSenhaCodigo(null);
            user.setResetSenhaExpiracao(null);
            repository.save(user);
            return false;
        }

        if (user.getResetSenhaCodigo() == null || !user.getResetSenhaCodigo().equals(codigo)) {
            user.setResetSenhaTentativas(user.getResetSenhaTentativas() + 1);
            if (user.getResetSenhaTentativas() >= 5) {
                // Invalida o código imediatamente após 5 erros
                user.setResetSenhaCodigo(null);
                user.setResetSenhaExpiracao(null);
            }
            repository.save(user);
            return false;
        }

        validarSenhaMinima(novaSenha);
        user.setSenha(passwordEncoder.encode(novaSenha));
        user.setResetSenhaCodigo(null);
        user.setResetSenhaExpiracao(null);
        user.setResetSenhaTentativas(0);
        repository.save(user);
        return true;
    }

    @Transactional
    public Usuario ativarSemAnunciosVitalicio(String email, boolean exigirVerificacaoStripe) {
        Usuario usuario = repository.findByEmail(email)
            .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado com e-mail: " + email));

        // Se já está ativo, apenas retorna
        if (Boolean.TRUE.equals(usuario.getSemAnunciosVitalicio())) {
            return usuario;
        }

        if (exigirVerificacaoStripe) {
            if (stripeService.isConfigurado()) {
                boolean pago = stripeService.verificarPagamentoVitalicio(email);
                if (!pago) {
                    throw new IllegalStateException("Nenhum pagamento aprovado foi localizado no Stripe para o e-mail: " + email + ". Por favor, conclua o pagamento pelo link oficial antes de ativar.");
                }
            } else {
                log.warn("[STRIPE] Chave do Stripe não configurada. Ativação em modo de desenvolvimento para: {}", email);
            }
        }

        usuario.setSemAnunciosVitalicio(true);
        log.info("[VITALÍCIO] Licença vitalícia sem anúncios ativada com sucesso para: {}", email);
        return repository.save(usuario);
    }

    @Transactional
    public Usuario ativarSemAnunciosVitalicio(String email) {
        return ativarSemAnunciosVitalicio(email, false);
    }

    private Usuario obterUsuarioAutenticado(Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || auth.getName() == null || auth.getName().isBlank()) {
            return null;
        }
        return repository.findByEmail(auth.getName()).orElse(null);
    }

    private void validarSenhaMinima(String senha) {
        if (senha == null || senha.isBlank()) {
            throw new IllegalArgumentException("A senha é obrigatória");
        }
        if (senha.length() < 6) {
            throw new IllegalArgumentException("A senha deve ter no mínimo 6 caracteres");
        }
    }

    private void validarAcessoLeituraUsuario(Usuario targetUser) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            throw new SecurityException("Acesso negado: autenticação obrigatória.");
        }

        boolean isSuperAdmin = auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));
        if (isSuperAdmin) {
            return;
        }

        boolean isProprio = auth.getName().equalsIgnoreCase(targetUser.getEmail());
        if (isProprio) {
            return;
        }

        boolean isAdmin = auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));
        if (isAdmin) {
            checkUserJurisdiction(targetUser);
            return;
        }

        throw new SecurityException("Acesso negado: Você não tem permissão para consultar este usuário.");
    }

    public record LoginAttemptResult(Usuario usuario, String blockedMessage) {
        public static LoginAttemptResult success(Usuario usuario) {
            return new LoginAttemptResult(usuario, null);
        }

        public static LoginAttemptResult blocked(Usuario usuario, String blockedMessage) {
            return new LoginAttemptResult(usuario, blockedMessage);
        }

        public static LoginAttemptResult invalid() {
            return new LoginAttemptResult(null, null);
        }

        public boolean isAuthenticated() {
            return usuario != null && blockedMessage == null;
        }

        public boolean isBlocked() {
            return usuario != null && blockedMessage != null;
        }
    }
}
