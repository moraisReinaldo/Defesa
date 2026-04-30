package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.AlertaClima;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.repository.AlertaClimaRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class AlertaClimaService {

    private final AlertaClimaRepository alertaClimaRepository;
    private final UsuarioRepository usuarioRepository;
    private final NotificationService notificationService;

    public AlertaClimaService(AlertaClimaRepository alertaClimaRepository,
                              UsuarioRepository usuarioRepository,
                              NotificationService notificationService) {
        this.alertaClimaRepository = alertaClimaRepository;
        this.usuarioRepository = usuarioRepository;
        this.notificationService = notificationService;
    }

    public AlertaClima criarAlerta(AlertaClima alerta) {
        AlertaClima salvo = alertaClimaRepository.save(alerta);

        // Disparar Push Notification para todos os usuários daquela cidade
        List<Usuario> moradores = usuarioRepository.findByCidadeAndRole(alerta.getCidade(), "CIDADAO");
        moradores.addAll(usuarioRepository.findByCidadeAndRole(alerta.getCidade(), "AGENTE"));
        
        String titulo = "Alerta: Risco " + alerta.getGravidade();
        for (Usuario user : moradores) {
            notificationService.sendPushNotification(user.getId(), titulo, alerta.getMensagem());
        }

        return salvo;
    }

    public List<AlertaClima> getAlertasAtivos(String cidade) {
        return alertaClimaRepository.findAlertasAtivosPorCidade(cidade, LocalDateTime.now());
    }

    public void deletarAlerta(String id) {
        alertaClimaRepository.deleteById(id);
    }
}
