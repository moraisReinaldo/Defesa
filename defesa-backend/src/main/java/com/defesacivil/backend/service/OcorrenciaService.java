package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Ocorrencia;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.OcorrenciaStatus;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.dto.OcorrenciaRequest;
import com.defesacivil.backend.repository.OcorrenciaRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class OcorrenciaService {

    @Autowired
    private OcorrenciaRepository ocorrenciaRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private FirebaseStorageService storageService;

    public Ocorrencia registrarOcorrencia(OcorrenciaRequest request) {
        // Validação de input
        if (request.getTipo() == null || request.getTipo().isBlank()) {
            throw new IllegalArgumentException("Tipo da ocorrência é obrigatório");
        }
        if (request.getDescricao() == null || request.getDescricao().isBlank()) {
            throw new IllegalArgumentException("Descrição é obrigatória");
        }

        Ocorrencia oc = new Ocorrencia();
        oc.setTipo(sanitizeInput(request.getTipo()));
        oc.setDescricao(sanitizeInput(request.getDescricao()));
        oc.setLatitude(request.getLatitude());
        oc.setLongitude(request.getLongitude());
        oc.setCidade(sanitizeInput(request.getCidade()));
        oc.setDataHora(request.getDataHora() != null ? request.getDataHora() : LocalDateTime.now().toString());
        oc.setUsuarioId(request.getUsuarioId());
        oc.setCriadoPorAgente(request.isCriadoPorAgente());

        // Se for Base64, subir para o Firebase Storage para economizar espaço no Firestore
        String foto = request.getCaminhoFoto();
        if (foto != null && foto.startsWith("data:image")) {
            String urlPublica = storageService.uploadBase64Image(foto, "ocorrencias");
            if (urlPublica != null) {
                oc.setCaminhoFoto(urlPublica);
            } else {
                oc.setCaminhoFoto(foto); // fallback se falhar
            }
        } else {
            oc.setCaminhoFoto(foto);
        }

        // Regra de Aprovação: Admins e Agentes são sempre aprovados
        boolean autoAprovado = oc.isCriadoPorAgente();
        
        if (oc.getUsuarioId() != null) {
            Optional<Usuario> criador = usuarioRepository.findById(oc.getUsuarioId());
            if (criador.isPresent()) {
                String role = criador.get().getRole();
                if (Role.ADMINISTRADOR.name().equals(role) || Role.AGENTE.name().equals(role)) {
                    autoAprovado = true;
                }
            }
        }

        if (autoAprovado) {
            oc.setStatus(OcorrenciaStatus.APROVADA.name());
        } else {
            oc.setStatus(OcorrenciaStatus.PENDENTE_APROVACAO.name());
            // Notificar todos os Administradores daquela cidade
            List<Usuario> admins = usuarioRepository.findByCidadeAndRole(oc.getCidade(), Role.ADMINISTRADOR.name());
            for (Usuario admin : admins) {
                notificationService.sendPushNotification(
                    admin.getFcmToken(), 
                    "Nova Ocorrência Pendente", 
                    "Uma nova ocorrência foi registrada em " + oc.getCidade() + " e aguarda sua aprovação."
                );
            }
        }

        return ocorrenciaRepository.save(oc);
    }

    public Ocorrencia aprovarOcorrencia(String id, String adminUserId) {
        // Verificação de role: apenas ADMINISTRADOR pode aprovar
        verificarRole(adminUserId, Role.ADMINISTRADOR, "Apenas administradores podem aprovar ocorrências");

        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc != null) {
            oc.setStatus(OcorrenciaStatus.APROVADA.name());
            Ocorrencia salva = ocorrenciaRepository.save(oc);
            
            // Notificar o munícipe que criou (se houver usuarioId)
            if (oc.getUsuarioId() != null) {
                usuarioRepository.findById(oc.getUsuarioId()).ifPresent(user -> {
                    notificationService.sendPushNotification(
                        user.getFcmToken(),
                        "Ocorrência Aprovada!",
                        "Sua ocorrência '" + oc.getTipo() + "' foi verificada e publicada."
                    );
                });
            }
            return salva;
        }
        return null;
    }

    public Ocorrencia registrarChegadaAgente(String id, String agenteUserId) {
        // Verificação de role: apenas AGENTE ou ADMINISTRADOR pode registrar chegada
        verificarRoleMultiple(agenteUserId, 
            List.of(Role.AGENTE, Role.ADMINISTRADOR), 
            "Apenas agentes podem registrar chegada no local");

        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc != null) {
            oc.setAgenteNoLocal(true);
            oc.setDataChegadaAgente(LocalDateTime.now().toString());
            oc.setStatus(OcorrenciaStatus.TRABALHANDO_ATUALMENTE.name());
            return ocorrenciaRepository.save(oc);
        }
        return null;
    }

    public List<Ocorrencia> buscarPorCidade(String cidade) {
        if (cidade == null || cidade.trim().isEmpty()) {
            return ocorrenciaRepository.findAll();
        }
        return ocorrenciaRepository.findByCidadeIgnoreCaseOrderByDataHoraDesc(cidade);
    }

    // ========== SEGURANÇA ==========

    private void verificarRole(String userId, Role roleRequerida, String mensagem) {
        if (userId == null || userId.isEmpty()) {
            // Se não há userId, permitir temporariamente (até JWT ser implementado)
            System.err.println("ALERTA SEGURANÇA: Requisição sem userId para endpoint protegido");
            return;
        }
        Optional<Usuario> usuario = usuarioRepository.findById(userId);
        if (usuario.isEmpty() || !roleRequerida.name().equals(usuario.get().getRole())) {
            throw new SecurityException(mensagem);
        }
    }

    private void verificarRoleMultiple(String userId, List<Role> rolesPermitidas, String mensagem) {
        if (userId == null || userId.isEmpty()) {
            System.err.println("ALERTA SEGURANÇA: Requisição sem userId para endpoint protegido");
            return;
        }
        Optional<Usuario> usuario = usuarioRepository.findById(userId);
        if (usuario.isEmpty() || !rolesPermitidas.stream().map(Enum::name).toList().contains(usuario.get().getRole())) {
            throw new SecurityException(mensagem);
        }
    }

    /** Sanitizar input para prevenir XSS/injection */
    private String sanitizeInput(String input) {
        if (input == null) return null;
        return input.replaceAll("<", "&lt;")
                    .replaceAll(">", "&gt;")
                    .replaceAll("\"", "&quot;")
                    .trim();
    }
}
