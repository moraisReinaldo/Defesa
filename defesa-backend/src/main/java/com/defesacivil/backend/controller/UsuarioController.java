package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.repository.UsuarioRepository;
import com.defesacivil.backend.service.UsuarioService;
import com.defesacivil.backend.dto.UsuarioRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private UsuarioService usuarioService;

    @PostMapping("/promover")
    public ResponseEntity<?> promoverParaAgente(@RequestBody Map<String, String> payload) {
        // SEGURANÇA: Apenas Administradores podem promover outros usuários
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        boolean isAdmin = auth != null && auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"));
        
        if (!isAdmin) {
            throw new SecurityException("Acesso negado: Apenas administradores podem promover usuários.");
        }

        String email = payload.get("email");
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("E-mail é obrigatório");
        }

        Optional<Usuario> usuarioOpt = usuarioRepository.findByEmail(email);
        if (usuarioOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Usuario usuario = usuarioOpt.get();
        usuario.setRole("AGENTE");
        usuario.setStatus("ATIVO");
        
        usuarioRepository.save(usuario);

        return ResponseEntity.ok(Map.of(
            "message", "Usuário promovido a AGENTE com sucesso!",
            "usuario", usuario
        ));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletarUsuario(@PathVariable String id) {
        boolean deletado = usuarioService.deletarUsuario(id);
        return deletado ? ResponseEntity.ok().build() : ResponseEntity.notFound().build();
    }

    @PutMapping("/{id}")
    public ResponseEntity<Usuario> atualizar(@PathVariable String id, @Valid @RequestBody UsuarioRequest request) {
        Usuario atualizado = usuarioService.atualizarUsuario(id, request);
        return ResponseEntity.ok(atualizado);
    }
}
