package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.service.UsuarioService;
import com.defesacivil.backend.dto.UsuarioRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller de gestão de Usuários.
 *
 * SEGURANÇA: A verificação de roles é feita pelo Spring Security (SecurityConfig).
 * Este controller não duplica verificações — apenas delega ao serviço.
 */
@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioService usuarioService;

    public UsuarioController(UsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    /** Promover cidadão a agente — apenas ADMINISTRADOR (protegido no SecurityConfig) */
    @PostMapping("/promover")
    public ResponseEntity<?> promoverParaAgente(@RequestBody Map<String, String> payload) {
        String email = payload.get("email");
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("E-mail é obrigatório para promoção.");
        }
        Usuario promovido = usuarioService.promoverParaAgente(email);
        return ResponseEntity.ok(Map.of(
            "message", "Usuário promovido a AGENTE com sucesso!",
            "usuario", promovido
        ));
    }

    /** Deletar usuário — apenas ADMINISTRADOR (protegido no SecurityConfig) */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletarUsuario(@PathVariable String id) {
        boolean deletado = usuarioService.deletarUsuario(id);
        return deletado ? ResponseEntity.ok().<Void>build() : ResponseEntity.notFound().build();
    }

    /** Atualizar perfil — autenticado (serviço verifica se é o próprio ou admin) */
    @PutMapping("/{id}")
    public ResponseEntity<Usuario> atualizar(
            @PathVariable String id,
            @Valid @RequestBody UsuarioRequest request) {
        Usuario atualizado = usuarioService.atualizarUsuario(id, request);
        return ResponseEntity.ok(atualizado);
    }
}
