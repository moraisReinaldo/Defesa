package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.domain.enums.Status;
import com.defesacivil.backend.dto.UsuarioRequest;
import com.defesacivil.backend.repository.UsuarioRepository;
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
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    // Carregada de variável de ambiente — nunca hardcoded
    @Value("${app.admin.password:#{null}}")
    private String adminPasswordHash;

    public UsuarioService(UsuarioRepository repository,
                          EmailService emailService,
                          PasswordEncoder passwordEncoder) {
        this.repository = repository;
        this.emailService = emailService;
        this.passwordEncoder = passwordEncoder;
    }

    public Usuario cadastrarUsuario(UsuarioRequest request) {
        if (repository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("E-mail já cadastrado!");
        }
        if (!request.isConcordaLGPD()) {
            throw new RuntimeException("É obrigatório concordar com os Termos de Privacidade (LGPD).");
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

        // Auto-cadastro de Admin fica PENDENTE; admin criado por outro admin fica ATIVO
        Status statusInicial = (roleReq == Role.ADMINISTRADOR && !isSolicitanteAdmin)
            ? Status.PENDENTE : Status.ATIVO;

        Usuario usuario = new Usuario();
        usuario.setNome(request.getNome());
        usuario.setEmail(request.getEmail());
        usuario.setTelefone(request.getTelefone());
        usuario.setSenha(passwordEncoder.encode(request.getSenha()));
        usuario.setCidade(request.getCidade() != null ? request.getCidade().trim().toUpperCase() : null);
        usuario.setRole(roleReq.name());
        usuario.setStatus(statusInicial.name());

        Usuario salvo = repository.save(usuario);

        if (roleReq == Role.ADMINISTRADOR) {
            emailService.enviarEmailAprovacaoAdmin(salvo);
        }

        return salvo;
    }

    public Optional<Usuario> login(String email, String senhaDigitada) {
        return repository.findByEmail(email)
            .filter(u -> passwordEncoder.matches(senhaDigitada, u.getSenha()));
    }

    /**
     * Valida a senha master do administrador.
     * SEGURANÇA: A senha no application.properties deve estar em BCrypt para produção.
     * Em desenvolvimento, aceita texto plano como fallback.
     */
    public boolean validarSenhaAdmin(String senhaDigitada) {
        if (adminPasswordHash == null || adminPasswordHash.isEmpty()) {
            log.warn("Senha de admin não configurada em app.admin.password!");
            return false;
        }
        // Tenta comparação BCrypt primeiro (produção); fallback para texto plano (dev)
        if (adminPasswordHash.startsWith("$2")) {
            return passwordEncoder.matches(senhaDigitada, adminPasswordHash);
        }
        // Comparação de tempo constante para evitar timing attacks
        return java.security.MessageDigest.isEqual(
            adminPasswordHash.getBytes(),
            senhaDigitada.getBytes()
        );
    }

    public List<Usuario> buscarUsuariosPorRole(String role, String cidade) {
        String cidadeBusca = (cidade != null && !cidade.isBlank()) ? cidade.trim().toUpperCase() : null;
        return repository.findByCidadeAndRole(cidadeBusca, role);
    }

    /**
     * Promove um cidadão/usuário a AGENTE.
     * Proteção por ADMINISTRADOR garantida no SecurityConfig.
     */
    public Usuario promoverParaAgente(String email) {
        Usuario usuario = repository.findByEmail(email)
            .orElseThrow(() -> new RuntimeException("Usuário não encontrado com e-mail: " + email));
        usuario.setRole(Role.AGENTE.name());
        usuario.setStatus(Status.ATIVO.name());
        return repository.save(usuario);
    }

    /**
     * Deleta um usuário.
     * Proteção por ADMINISTRADOR garantida no SecurityConfig.
     */
    public boolean deletarUsuario(String id) {
        if (!repository.existsById(id)) return false;
        repository.deleteById(id);
        return true;
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

        if (request.getNome() != null) usuario.setNome(request.getNome());
        if (request.getTelefone() != null) usuario.setTelefone(request.getTelefone());
        if (request.getCidade() != null) usuario.setCidade(request.getCidade().trim().toUpperCase());
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
        String codigo = String.format("%06d", new java.util.Random().nextInt(999999));
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

        if (user.getResetSenhaExpiracao().isBefore(LocalDateTime.now())) {
            return false;
        }

        user.setSenha(passwordEncoder.encode(novaSenha));
        user.setResetSenhaCodigo(null);
        user.setResetSenhaExpiracao(null);
        repository.save(user);
        return true;
    }
}
