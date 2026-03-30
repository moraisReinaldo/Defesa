package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.Status;
import com.defesacivil.backend.dto.UsuarioRequest;
import com.defesacivil.backend.security.JwtService;
import com.defesacivil.backend.service.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api")
public class AuthController {

    @Autowired
    private UsuarioService usuarioService;

    @Autowired
    private JwtService jwtService;

    @PostMapping("/auth/cadastro")
    public ResponseEntity<?> cadastrar(@RequestBody UsuarioRequest request) {
        try {
            Usuario usuarioSalvo = usuarioService.cadastrarUsuario(request);
            
            Map<String, Object> response = new HashMap<>();
            String mensagem = "Cadastro realizado! ";
            
            if (Status.PENDENTE.name().equals(usuarioSalvo.getStatus())) {
                mensagem += "Seu acesso como Administrador ficará PENDENTE de aprovação. Um e-mail de confirmação foi enviado à equipe para moderação.";
                response.put("pendente", true);
            } else {
                mensagem += "Você já pode acessar o sistema.";
                response.put("pendente", false);
            }

            response.put("message", mensagem);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @PostMapping("/usuarios/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String email = credentials.get("email");
        String senha = credentials.get("senha");

        if (email == null || senha == null) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", "Email e senha são obrigatórios");
            return ResponseEntity.badRequest().body(errorResponse);
        }

        Optional<Usuario> usuarioOpt = usuarioService.login(email, senha);
        if (usuarioOpt.isPresent()) {
            Usuario usuario = usuarioOpt.get();
            
            if (Status.PENDENTE.name().equals(usuario.getStatus())) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("message", "Seu cadastro ainda está pendente de aprovação por e-mail.");
                return ResponseEntity.status(403).body(errorResponse);
            }

            // Gerar Token JWT com a Role do usuário
            String token = jwtService.generateToken(usuario.getEmail(), usuario.getRole());
            
            // Retornar usuário e token (removendo senha por segurança)
            usuario.setSenha(null);
            
            Map<String, Object> response = new HashMap<>();
            response.put("usuario", usuario);
            response.put("token", token);
            
            return ResponseEntity.ok(response);
        }

        Map<String, String> errorResponse = new HashMap<>();
        errorResponse.put("message", "Email ou senha incorretos");
        return ResponseEntity.status(401).body(errorResponse);
    }

    @PostMapping("/auth/admin-login")
    public ResponseEntity<?> loginAdmin(@RequestBody Map<String, String> body) {
        String senha = body.get("senha");
        if (senha == null) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", "Senha é obrigatória");
            return ResponseEntity.badRequest().body(errorResponse);
        }

        if (usuarioService.validarSenhaAdmin(senha)) {
            // Admin "Root" Master Login
            String token = jwtService.generateToken("admin@defesacivil.gov.br", "ADMINISTRADOR");
            Map<String, Object> response = new HashMap<>();
            response.put("token", token);
            response.put("message", "Autenticação Master realizada com sucesso");
            return ResponseEntity.ok().body(response);
        }

        Map<String, String> errorResponse = new HashMap<>();
        errorResponse.put("message", "Senha de administrador incorreta");
        return ResponseEntity.status(401).body(errorResponse);
    }

    @GetMapping("/usuarios/agentes")
    public ResponseEntity<List<Usuario>> listarAgentes(@RequestParam(required = false) String cidade) {
        List<Usuario> agentes = usuarioService.buscarUsuariosPorRole("AGENTE", cidade);
        // Remover senhas antes de retornar
        agentes.forEach(a -> a.setSenha(null));
        return ResponseEntity.ok(agentes);
    }
}
