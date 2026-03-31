package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.domain.enums.Status;
import com.defesacivil.backend.dto.UsuarioRequest;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UsuarioService {

    @Autowired
    private UsuarioRepository repository;

    @Autowired
    private EmailService emailService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // Senha admin carregada de variável de ambiente/properties — NUNCA hardcoded
    @Value("${app.admin.password:#{null}}")
    private String adminPassword;

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
        
        Status statusInicial = Status.ATIVO;

        if (roleReq == Role.ADMINISTRADOR) {
            throw new RuntimeException("Contas de administrador exigem autorização manual. Solicite via e-mail para reinaldoinfra07@gmail.com");
        }

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
            System.err.println("ALERTA: Senha de admin não configurada em app.admin.password!");
            return false;
        }
        return adminPassword.equals(senhaDigitada);
    }

    public List<Usuario> buscarUsuariosPorRole(String role, String cidade) {
        String cidadeBusca = (cidade != null && !cidade.isBlank()) ? cidade.trim().toUpperCase() : null;
        return repository.findByCidadeAndRole(cidadeBusca, role);
    }
}
