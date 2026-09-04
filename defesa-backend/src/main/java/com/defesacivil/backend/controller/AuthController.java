package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.Status;
import com.defesacivil.backend.dto.UsuarioRequest;
import com.defesacivil.backend.security.JwtService;
import com.defesacivil.backend.service.UsuarioService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Controller de Autenticação e listagem de agentes.
 * Rotas públicas configuradas no SecurityConfig.
 */
@RestController
@RequestMapping("/api")
public class AuthController {

    private final UsuarioService usuarioService;
    private final JwtService jwtService;

    public AuthController(UsuarioService usuarioService, JwtService jwtService) {
        this.usuarioService = usuarioService;
        this.jwtService = jwtService;
    }

    @PostMapping("/auth/cadastro")
    public ResponseEntity<?> cadastrar(@jakarta.validation.Valid @RequestBody UsuarioRequest request) {
        try {
            Usuario usuarioSalvo = usuarioService.cadastrarUsuario(request);

            boolean isPendente = Status.PENDENTE.name().equals(usuarioSalvo.getStatus());
            boolean usuarioAtivo = Status.ATIVO.name().equalsIgnoreCase(usuarioSalvo.getStatus());
            String token = usuarioAtivo ? jwtService.generateToken(usuarioSalvo.getEmail(), usuarioSalvo.getRole()) : null;
            usuarioSalvo.setSenha(null);

            Map<String, Object> response = new HashMap<>();
            String mensagem = isPendente 
                ? "Cadastro realizado! Sua conta de Coordenador está em análise e aguarda homologação do Super Admin."
                : "Cadastro realizado com sucesso! Bem-vindo ao Defesa em Foco.";

            response.put("usuario", usuarioSalvo);
            response.put("token", token);
            response.put("pendente", isPendente);
            response.put("message", mensagem);
            response.put("sucesso", true);

            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage(), "sucesso", false));
        }
    }

    @PostMapping("/usuarios/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String email = credentials.get("email");
        String senha = credentials.get("senha");

        if (email == null || senha == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Email e senha são obrigatórios"));
        }

        UsuarioService.LoginAttemptResult loginResult = usuarioService.validarLogin(email, senha);
        if (loginResult.isBlocked()) {
            boolean isPendente = Status.PENDENTE.name().equalsIgnoreCase(loginResult.usuario().getStatus());
            return ResponseEntity.status(403).body(Map.of(
                "message", loginResult.blockedMessage(),
                "pendente", isPendente,
                "sucesso", false
            ));
        }

        if (loginResult.isAuthenticated()) {
            Usuario usuario = loginResult.usuario();
            String token = jwtService.generateToken(usuario.getEmail(), usuario.getRole());
            usuario.setSenha(null);

            Map<String, Object> response = new HashMap<>();
            response.put("usuario", usuario);
            response.put("token", token);
            response.put("pendente", false);

            return ResponseEntity.ok(response);
        }

        return ResponseEntity.status(401).body(Map.of("message", "Email ou senha incorretos"));
    }

    @PostMapping("/auth/admin-login")
    public ResponseEntity<?> loginAdmin(@RequestBody Map<String, String> body) {
        String senha = body.get("senha");
        if (senha == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Senha é obrigatória"));
        }

        if (usuarioService.validarSenhaAdmin(senha)) {
            String token = jwtService.generateToken("admin@defesacivil.gov.br", "ADMINISTRADOR");
            return ResponseEntity.ok(Map.of(
                "token", token,
                "message", "Autenticação Master realizada com sucesso"
            ));
        }

        return ResponseEntity.status(401).body(Map.of("message", "Senha de administrador incorreta"));
    }

    /**
     * Logout — Invalida o token JWT na blacklist do servidor e confirma ao cliente.
     */
    @PostMapping("/auth/logout")
    public ResponseEntity<?> logout(jakarta.servlet.http.HttpServletRequest request) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            jwtService.revokeToken(token);
        }
        return ResponseEntity.ok(Map.of("message", "Logout realizado com sucesso"));
    }

    @GetMapping("/usuarios/agentes")
    public ResponseEntity<List<Usuario>> listarAgentes(@RequestParam(required = false) String cidade) {
        List<Usuario> agentes = usuarioService.buscarUsuariosPorRole("AGENTE", cidade);
        // @JsonIgnore na entidade garante que a senha não é serializada
        return ResponseEntity.ok(agentes);
    }
}
