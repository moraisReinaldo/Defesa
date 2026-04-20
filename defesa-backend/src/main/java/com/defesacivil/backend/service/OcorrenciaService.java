package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Ocorrencia;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.OcorrenciaStatus;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.dto.OcorrenciaRequest;
import com.defesacivil.backend.repository.OcorrenciaRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class OcorrenciaService {

    private static final Logger log = LoggerFactory.getLogger(OcorrenciaService.class);

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

    // ========== HELPERS DE SEGURANÇA ==========

    /**
     * Extrai o email do usuário autenticado a partir do JWT no SecurityContext.
     * Nunca confia em parâmetros externos como X-User-Id.
     */
    private String getAuthenticatedEmail() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return (auth != null && auth.isAuthenticated()) ? auth.getName() : null;
    }

    private boolean isAuthenticated() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getName());
    }

    private boolean hasRole(String role) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals("ROLE_" + role));
    }

    private boolean hasAnyRole(String... roles) {
        for (String role : roles) {
            if (hasRole(role)) return true;
        }
        return false;
    }

    // ========== OPERAÇÕES ==========

    public Ocorrencia registrarOcorrencia(OcorrenciaRequest request) {
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
        // Criador (agente/admin) já vem pré-escalado pelo app
        if (request.getAgentes() != null && !request.getAgentes().isBlank()) {
            oc.setAgentes(sanitizeInput(request.getAgentes()));
        }

        // Upload de foto Base64 para MinIO
        String foto = request.getCaminhoFoto();
        if (foto != null && foto.startsWith("data:image")) {
            String objectKey = minioService.uploadBase64Image(foto, "ocorrencias");
            oc.setCaminhoFoto(objectKey != null ? objectKey : foto);
        } else {
            oc.setCaminhoFoto(foto);
        }

        // Regra de auto-aprovação: Admins e Agentes são sempre aprovados automaticamente
        boolean autoAprovado = oc.isCriadoPorAgente() || hasAnyRole("ADMINISTRADOR", "AGENTE");

        // Fallback: verificar pelo usuarioId no banco se a flag não veio do app
        if (!autoAprovado && oc.getUsuarioId() != null) {
            Optional<Usuario> criador = usuarioRepository.findById(oc.getUsuarioId());
            if (criador.isPresent()) {
                String role = criador.get().getRole();
                autoAprovado = Role.ADMINISTRADOR.name().equals(role) || Role.AGENTE.name().equals(role);
            }
        }

        if (autoAprovado) {
            oc.setStatus(OcorrenciaStatus.APROVADA.name());
            log.info("Ocorrência criada com auto-aprovação para usuário com privilégios.");
        } else {
            oc.setStatus(OcorrenciaStatus.PENDENTE_APROVACAO.name());
            // Notificar admins da cidade
            List<Usuario> admins = usuarioRepository.findByCidadeAndRole(oc.getCidade(), Role.ADMINISTRADOR.name());
            for (Usuario admin : admins) {
                notificationService.sendPushNotification(
                    admin.getFcmToken(),
                    "Nova Ocorrência Pendente",
                    "Uma nova ocorrência aguarda aprovação em " + oc.getCidade() + "."
                );
            }
        }

        return ocorrenciaRepository.save(oc);
    }

    /** Aprovar — SecurityConfig já garante que apenas ADMINISTRADOR chega aqui */
    public Ocorrencia aprovarOcorrencia(String id) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc == null) return null;

        oc.setStatus(OcorrenciaStatus.APROVADA.name());
        Ocorrencia salva = ocorrenciaRepository.save(oc);

        if (oc.getUsuarioId() != null) {
            usuarioRepository.findById(oc.getUsuarioId()).ifPresent(user ->
                notificationService.sendPushNotification(
                    user.getFcmToken(),
                    "Ocorrência Aprovada!",
                    "Sua ocorrência '" + oc.getTipo() + "' foi verificada e publicada."
                )
            );
        }

        return salva;
    }

    /** Registrar chegada — SecurityConfig garante AGENTE ou ADMINISTRADOR */
    public Ocorrencia registrarChegadaAgente(String id, String parecer) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc == null) return null;

        oc.setAgenteNoLocal(true);
        oc.setDataChegadaAgente(LocalDateTime.now().toString());
        oc.setStatus(OcorrenciaStatus.TRABALHANDO_ATUALMENTE.name());

        if (parecer != null && !parecer.isBlank()) {
            oc.setDescricaoSituacao(sanitizeInput(parecer));
        }

        return ocorrenciaRepository.save(oc);
    }

    /** Resolver ocorrência — SecurityConfig garante AGENTE ou ADMINISTRADOR */
    public Ocorrencia resolverOcorrencia(String id, String parecer) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc == null) return null;

        oc.setStatus(OcorrenciaStatus.RESOLVIDA.name());
        oc.setDataResolucao(LocalDateTime.now().toString());

        if (parecer != null && !parecer.isBlank()) {
            oc.setDescricaoSituacao(sanitizeInput(parecer));
        }

        Ocorrencia salva = ocorrenciaRepository.save(oc);

        if (oc.getUsuarioId() != null) {
            usuarioRepository.findById(oc.getUsuarioId()).ifPresent(user ->
                notificationService.sendPushNotification(
                    user.getFcmToken(),
                    "Caso Resolvido!",
                    "A ocorrência em " + oc.getCidade() + " foi marcada como resolvida."
                )
            );
        }

        return processarUrl(salva);
    }

    /** Reativar — SecurityConfig garante AGENTE ou ADMINISTRADOR */
    public Ocorrencia reativarOcorrencia(String id) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc == null) return null;

        oc.setStatus(OcorrenciaStatus.APROVADA.name());
        oc.setDataResolucao(null);
        return ocorrenciaRepository.save(oc);
    }

    /** Deletar — SecurityConfig garante ADMINISTRADOR */
    public boolean deletarOcorrencia(String id) {
        if (!ocorrenciaRepository.existsById(id)) return false;
        ocorrenciaRepository.deleteById(id);
        return true;
    }

    public Ocorrencia atualizarOcorrencia(String id, OcorrenciaRequest request) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc == null) return null;

        if (request.getTipo() != null) oc.setTipo(sanitizeInput(request.getTipo()));
        if (request.getDescricao() != null) oc.setDescricao(sanitizeInput(request.getDescricao()));
        if (request.getLatitude() != 0) oc.setLatitude(request.getLatitude());
        if (request.getLongitude() != 0) oc.setLongitude(request.getLongitude());
        if (request.getAgentes() != null) oc.setAgentes(request.getAgentes());
        if (request.getStatus() != null) oc.setStatus(request.getStatus().toUpperCase());
        if (request.getCidade() != null) oc.setCidade(sanitizeInput(request.getCidade()));
        if (request.getDescricaoSituacao() != null) oc.setDescricaoSituacao(sanitizeInput(request.getDescricaoSituacao()));

        return ocorrenciaRepository.save(oc);
    }

    @Transactional(readOnly = true)
    public Page<Ocorrencia> buscarPorCidade(String cidade, Pageable pageable) {
        boolean admin = hasRole("ADMINISTRADOR");
        boolean agente = hasRole("AGENTE");

        // Resolver cidade do usuário autenticado se não informada
        if ((cidade == null || cidade.trim().isEmpty()) && isAuthenticated()) {
            String email = getAuthenticatedEmail();
            if (email != null) {
                Optional<Usuario> usuario = usuarioRepository.findByEmail(email);
                if (usuario.isPresent() && usuario.get().getCidade() != null) {
                    cidade = usuario.get().getCidade();
                }
            }
        }

        // ADMIN vê tudo na cidade (ou tudo se não filtrou)
        if (admin) {
            if (cidade == null || cidade.trim().isEmpty()) {
                return processarUrls(ocorrenciaRepository.findAll(pageable));
            }
            return processarUrls(ocorrenciaRepository.findByCidadeIgnoreCaseOrderByDataHoraDesc(cidade, pageable));
        }

        // AGENTE vê tudo na sua cidade (incluindo pendentes)
        if (agente && cidade != null) {
            return processarUrls(ocorrenciaRepository.findByCidadeIgnoreCaseOrderByDataHoraDesc(cidade, pageable));
        }

        // CIDADÃO: vê aprovadas da cidade + suas próprias (qualquer status)
        String currentUserId = null;
        String email = getAuthenticatedEmail();
        if (email != null) {
            Optional<Usuario> u = usuarioRepository.findByEmail(email);
            if (u.isPresent()) currentUserId = u.get().getId();
        }

        return processarUrls(ocorrenciaRepository.findPublicByCidadeOrCreator(cidade, currentUserId, pageable));
    }

    // ========== HELPERS INTERNOS ==========

    private Ocorrencia processarUrl(Ocorrencia oc) {
        if (oc == null) return null;
        
        String foto = oc.getCaminhoFoto();
        if (foto == null || foto.isBlank()) {
            log.info("ℹ️ Ocorrência {}: Sem foto para processar.", oc.getId());
            return oc;
        }
        
        // Se for Base64 (data:image) ou já for uma URL absoluta (http), não mexe
        if (foto.startsWith("data:") || foto.startsWith("http")) {
            log.info("📸 Ocorrência {}: Foto em Base64 ou URL absoluta. Tamanho: {} chars.", oc.getId(), foto.length());
            return oc;
        }
        
        // Só gera URL assinada do MinIO se for um caminho de objeto (ex: ocorrencias/uuid.jpg)
        try {
            String urlAssinada = minioService.getPresignedUrl(foto);
            log.info("🔗 Ocorrência {}: URL Gerada -> {}", oc.getId(), urlAssinada);
            oc.setCaminhoFoto(urlAssinada);
        } catch (Exception e) {
            log.warn("❌ Ocorrência {}: Erro ao gerar URL do MinIO para {}: {}", oc.getId(), foto, e.getMessage());
        }
        
        return oc;
    }

    private Page<Ocorrencia> processarUrls(Page<Ocorrencia> page) {
        log.info("📦 Processando URLs para {} ocorrências encontradas.", page.getNumberOfElements());
        page.getContent().forEach(this::processarUrl);
        return page;
    }

    private String sanitizeInput(String input) {
        if (input == null) return null;
        return input.replaceAll("<", "&lt;")
                    .replaceAll(">", "&gt;")
                    .replaceAll("\"", "&quot;")
                    .trim();
    }
}
