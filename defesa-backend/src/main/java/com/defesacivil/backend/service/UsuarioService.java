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

import java.util.Arrays;
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
            String cidadeReq = request.getCidade() != null ? request.getCidade().trim() : "";
            if (cidadeReq.isEmpty()) {
                throw new RuntimeException("A cidade é obrigatória para administradores.");
            }

            List<Usuario> adminsNaCidade = repository.findByCidadeIgnoreCaseAndRoleAndStatusIn(
                    cidadeReq,
                    Role.ADMINISTRADOR,
                    Arrays.asList(Status.ATIVO, Status.PENDENTE)
            );

            // Filtro manual para case insensitive, já que o Firebase whereEqualTo é case sensitive
            boolean jaExisteAdmin = adminsNaCidade.stream()
                .anyMatch(u -> u.getCidade().equalsIgnoreCase(cidadeReq));

            if (jaExisteAdmin) {
                throw new RuntimeException("Já existe um administrador cadastrado ou pendente para a cidade de " + request.getCidade());
            }

            statusInicial = Status.PENDENTE;
        }

        Usuario usuario = new Usuario();
        usuario.setNome(request.getNome());
        usuario.setEmail(request.getEmail());
        usuario.setTelefone(request.getTelefone());
        // Hash da senha com BCrypt — nunca armazenar em texto puro
        usuario.setSenha(passwordEncoder.encode(request.getSenha()));
        usuario.setCidade(request.getCidade());
        usuario.setRole(roleReq);
        usuario.setStatus(statusInicial);

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
}
