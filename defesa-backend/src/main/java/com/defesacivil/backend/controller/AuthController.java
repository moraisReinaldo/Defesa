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

            Map<String, Object> response = new HashMap<>();
            String mensagem = "Cadastro realizado! ";

            if (Status.PENDENTE.name().equals(usuarioSalvo.getStatus())) {
                mensagem += "Seu acesso como Administrador ficará PENDENTE de aprovação.";
                response.put("pendente", true);
            } else {
                mensagem += "Você já pode acessar o sistema.";
                response.put("pendente", false);
            }

            response.put("message", mensagem);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/usuarios/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String email = credentials.get("email");
        String senha = credentials.get("senha");

        if (email == null || senha == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Email e senha são obrigatórios"));
        }

        Optional<Usuario> usuarioOpt = usuarioService.login(email, senha);
        if (usuarioOpt.isPresent()) {
            Usuario usuario = usuarioOpt.get();

            if (Status.PENDENTE.name().equals(usuario.getStatus())) {
                return ResponseEntity.status(403).body(
                    Map.of("message", "Seu cadastro ainda está pendente de aprovação.")
                );
            }

            String token = jwtService.generateToken(usuario.getEmail(), usuario.getRole());
            // A senha nunca deve sair em nenhuma resposta — @JsonIgnore na entidade garante isso,
            // mas zeramos aqui também como dupla proteção
            usuario.setSenha(null);

            return ResponseEntity.ok(Map.of("usuario", usuario, "token", token));
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

    @GetMapping("/usuarios/agentes")
    public ResponseEntity<List<Usuario>> listarAgentes(@RequestParam(required = false) String cidade) {
        List<Usuario> agentes = usuarioService.buscarUsuariosPorRole("AGENTE", cidade);
        // @JsonIgnore na entidade garante que a senha não é serializada
        return ResponseEntity.ok(agentes);
    }
}
