package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Ocorrencia;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.OcorrenciaStatus;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.dto.OcorrenciaRequest;
import com.defesacivil.backend.repository.OcorrenciaRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class OcorrenciaService {

    private final OcorrenciaRepository ocorrenciaRepository;
    private final UsuarioRepository usuarioRepository;
    private final NotificationService notificationService;
    private final MinioService minioService;

    public OcorrenciaService(OcorrenciaRepository ocorrenciaRepository,
                             UsuarioRepository usuarioRepository,
                             NotificationService notificationService,
                             MinioService minioService) {
        this.ocorrenciaRepository = ocorrenciaRepository;
        this.usuarioRepository = usuarioRepository;
        this.notificationService = notificationService;
        this.minioService = minioService;
    }

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

        // Se for Base64, subir para o MinIO para não salvar tudo no banco
        String foto = request.getCaminhoFoto();
        if (foto != null && foto.startsWith("data:image")) {
            String objectKey = minioService.uploadBase64Image(foto, "ocorrencias");
            if (objectKey != null) {
                oc.setCaminhoFoto(objectKey);
            } else {
                oc.setCaminhoFoto(foto); // fallback se falhar
            }
        } else {
            oc.setCaminhoFoto(foto);
        }

        // Regra de Aprovação: Admins e Agentes são sempre aprovados
        boolean autoAprovado = oc.isCriadoPorAgente();
        
        // Short-circuit: se já sabemos que é agente, não precisa buscar no banco
        if (!autoAprovado && oc.getUsuarioId() != null) {
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

    public Ocorrencia registrarChegadaAgente(String id, String agenteUserId, String parecer) {
        // Verificação de role: apenas AGENTE ou ADMINISTRADOR pode registrar chegada
        verificarRoleMultiple(agenteUserId, 
            List.of(Role.AGENTE, Role.ADMINISTRADOR), 
            "Apenas agentes ou administradores podem registrar chegada no local");

        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc != null) {
            oc.setAgenteNoLocal(true);
            oc.setDataChegadaAgente(LocalDateTime.now().toString());
            oc.setStatus(OcorrenciaStatus.TRABALHANDO_ATUALMENTE.name());
            if (parecer != null && !parecer.isBlank()) {
                oc.setDescricaoSituacao(sanitizeInput(parecer));
            }
            return ocorrenciaRepository.save(oc);
        }
        return null;
    }

    public Ocorrencia resolverOcorrencia(String id, String userId, String parecer) {
        // Verificação de role: apenas AGENTE ou ADMINISTRADOR pode resolver
        verificarRoleMultiple(userId, 
            List.of(Role.AGENTE, Role.ADMINISTRADOR), 
            "Apenas agentes ou administradores podem resolver ocorrências");

        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc != null) {
            oc.setStatus(OcorrenciaStatus.RESOLVIDA.name());
            oc.setDataResolucao(LocalDateTime.now().toString());
            if (parecer != null && !parecer.isBlank()) {
                oc.setDescricaoSituacao(sanitizeInput(parecer));
            }
            
            Ocorrencia salva = ocorrenciaRepository.save(oc);
            
            // Notificar o munícipe
            if (oc.getUsuarioId() != null) {
                usuarioRepository.findById(oc.getUsuarioId()).ifPresent(user -> {
                    notificationService.sendPushNotification(
                        user.getFcmToken(),
                        "Caso Resolvido!",
                        "A ocorrência em " + oc.getCidade() + " foi marcada como resolvida."
                    );
                });
            }
            
            return salva;
        }
        return null;
    }

    public Ocorrencia reativarOcorrencia(String id, String userId) {
        // Verificação de role: apenas AGENTE ou ADMINISTRADOR pode reativar
        verificarRoleMultiple(userId,
            List.of(Role.AGENTE, Role.ADMINISTRADOR),
            "Apenas agentes ou administradores podem reativar ocorrências");

        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc != null) {
            oc.setStatus(OcorrenciaStatus.APROVADA.name());
            oc.setDataResolucao(null);
            return ocorrenciaRepository.save(oc);
        }
        return null;
    }

    public boolean deletarOcorrencia(String id, String userId) {
        // Verificação de role: apenas ADMINISTRADOR pode deletar
        verificarRole(userId, Role.ADMINISTRADOR, "Apenas administradores podem deletar ocorrências");

        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc != null && oc.getId() != null) {
            ocorrenciaRepository.deleteById(oc.getId());
            return true;
        }
        return false;
    }

    public Ocorrencia atualizarOcorrencia(String id, OcorrenciaRequest request) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc != null) {
            if (request.getTipo() != null) oc.setTipo(sanitizeInput(request.getTipo()));
            if (request.getDescricao() != null) oc.setDescricao(sanitizeInput(request.getDescricao()));
            if (request.getLatitude() != 0) oc.setLatitude(request.getLatitude());
            if (request.getLongitude() != 0) oc.setLongitude(request.getLongitude());
            if (request.getAgentes() != null) oc.setAgentes(request.getAgentes());
            if (request.getStatus() != null) oc.setStatus(request.getStatus().toUpperCase());
            if (request.getCidade() != null) oc.setCidade(sanitizeInput(request.getCidade()));
            
            return ocorrenciaRepository.save(oc);
        }
        return null;
    }

    @Transactional(readOnly = true)
    public List<Ocorrencia> buscarPorCidade(String cidade) {
        // Enforçar filtro por cidade para usuários não-administrativos via SecurityContext
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        
        List<Ocorrencia> result;

        if (auth != null && auth.isAuthenticated() && !auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMINISTRADOR"))) {
            // Se for um cidadão ou agente autenticado, buscar os dados dele para saber a cidade real
            Optional<Usuario> usuario = usuarioRepository.findByEmail(auth.getName());
            if (usuario.isPresent()) {
                String cidadeUsuario = usuario.get().getCidade();
                if (cidadeUsuario != null && !cidadeUsuario.isBlank()) {
                    result = ocorrenciaRepository.findByCidadeIgnoreCaseOrderByDataHoraDesc(cidadeUsuario);
                    return processarUrls(result);
                }
            }
        }

        if (cidade == null || cidade.trim().isEmpty()) {
            result = ocorrenciaRepository.findAll();
        } else {
            result = ocorrenciaRepository.findByCidadeIgnoreCaseOrderByDataHoraDesc(cidade);
        }
        return processarUrls(result);
    }

    private List<Ocorrencia> processarUrls(List<Ocorrencia> ocorrencias) {
        // Substitui a key do objeto pela Presigned URL gerada na hora (valida por 1h)
        for (Ocorrencia oc : ocorrencias) {
            if (oc.getCaminhoFoto() != null && !oc.getCaminhoFoto().startsWith("http")) {
                oc.setCaminhoFoto(minioService.getPresignedUrl(oc.getCaminhoFoto()));
            }
        }
        return ocorrencias;
    }

    // ========== SEGURANÇA ==========

    private void verificarRole(String userId, Role roleRequerida, String mensagem) {
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            throw new SecurityException("Acesso negado: Usuário não autenticado");
        }
        
        boolean hasRole = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_" + roleRequerida.name()));
        
        if (!hasRole) {
            throw new SecurityException(mensagem);
        }
    }

    private void verificarRoleMultiple(String userId, List<Role> rolesPermitidas, String mensagem) {
        org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            throw new SecurityException("Acesso negado: Usuário não autenticado");
        }

        boolean hasAnyRole = auth.getAuthorities().stream()
                .anyMatch(a -> rolesPermitidas.stream()
                        .anyMatch(role -> a.getAuthority().equals("ROLE_" + role.name())));

        if (!hasAnyRole) {
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
