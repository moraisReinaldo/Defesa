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

    /** Listar todos os usuários — apenas ADMINISTRADOR */
    @GetMapping
    public ResponseEntity<java.util.List<Usuario>> listarTodos() {
        java.util.List<Usuario> usuarios = usuarioService.listarTodos();
        return ResponseEntity.ok(usuarios);
    }

    /** Buscar usuário por ID — autenticado */
    @GetMapping("/{id}")
    public ResponseEntity<Usuario> buscarPorId(@PathVariable String id) {
        Usuario usuario = usuarioService.buscarPorId(id);
        return usuario != null ? ResponseEntity.ok(usuario) : ResponseEntity.notFound().build();
    }

    /** Listar usuários pendentes de aprovação — apenas ADMINISTRADOR */
    @GetMapping("/pendentes")
    public ResponseEntity<java.util.List<Usuario>> listarPendentes() {
        return ResponseEntity.ok(usuarioService.listarPendentes());
    }

    /** Aprovar usuário pendente — apenas ADMINISTRADOR */
    @PostMapping("/{id}/aprovar")
    public ResponseEntity<?> aprovarUsuario(@PathVariable String id) {
        Usuario aprovado = usuarioService.aprovarUsuario(id);
        return ResponseEntity.ok(Map.of(
            "message", "Usuário aprovado com sucesso!",
            "usuario", aprovado
        ));
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

    /** Excluir própria conta — qualquer usuário autenticado */
    @DeleteMapping("/minha-conta")
    public ResponseEntity<?> excluirMinhaConta() {
        org.springframework.security.core.Authentication auth =
            org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        usuarioService.excluirPropriaConta(email);
        return ResponseEntity.ok(Map.of("message", "Conta excluída com sucesso."));
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

    /** Solicitar código de reset (PÚBLICO) */
    @PostMapping("/esqueci-senha")
    public ResponseEntity<?> solicitarReset(@RequestBody Map<String, String> payload) {
        String email = payload.get("email");
        boolean sucesso = usuarioService.solicitarResetSenha(email);
        if (sucesso) {
            return ResponseEntity.ok(Map.of("message", "Um código de recuperação foi enviado para seu e-mail."));
        } else {
            return ResponseEntity.status(404).body(Map.of("message", "E-mail não encontrado no sistema."));
        }
    }

    /** Resetar senha com código (PÚBLICO) */
    @PostMapping("/resetar-senha")
    public ResponseEntity<?> resetarSenha(@RequestBody Map<String, String> payload) {
        String email = payload.get("email");
        String codigo = payload.get("codigo");
        String novaSenha = payload.get("novaSenha");
        
        boolean sucesso = usuarioService.resetarSenha(email, codigo, novaSenha);
        if (sucesso) {
            return ResponseEntity.ok(Map.of("message", "Senha alterada com sucesso!"));
        }
        return ResponseEntity.badRequest().body(Map.of("message", "Código inválido ou expirado."));
    }

    /** Ativar modo vitalício sem anúncios para o usuário autenticado */
    @PostMapping("/ativar-vitalicio")
    public ResponseEntity<?> ativarVitalicio() {
        org.springframework.security.core.Authentication auth =
            org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
            return ResponseEntity.status(401).body(Map.of("message", "Usuário precisa estar autenticado.", "sucesso", false));
        }
        String email = auth.getName();
        try {
            Usuario atualizado = usuarioService.ativarSemAnunciosVitalicio(email, true);
            atualizado.setSenha(null);
            return ResponseEntity.ok(Map.of(
                "message", "Acesso Vitalício Sem Anúncios ativado com sucesso!",
                "usuario", atualizado,
                "sucesso", true
            ));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(402).body(Map.of(
                "message", e.getMessage(),
                "sucesso", false
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "message", e.getMessage(),
                "sucesso", false
            ));
        }
    }
}
