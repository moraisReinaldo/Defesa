package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.repository.UsuarioRepository;
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
    private com.defesacivil.backend.service.UsuarioService usuarioService;

    @PostMapping("/promover")
    public ResponseEntity<?> promoverParaAgente(@RequestBody Map<String, String> payload) {
        String email = payload.get("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "E-mail é obrigatório"));
        }

        Optional<Usuario> usuarioOpt = usuarioRepository.findByEmail(email);
        if (usuarioOpt.isEmpty()) {
            return ResponseEntity.status(404).body(Map.of("message", "Usuário não encontrado com este e-mail"));
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
    public ResponseEntity<?> deletarUsuario(@PathVariable String id) {
        try {
            boolean deletado = usuarioService.deletarUsuario(id);
            if (deletado) return ResponseEntity.ok().build();
            return ResponseEntity.notFound().build();
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
