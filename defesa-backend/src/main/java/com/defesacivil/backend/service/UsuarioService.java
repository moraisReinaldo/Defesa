package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.domain.enums.Status;
import com.defesacivil.backend.dto.UsuarioRequest;
import com.defesacivil.backend.repository.UsuarioRepository;
import com.defesacivil.backend.repository.CidadeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
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
    private final CidadeRepository cidadeRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    // Carregada de variável de ambiente — nunca hardcoded
    @Value("${app.admin.password:}")
    private String adminPasswordHash;

    public UsuarioService(UsuarioRepository repository,
                          CidadeRepository cidadeRepository,
                          EmailService emailService,
                          PasswordEncoder passwordEncoder) {
        this.repository = repository;
        this.cidadeRepository = cidadeRepository;
        this.emailService = emailService;
        this.passwordEncoder = passwordEncoder;
    }

    public String normalizarCodigoCidade(String cidade) {
        if (cidade == null || cidade.isBlank()) return null;
        String limpa = cidade.trim().toUpperCase();
        return cidadeRepository.findByCodigoIgnoreCase(limpa)
            .or(() -> cidadeRepository.findByNomeIgnoreCase(limpa))
            .map(com.defesacivil.backend.domain.Cidade::getCodigo)
            .orElse(limpa);
    }

    public Usuario cadastrarUsuario(UsuarioRequest request) {
        if (repository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("E-mail já cadastrado!");
        }
        if (!request.isConcordaLGPD()) {
            throw new RuntimeException("É obrigatório concordar com os Termos de Privacidade (LGPD).");
        }

        // Validação de senha
        if (request.getSenha() == null || request.getSenha().isBlank()) {
            throw new RuntimeException("A senha é obrigatória");
        }
        if (request.getSenha().length() < 6) {
            throw new RuntimeException("A senha deve ter no mínimo 6 caracteres");
        }

        Role roleReq;
        try {
            roleReq = Role.valueOf(request.getRole().toUpperCase());
        } catch (Exception e) {
            roleReq = Role.CIDADAO;
        }

        // Prevenir Role Injection: apenas admins autenticados podem criar outros admins/agentes
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isSolicitanteAdmin = auth != null && auth.isAuthenticated() &&
            auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));

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

        Usuario usuario = new Usuario();
        usuario.setNome(request.getNome());
        usuario.setEmail(request.getEmail());
        usuario.setTelefone(request.getTelefone());
        usuario.setSenha(passwordEncoder.encode(request.getSenha()));
        usuario.setEspecialidade(request.getEspecialidade());

        String cidNorm = normalizarCodigoCidade(request.getCidade());
        if (roleReq == Role.AGENTE && isSolicitanteAdmin) {
            String adminEmail = auth.getName();
            Usuario admin = repository.findByEmail(adminEmail).orElse(null);
            if (admin != null && admin.getCidade() != null && !admin.getCidade().isBlank()) {
                cidNorm = normalizarCodigoCidade(admin.getCidade());
            }
        }
        usuario.setCidade(cidNorm);
        if (cidNorm != null) {
            cidadeRepository.findByCodigoIgnoreCase(cidNorm).ifPresent(usuario::setCidadeEntidade);
        }

        usuario.setRole(roleReq.name());
        usuario.setStatus(statusInicial.name());

        Usuario salvo = repository.save(usuario);

        if (roleReq == Role.ADMINISTRADOR && !isSolicitanteAdmin) {
            emailService.enviarEmailAprovacaoAdmin(salvo);
        }

        return salvo;
    }

    public Optional<Usuario> login(String email, String senhaDigitada) {
        return repository.findByEmail(email)
            .filter(u -> passwordEncoder.matches(senhaDigitada, u.getSenha()));
    }

    @Transactional(readOnly = true)
    public List<Usuario> listarTodos() {
        return repository.findAll();
    }

    @Transactional(readOnly = true)
    public Usuario buscarPorId(String id) {
        return repository.findById(id).orElse(null);
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
        String adminCity = null;
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isAdmin = auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));
            
        if (isAdmin && auth != null) {
            String adminEmail = auth.getName();
            Usuario admin = repository.findByEmail(adminEmail).orElse(null);
            if (admin != null) {
                adminCity = admin.getCidade();
            }
        }

        // Se for admin e tiver cidade, ignora o parâmetro e força a busca na jurisdição
        String cidadeBusca;
        if (adminCity != null && !adminCity.trim().isEmpty()) {
            cidadeBusca = normalizarCodigoCidade(adminCity);
        } else {
            cidadeBusca = normalizarCodigoCidade(cidade);
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

        // Apenas o próprio usuário ou um admin pode editar
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isAdmin = auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));
        boolean isProprio = auth != null && auth.getName().equals(usuario.getEmail());

        if (!isAdmin && !isProprio) {
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
                cidadeRepository.findByCodigoIgnoreCase(norm).ifPresent(usuario::setCidadeEntidade);
            }
        }
        if (request.getFcmToken() != null) usuario.setFcmToken(request.getFcmToken());

        // Apenas admins podem mudar a role de outros usuários
        if (isAdmin && request.getRole() != null) {
            usuario.setRole(request.getRole().toUpperCase());
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
        repository.save(user);

        emailService.enviarEmailRecuperacaoSenha(email, codigo);
        return true;
    }

    public boolean resetarSenha(String email, String codigo, String novaSenha) {
        Optional<Usuario> userOpt = repository.findByEmail(email);
        if (userOpt.isEmpty()) return false;

        Usuario user = userOpt.get();
        if (user.getResetSenhaCodigo() == null || !user.getResetSenhaCodigo().equals(codigo)) {
            return false;
        }

        if (user.getResetSenhaExpiracao() == null || user.getResetSenhaExpiracao().isBefore(LocalDateTime.now())) {
            return false;
        }

        user.setSenha(passwordEncoder.encode(novaSenha));
        user.setResetSenhaCodigo(null);
        user.setResetSenhaExpiracao(null);
        repository.save(user);
        return true;
    }
}
