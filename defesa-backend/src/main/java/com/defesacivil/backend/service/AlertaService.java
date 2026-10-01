package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Alerta;
import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.dto.AlertaRequest;
import com.defesacivil.backend.repository.AlertaRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import com.defesacivil.backend.domain.enums.Status;
import com.defesacivil.backend.domain.Usuario;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AlertaService {

    private final AlertaRepository alertaRepository;
    private final CidadeService cidadeService;
    private final UsuarioRepository usuarioRepository;
    private final NotificationService notificationService;
    private final com.defesacivil.backend.repository.RotaEmergenciaRepository rotaEmergenciaRepository;

    public AlertaService(AlertaRepository alertaRepository, CidadeService cidadeService,
                         UsuarioRepository usuarioRepository, NotificationService notificationService,
                         com.defesacivil.backend.repository.RotaEmergenciaRepository rotaEmergenciaRepository) {
        this.alertaRepository = alertaRepository;
        this.cidadeService = cidadeService;
        this.usuarioRepository = usuarioRepository;
        this.notificationService = notificationService;
        this.rotaEmergenciaRepository = rotaEmergenciaRepository;
    }

    private String normalizarCodigoCidade(String cidade) {
        return cidadeService.normalizarCodigoCidade(cidade);
    }

    private String obterNomeCidade(String cidade) {
        return cidadeService.obterNomeCidade(cidade);
    }

    private String getAuthenticatedEmail() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return (auth != null && auth.isAuthenticated()) ? auth.getName() : null;
    }

    private boolean hasRole(String role) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_" + role));
    }

    private boolean hasAnyRole(String... roles) {
        for (String role : roles) {
            if (hasRole(role)) {
                return true;
            }
        }
        return false;
    }

    private void checkJurisdiction(String cidadeAlerta) {
        if (cidadeAlerta == null || cidadeAlerta.trim().isEmpty()) {
            return;
        }

        if (hasRole("SUPER_ADMIN")) {
            return;
        }

        if (hasAnyRole("ADMINISTRADOR", "AGENTE")) {
            String email = getAuthenticatedEmail();
            if (email == null) {
                throw new SecurityException("Acesso negado: Usuário não autenticado.");
            }

            Usuario usuario = usuarioRepository.findByEmail(email).orElse(null);
            if (usuario == null || usuario.getCidade() == null || usuario.getCidade().isBlank()) {
                throw new SecurityException("Acesso negado: Usuário sem cidade configurada.");
            }

            String cidadeUsuario = normalizarCodigoCidade(usuario.getCidade());
            String cidadeAlertaNormalizada = normalizarCodigoCidade(cidadeAlerta);
            if (cidadeUsuario != null && cidadeAlertaNormalizada != null
                && !cidadeUsuario.equalsIgnoreCase(cidadeAlertaNormalizada)) {
                throw new SecurityException("Acesso negado: Você só pode gerenciar alertas da sua própria cidade.");
            }
        }
    }

    public List<Alerta> buscarAlertasAtivos(String cidade) {
        if (cidade != null && !cidade.trim().isEmpty()) {
            String codigo = normalizarCodigoCidade(cidade);
            String nome = obterNomeCidade(cidade);
            return alertaRepository.findByCidadeFlexible(cidade.trim(), codigo, nome);
        }
        return alertaRepository.findByAtivoTrueOrderByDataCriacaoDesc();
    }

    public Alerta emitirAlerta(AlertaRequest request) {
        String cidade = normalizarCodigoCidade(request.getCidade());
        checkJurisdiction(cidade);

        if (request.getRotaEmergenciaId() != null && !request.getRotaEmergenciaId().isBlank()) {
            if (!hasRole("SUPER_ADMIN")) {
                cidadeService.buscarPorCodigo(cidade).ifPresent(c -> {
                    if (!c.isRecursoRotasEmergenciaLiberado()) {
                        throw new IllegalStateException("O recurso de vinculação de rotas requer o plano Gestão Municipal ou PRO Municipal.");
                    }
                });
            }
        }

        Alerta alerta = new Alerta(
            cidade,
            request.getTitulo(),
            request.getMensagem(),
            request.getNivel()
        );
        alerta.setRotaEmergenciaId(request.getRotaEmergenciaId());

        Alerta salvo = alertaRepository.save(alerta);

        // Se houver rota vinculada (ex: alerta EXTREMO), ativa a rota
        if (salvo.getRotaEmergenciaId() != null && !salvo.getRotaEmergenciaId().isBlank()) {
            rotaEmergenciaRepository.findById(salvo.getRotaEmergenciaId()).ifPresent(rota -> {
                rota.setAtiva(true);
                rota.setAlertaVinculadoId(salvo.getId());
                rotaEmergenciaRepository.save(rota);
            });
        }

        cidade = salvo.getCidade();
        List<String> destinatarios = usuarioRepository.findByCidadeIgnoreCaseAndStatus(cidade, Status.ATIVO.name())
            .stream()
            .map(Usuario::getId)
            .toList();
        notificationService.sendPushNotificationToUsers(
            destinatarios,
            "Alerta Defesa Civil: " + salvo.getTitulo(),
            salvo.getMensagem()
        );
        return salvo;
    }

    public void cancelarAlerta(String id) {
        alertaRepository.findById(id).ifPresent(alerta -> {
            checkJurisdiction(alerta.getCidade());
            alerta.setAtivo(false);
            alertaRepository.save(alerta);

            // Desativa a rota vinculada ao alerta se houver
            if (alerta.getRotaEmergenciaId() != null && !alerta.getRotaEmergenciaId().isBlank()) {
                rotaEmergenciaRepository.findById(alerta.getRotaEmergenciaId()).ifPresent(rota -> {
                    rota.setAtiva(false);
                    rotaEmergenciaRepository.save(rota);
                });
            }
        });
    }
}
