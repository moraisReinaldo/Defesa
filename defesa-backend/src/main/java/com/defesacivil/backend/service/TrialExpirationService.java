package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.StatusCidade;
import com.defesacivil.backend.repository.CidadeRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class TrialExpirationService {

    private static final Logger log = LoggerFactory.getLogger(TrialExpirationService.class);

    private final CidadeRepository cidadeRepository;
    private final UsuarioRepository usuarioRepository;
    private final PontoInteresseService pontoInteresseService;
    private final NotificationService notificationService;

    public TrialExpirationService(CidadeRepository cidadeRepository, UsuarioRepository usuarioRepository,
                                  PontoInteresseService pontoInteresseService,
                                  NotificationService notificationService) {
        this.cidadeRepository = cidadeRepository;
        this.usuarioRepository = usuarioRepository;
        this.pontoInteresseService = pontoInteresseService;
        this.notificationService = notificationService;
    }

    @Scheduled(fixedDelayString = "${app.trial.expiration-check-ms:3600000}")
    @Transactional
    public void expirarTrialsVencidos() {
        LocalDateTime agora = LocalDateTime.now();
        for (Cidade cidade : cidadeRepository.findByStatus(StatusCidade.TRIAL_ATIVO)) {
            if (cidade.getTrialFim() == null || cidade.getTrialFim().isAfter(agora)) {
                continue;
            }

            log.warn("[TrialExpirationService] Trial expirado para cidade: {} ({}). Data fim: {}",
                    cidade.getNome(), cidade.getCodigo(), cidade.getTrialFim());

            cidade.setStatus(StatusCidade.EXPIRADO);
            cidadeRepository.save(cidade);
            pontoInteresseService.marcarIndisponiveisDaCidade(cidade.getCodigo());

            List<Usuario> usuarios = usuarioRepository.findByCidadeIgnoreCase(cidade.getCodigo());
            for (Usuario usuario : usuarios) {
                if ("ADMINISTRADOR".equals(usuario.getRole())) {
                    if (Boolean.TRUE.equals(usuario.getAdministradorTitular())) {
                        log.info("[TrialExpirationService] Notificando administrador titular {} sobre expiração do trial.", usuario.getEmail());
                        notificationService.sendPushNotification(usuario.getId(),
                                "Período de Testes Expirado",
                                "O período de degustação (trial) de 120 dias do município de " + cidade.getNome() + " expirou. Entre em contato para ativar o Plano PRO Municipal.");
                    } else {
                        usuario.setRole("CIDADAO");
                        usuario.setStatus("ATIVO");
                        usuarioRepository.save(usuario);
                        log.info("[TrialExpirationService] Administrador adicional {} rebaixado para CIDADAO.", usuario.getEmail());
                    }
                } else if ("AGENTE".equals(usuario.getRole())) {
                    usuario.setRole("CIDADAO");
                    usuario.setStatus("ATIVO");
                    usuarioRepository.save(usuario);
                    log.info("[TrialExpirationService] Agente {} rebaixado para CIDADAO.", usuario.getEmail());
                }
            }
        }
    }
}
