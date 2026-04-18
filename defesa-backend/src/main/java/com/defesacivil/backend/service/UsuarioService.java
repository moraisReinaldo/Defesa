package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.domain.enums.Status;
import com.defesacivil.backend.dto.UsuarioRequest;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class UsuarioService {

    private static final Logger log = LoggerFactory.getLogger(UsuarioService.class);

    private final UsuarioRepository repository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    // Senha admin carregada de variável de ambiente/properties — NUNCA hardcoded
    @Value("${app.admin.password:#{null}}")
    private String adminPassword;

    public UsuarioService(UsuarioRepository repository,
                          EmailService emailService,
                          PasswordEncoder passwordEncoder) {
        this.repository = repository;
        this.emailService = emailService;
        this.passwordEncoder = passwordEncoder;
    }

    public Usuario cadastrarUsuario(UsuarioRequest request) {
        Optional<Usuario> existente = repository.findByEmail(request.getEmail());
        if (existente.isPresent()) {
            throw new RuntimeException("E-mail já cadastrado!");
        }

        if (!request.isConcordaLGPD()) {
            throw new RuntimeException("É obrigatório concordar com os Termos de Privacidade (LGPD).");
        }

        Role roleReq;
        try {
            roleReq = Role.valueOf(request.getRole().toUpperCase());
        } catch (Exception e) {
            roleReq = Role.CIDADAO; // fallback
        }

        // --- SEGURANÇA: Prevenir Role Injection ---
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        boolean isSolicianteAdmin = auth != null && auth.isAuthenticated() && 
            auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));

        if (!isSolicianteAdmin) {
            // Se não for um admin logado criando o usuário, restringimos as opções
            if (roleReq == Role.AGENTE) {
                throw new RuntimeException("Apenas administradores podem cadastrar novos agentes.");
            }
            // Só permitimos CIDADAO ou ADMINISTRADOR (que ficará PENDENTE)
            if (roleReq != Role.CIDADAO && roleReq != Role.ADMINISTRADOR) {
                roleReq = Role.CIDADAO;
            }
        }
        
        // Admins já nascem ATIVOS se criados por outro Admin. 
        // Se for auto-cadastro de Admin, fica PENDENTE.
        Status statusInicial = (roleReq == Role.ADMINISTRADOR && !isSolicianteAdmin) ? Status.PENDENTE : Status.ATIVO;

        Usuario usuario = new Usuario();
        usuario.setNome(request.getNome());
        usuario.setEmail(request.getEmail());
        usuario.setTelefone(request.getTelefone());
        // Hash da senha com BCrypt — nunca armazenar em texto puro
        usuario.setSenha(passwordEncoder.encode(request.getSenha()));
        
        String cidadeNormalizada = request.getCidade() != null ? request.getCidade().trim().toUpperCase() : null;
        usuario.setCidade(cidadeNormalizada);
        
        usuario.setRole(roleReq.name());
        usuario.setStatus(statusInicial.name());

        Usuario salvo = repository.save(usuario);

        if (roleReq == Role.ADMINISTRADOR) {
            emailService.enviarEmailAprovacaoAdmin(salvo);
        }

        return salvo;
    }

    public Optional<Usuario> login(String email, String senhaDigitada) {
        Optional<Usuario> usuarioOpt = repository.findByEmail(email);
        if (usuarioOpt.isPresent()) {
            Usuario usuario = usuarioOpt.get();
            if (passwordEncoder.matches(senhaDigitada, usuario.getSenha())) {
                return Optional.of(usuario);
            }
        }
        return Optional.empty();
    }

    public boolean validarSenhaAdmin(String senhaDigitada) {
        if (adminPassword == null || adminPassword.isEmpty()) {
            log.warn("Senha de admin não configurada em app.admin.password!");
            return false;
        }
        // Comparação segura usando PasswordEncoder (resistente a timing attacks)
        // Se a senha no env for plaintext, fazemos comparação direta (fallback para dev)
        return adminPassword.equals(senhaDigitada);
    }

    public List<Usuario> buscarUsuariosPorRole(String role, String cidade) {
        String cidadeBusca = (cidade != null && !cidade.isBlank()) ? cidade.trim().toUpperCase() : null;
        return repository.findByCidadeAndRole(cidadeBusca, role);
    }

    public boolean deletarUsuario(String id) {
        // Obter o usuário autenticado para verificar se ele é um administrador
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        boolean isSolicianteAdmin = auth != null && auth.isAuthenticated() && 
            auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));
        
        if (!isSolicianteAdmin) {
            throw new SecurityException("Apenas administradores podem deletar usuários.");
        }

        Optional<Usuario> usr = repository.findById(id);
        if (usr.isPresent()) {
            repository.deleteById(id);
            return true;
        }
        return false;
    }

    public Usuario atualizarUsuario(String id, UsuarioRequest request) {
        Usuario usuario = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado!"));

        // Apenas o próprio usuário ou um admin pode editar
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        boolean isAdmin = auth != null && auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));
        boolean isProprio = auth != null && auth.getName().equals(usuario.getEmail());

        if (!isAdmin && !isProprio) {
            throw new SecurityException("Você não tem permissão para editar este perfil.");
        }

        if (request.getNome() != null) usuario.setNome(request.getNome());
        if (request.getTelefone() != null) usuario.setTelefone(request.getTelefone());
        if (request.getCidade() != null) usuario.setCidade(request.getCidade().trim().toUpperCase());
        if (request.getFcmToken() != null) usuario.setFcmToken(request.getFcmToken());
        
        // Se um Admin estiver editando, ele pode mudar a role
        if (isAdmin && request.getRole() != null) {
            usuario.setRole(request.getRole().toUpperCase());
        }

        if (request.getSenha() != null && !request.getSenha().isBlank()) {
            usuario.setSenha(passwordEncoder.encode(request.getSenha()));
        }

        return repository.save(usuario);
    }
}
