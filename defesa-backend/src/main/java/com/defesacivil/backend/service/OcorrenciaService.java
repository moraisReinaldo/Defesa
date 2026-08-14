package com.defesacivil.backend.service;

import com.defesacivil.backend.domain.Ocorrencia;
import com.defesacivil.backend.domain.Usuario;
import com.defesacivil.backend.domain.enums.OcorrenciaStatus;
import com.defesacivil.backend.domain.enums.Role;
import com.defesacivil.backend.dto.OcorrenciaRequest;
import com.defesacivil.backend.repository.OcorrenciaRepository;
import com.defesacivil.backend.repository.UsuarioRepository;
import com.defesacivil.backend.repository.CidadeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.data.domain.PageImpl;
import org.springframework.web.util.HtmlUtils;
import java.util.stream.Collectors;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class OcorrenciaService {

    private static final Logger log = LoggerFactory.getLogger(OcorrenciaService.class);

    private final OcorrenciaRepository ocorrenciaRepository;
    private final UsuarioRepository usuarioRepository;
    private final CidadeRepository cidadeRepository;
    private final NotificationService notificationService;
    private final MinioService minioService;

    public OcorrenciaService(OcorrenciaRepository ocorrenciaRepository,
                             UsuarioRepository usuarioRepository,
                             CidadeRepository cidadeRepository,
                             NotificationService notificationService,
                             MinioService minioService) {
        this.ocorrenciaRepository = ocorrenciaRepository;
        this.usuarioRepository = usuarioRepository;
        this.cidadeRepository = cidadeRepository;
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

    @Transactional(readOnly = true)
    public Ocorrencia buscarPorId(String id) {
        return ocorrenciaRepository.findById(id)
                .map(this::processarUrl)
                .orElse(null);
    }

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
        String cidade = normalizarCodigoCidade(request.getCidade());
        oc.setCidade(cidade);
        if (cidade != null) {
            cidadeRepository.findByCodigoIgnoreCase(cidade).ifPresent(oc::setCidadeEntidade);
        }
        oc.setDataHora(request.getDataHora() != null ? request.getDataHora() : LocalDateTime.now().toString());
        
        // CORRETO - Segurança (Backend Bug 4)
        String emailAutenticado = getAuthenticatedEmail();
        if (emailAutenticado != null && !"anonymousUser".equals(emailAutenticado)) {
            // Usuário autenticado: sempre usa o ID do JWT — nunca confia no body
            usuarioRepository.findByEmail(emailAutenticado).ifPresent(u -> {
                oc.setUsuarioId(u.getId());
                oc.setAutor(u);
                if (Role.ADMINISTRADOR.name().equals(u.getRole()) || Role.AGENTE.name().equals(u.getRole())) {
                    // REGRA DE NEGÓCIO: O admin só pode inserir ocorrências (do passado ou não) na sua própria cidade.
                    if (u.getCidade() != null && !u.getCidade().isBlank()) {
                        String cidAdmin = normalizarCodigoCidade(u.getCidade());
                        oc.setCidade(cidAdmin);
                        if (cidAdmin != null) {
                            cidadeRepository.findByCodigoIgnoreCase(cidAdmin).ifPresent(oc::setCidadeEntidade);
                        }
                    }
                }
            });
        } else {
            // Usuário anônimo (sem conta): não tem ID para associar
            oc.setUsuarioId(null);
            oc.setAutor(null);
        }

        oc.setCriadoPorAgente(request.isCriadoPorAgente());
        // Criador (agente/admin) já vem pré-escalado pelo app
        if (request.getAgentes() != null && !request.getAgentes().isBlank()) {
            oc.setAgentes(sanitizeInput(request.getAgentes()));
        }

        // Verifica se é uma ocorrência lançada no passado (dataHora foi fornecida)
        boolean isPassado = false;
        if (request.getDataHora() != null) {
            try {
                // Se a data informada for muito no passado (e.g. mais de 2 minutos atrás), 
                // consideramos como um registro passado (Data Customizada do Admin)
                LocalDateTime dt = LocalDateTime.parse(request.getDataHora());
                if (dt.isBefore(LocalDateTime.now().minusMinutes(2))) {
                    isPassado = true;
                }
            } catch (Exception e) {
                // Ignore
            }
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
            if (isPassado) {
                // REGRA DE NEGÓCIO: Se lançada no passado (data customizada), já entra como resolvida
                oc.setStatus(OcorrenciaStatus.RESOLVIDA.name());
                oc.setDataResolucao(LocalDateTime.now().toString()); // Pode ser a data do ocorrido também, mas manteremos today para timestamp do fechamento
                log.info("Ocorrência lançada no passado e automaticamente definida como RESOLVIDA.");
            } else {
                oc.setStatus(OcorrenciaStatus.APROVADA.name());
                log.info("Ocorrência criada com auto-aprovação para usuário com privilégios.");
            }
        } else {
            oc.setStatus(OcorrenciaStatus.PENDENTE_APROVACAO.name());
            // Notificar admins da cidade
            List<Usuario> admins = usuarioRepository.findByCidadeAndRole(oc.getCidade(), Role.ADMINISTRADOR.name());
            for (Usuario admin : admins) {
                notificationService.sendPushNotification(
                    admin.getId(),
                    "Nova Ocorrência Pendente",
                    "Uma nova ocorrência aguarda aprovação em " + oc.getCidade() + "."
                );
            }
        }

        return processarUrl(ocorrenciaRepository.save(oc));
    }

    /** Aprovar — SecurityConfig já garante que apenas ADMINISTRADOR chega aqui */
    public Ocorrencia aprovarOcorrencia(String id) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc == null) return null;
        checkJurisdiction(oc.getCidade());

        oc.setStatus(OcorrenciaStatus.APROVADA.name());
        Ocorrencia salva = ocorrenciaRepository.save(oc);

        if (oc.getUsuarioId() != null) {
            usuarioRepository.findById(oc.getUsuarioId()).ifPresent(user ->
                notificationService.sendPushNotification(
                    user.getId(),
                    "Ocorrência Aprovada",
                    "Sua ocorrência '" + oc.getTipo() + "' foi verificada e publicada."
                )
            );
        }

        return processarUrl(salva);
    }

    /** Registrar chegada — SecurityConfig garante AGENTE ou ADMINISTRADOR */
    public Ocorrencia registrarChegadaAgente(String id, String parecer) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc == null) return null;
        checkJurisdiction(oc.getCidade());

        oc.setAgenteNoLocal(true);
        oc.setDataChegadaAgente(LocalDateTime.now().toString());
        oc.setStatus(OcorrenciaStatus.TRABALHANDO_ATUALMENTE.name());

        if (parecer != null && !parecer.isBlank()) {
            oc.setDescricaoSituacao(sanitizeInput(parecer));
        }

        return processarUrl(ocorrenciaRepository.save(oc));
    }

    /** Resolver ocorrência — SecurityConfig garante AGENTE ou ADMINISTRADOR */
    public Ocorrencia resolverOcorrencia(String id, String parecer) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc == null) return null;
        checkJurisdiction(oc.getCidade());

        oc.setStatus(OcorrenciaStatus.RESOLVIDA.name());
        oc.setDataResolucao(LocalDateTime.now().toString());

        if (parecer != null && !parecer.isBlank()) {
            oc.setDescricaoSituacao(sanitizeInput(parecer));
        }

        Ocorrencia salva = ocorrenciaRepository.save(oc);

        if (oc.getUsuarioId() != null) {
            usuarioRepository.findById(oc.getUsuarioId()).ifPresent(user ->
                notificationService.sendPushNotification(
                    user.getId(),
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
        checkJurisdiction(oc.getCidade());

        oc.setStatus(OcorrenciaStatus.APROVADA.name());
        oc.setDataResolucao(null);
        return processarUrl(ocorrenciaRepository.save(oc));
    }

    /** Deletar — SecurityConfig garante ADMINISTRADOR */
    public boolean deletarOcorrencia(String id) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc == null) return false;
        checkJurisdiction(oc.getCidade());
        ocorrenciaRepository.deleteById(id);
        return true;
    }

    public String normalizarCodigoCidade(String cidade) {
        if (cidade == null || cidade.isBlank()) return null;
        String limpa = cidade.trim().toUpperCase();
        return cidadeRepository.findByCodigoIgnoreCase(limpa)
            .or(() -> cidadeRepository.findByNomeIgnoreCase(limpa))
            .map(com.defesacivil.backend.domain.Cidade::getCodigo)
            .orElse(limpa);
    }

    private void checkJurisdiction(String cidadeOcorrencia) {
        if (cidadeOcorrencia == null || cidadeOcorrencia.trim().isEmpty()) return;
        if (hasAnyRole("ADMINISTRADOR", "AGENTE")) {
            String email = getAuthenticatedEmail();
            if (email != null) {
                Usuario user = usuarioRepository.findByEmail(email).orElse(null);
                if (user != null && user.getCidade() != null && !user.getCidade().trim().isEmpty()) {
                    String userCity = normalizarCodigoCidade(user.getCidade());
                    String ocCity = normalizarCodigoCidade(cidadeOcorrencia);
                    if (userCity != null && ocCity != null && !userCity.equalsIgnoreCase(ocCity)) {
                        throw new SecurityException("Acesso negado: Você só pode gerenciar itens de sua própria cidade.");
                    }
                }
            }
        }
    }

    public Ocorrencia atualizarOcorrencia(String id, OcorrenciaRequest request) {
        Ocorrencia oc = ocorrenciaRepository.findById(id).orElse(null);
        if (oc == null) return null;
        
        checkJurisdiction(oc.getCidade());
        
        if (!hasAnyRole("ADMINISTRADOR", "AGENTE")) {
            String email = getAuthenticatedEmail();
            if (email == null) {
                throw new SecurityException("Acesso negado: Usuário não autenticado.");
            }
            Usuario currentUser = usuarioRepository.findByEmail(email).orElse(null);
            if (currentUser == null || oc.getUsuarioId() == null || !oc.getUsuarioId().equals(currentUser.getId())) {
                throw new SecurityException("Acesso negado: Você só pode editar suas próprias ocorrências.");
            }
        }

        if (request.getTipo() != null) oc.setTipo(sanitizeInput(request.getTipo()));
        if (request.getDescricao() != null) oc.setDescricao(sanitizeInput(request.getDescricao()));
        
        // CORRETO - Prevenção de NPE (Backend Bug 3)
        if (request.getLatitude() != null && request.getLatitude() != 0) oc.setLatitude(request.getLatitude());
        if (request.getLongitude() != null && request.getLongitude() != 0) oc.setLongitude(request.getLongitude());
        
        if (request.getAgentes() != null) oc.setAgentes(request.getAgentes());
        if (request.getStatus() != null) oc.setStatus(request.getStatus().toUpperCase());
        if (request.getCidade() != null) {
            String cidadeEditada = normalizarCodigoCidade(request.getCidade());
            oc.setCidade(cidadeEditada);
            if (cidadeEditada != null) {
                cidadeRepository.findByCodigoIgnoreCase(cidadeEditada).ifPresent(oc::setCidadeEntidade);
            }
        }
        if (request.getDescricaoSituacao() != null) oc.setDescricaoSituacao(sanitizeInput(request.getDescricaoSituacao()));

        return processarUrl(ocorrenciaRepository.save(oc));
    }

    @Transactional(readOnly = true)
    public Page<Ocorrencia> buscarPorCidade(String cidade, Pageable pageable) {
        boolean admin = hasRole("ADMINISTRADOR");
        boolean agente = hasRole("AGENTE");

        String cidadeUsuario = null;
        String currentUserId = null;

        if (isAuthenticated()) {
            String email = getAuthenticatedEmail();
            if (email != null) {
                Optional<Usuario> usuario = usuarioRepository.findByEmail(email);
                if (usuario.isPresent()) {
                    cidadeUsuario = normalizarCodigoCidade(usuario.get().getCidade());
                    currentUserId = usuario.get().getId();
                }
            }
        }

        // Se for admin ou agente, DEVE ver apenas da própria cidade
        if (admin || agente) {
            String cidadeParaBuscar = (cidadeUsuario != null && !cidadeUsuario.trim().isEmpty()) 
                    ? cidadeUsuario 
                    : normalizarCodigoCidade(cidade);
            if (cidadeParaBuscar == null || cidadeParaBuscar.trim().isEmpty()) {
                return processarUrls(ocorrenciaRepository.findAll(pageable));
            }
            return processarUrls(ocorrenciaRepository.findByCidadeIgnoreCaseOrderByDataHoraDesc(cidadeParaBuscar, pageable));
        }

        // CIDADÃO / ANÔNIMO: vê aprovadas da cidade solicitada (ou todas se cidade for null) + suas próprias (qualquer status)
        String cidFiltro = normalizarCodigoCidade(cidade);
        return processarUrls(ocorrenciaRepository.findPublicByCidadeOrCreator(cidFiltro, currentUserId, pageable));
    }

    // ========== HELPERS INTERNOS ==========

    private Ocorrencia processarUrl(Ocorrencia oc) {
        if (oc == null) return null;
        
        // Criamos uma cópia para não correr risco de o Hibernate salvar a URL assinada no banco
        Ocorrencia copia = new Ocorrencia();
        copia.setId(oc.getId());
        copia.setTipo(oc.getTipo());
        copia.setDescricao(oc.getDescricao());
        copia.setLatitude(oc.getLatitude());
        copia.setLongitude(oc.getLongitude());
        copia.setCidade(oc.getCidade());
        copia.setDataHora(oc.getDataHora());
        copia.setStatus(oc.getStatus());
        copia.setUsuarioId(oc.getUsuarioId());
        copia.setAgentes(oc.getAgentes());
        copia.setAgenteNoLocal(oc.isAgenteNoLocal());
        copia.setDataChegadaAgente(oc.getDataChegadaAgente());
        copia.setDataResolucao(oc.getDataResolucao());
        copia.setCriadoPorAgente(oc.isCriadoPorAgente());
        copia.setDescricaoSituacao(oc.getDescricaoSituacao());
        copia.setCidadeEntidade(oc.getCidadeEntidade());
        copia.setAutor(oc.getAutor());
        copia.setAgentesAtribuidos(oc.getAgentesAtribuidos());
        
        String foto = oc.getCaminhoFoto();
        if (foto == null || foto.isBlank()) {
            copia.setCaminhoFoto(null);
            return copia;
        }
        
        if (foto.startsWith("data:") || foto.startsWith("http")) {
            copia.setCaminhoFoto(foto);
            return copia;
        }
        
        try {
            copia.setCaminhoFoto(minioService.getPresignedUrl(foto));
        } catch (Exception e) {
            log.warn("❌ Erro ao gerar URL do MinIO para {}: {}", foto, e.getMessage());
            copia.setCaminhoFoto(foto);
        }
        
        return copia;
    }

    // CORRETO - (Backend Bug 2)
    private Page<Ocorrencia> processarUrls(Page<Ocorrencia> page) {
        log.info("📦 Processando URLs para {} ocorrências encontradas.", page.getNumberOfElements());
        List<Ocorrencia> processadas = page.getContent()
                .stream()
                .map(this::processarUrl)
                .collect(Collectors.toList());
        return new PageImpl<>(
                processadas,
                page.getPageable(),
                page.getTotalElements()
        );
    }

    private String sanitizeInput(String input) {
        if (input == null) return null;
        return HtmlUtils.htmlEscape(input.trim());
    }
}
