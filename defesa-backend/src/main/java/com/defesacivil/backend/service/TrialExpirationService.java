package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.StatusCidade;
import com.defesacivil.backend.repository.CidadeRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class TrialExpirationService {

    private final CidadeRepository cidadeRepository;
    private final UsuarioRepository usuarioRepository;

    public TrialExpirationService(CidadeRepository cidadeRepository, UsuarioRepository usuarioRepository) {
        this.cidadeRepository = cidadeRepository;
        this.usuarioRepository = usuarioRepository;
    }

    @Scheduled(fixedDelayString = "${app.trial.expiration-check-ms:3600000}")
    @Transactional
    public void expirarTrialsVencidos() {
        LocalDateTime agora = LocalDateTime.now();
        for (Cidade cidade : cidadeRepository.findByStatus(StatusCidade.TRIAL_ATIVO)) {
            if (cidade.getTrialFim() == null || cidade.getTrialFim().isAfter(agora)) {
                continue;
            }

            cidade.setStatus(StatusCidade.EXPIRADO);
            cidadeRepository.save(cidade);

            List<Usuario> usuarios = usuarioRepository.findByCidadeIgnoreCase(cidade.getCodigo());
            for (Usuario usuario : usuarios) {
                if ("ADMINISTRADOR".equals(usuario.getRole()) || "AGENTE".equals(usuario.getRole())) {
                    usuario.setStatus("BLOQUEADO");
                    usuarioRepository.save(usuario);
                }
            }
        }
    }
}
