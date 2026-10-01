package com.defesacivil.backend.service;

import com.defesacivil.backend.config.GeminiConfig;
import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.domain.Ocorrencia;
import com.defesacivil.backend.domain.enums.PlanoCidade;
import com.defesacivil.backend.dto.SugestaoIaDto;
import com.defesacivil.backend.repository.OcorrenciaRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Base64;
import java.util.concurrent.TimeUnit;

/**
 * Serviço de Inteligência Artificial para posicionamento de ocorrências.
 *
 * Regras de plano:
 *  - PRO_MUNICIPAL  → IA completa (Gemini multimodal: texto + foto)
 *  - Outros planos  → sem IA; retorna centroide PostGIS com flag iaSemPlano=true
 *
 * Falhas de API (quota, chave inválida, timeout) geram log + notificação ao admin
 * e retornam fallback seguro sem quebrar o fluxo de aprovação.
 */
@Service
public class OcorrenciaIaService {

    private static final Logger log = LoggerFactory.getLogger(OcorrenciaIaService.class);

    // Raio para busca de relatos similares (200 metros, conforme regra de negócio)
    private static final int RAIO_CLUSTER_METROS = 200;
    // Janela de tempo para agrupamento de relatos
    private static final int JANELA_HORAS = 2;

    private final GeminiConfig geminiConfig;
    private final MinioService minioService;
    private final NotificationService notificationService;
    private final OcorrenciaRepository ocorrenciaRepository;
    private final ObjectMapper objectMapper;

    private final OkHttpClient http = new OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build();

    private static final String GEMINI_URL =
        "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s";

    public OcorrenciaIaService(GeminiConfig geminiConfig,
                                MinioService minioService,
                                NotificationService notificationService,
                                OcorrenciaRepository ocorrenciaRepository,
                                ObjectMapper objectMapper) {
        this.geminiConfig = geminiConfig;
        this.minioService = minioService;
        this.notificationService = notificationService;
        this.ocorrenciaRepository = ocorrenciaRepository;
        this.objectMapper = objectMapper;
    }

    // =========================================================================
    // ENTRY POINT — chamado pelo OcorrenciaService quando admin abre ocorrência
    // =========================================================================

    /**
     * Calcula a sugestão de localização para a ocorrência.
     * Respeita as regras de plano da cidade associada.
     *
     * @param ocorrencia A ocorrência pendente de aprovação
     * @param cidade     A cidade associada (pode ser null — usará fallback)
     * @return SugestaoIaDto sempre preenchido (nunca null)
     */
    public SugestaoIaDto calcularSugestao(Ocorrencia ocorrencia, Cidade cidade) {

        // --- 1. Calcular centroide PostGIS (gratuito, sempre disponível) ---
        CentroideResult centroide = calcularCentroidePostGIS(ocorrencia);

        // --- 2. Verificar se o plano permite IA ---
        PlanoCidade planoEfetivo = (cidade != null) ? cidade.getPlanoEfetivo() : PlanoCidade.BASE_GRATUITO;

        if (planoEfetivo != PlanoCidade.PRO_MUNICIPAL) {
            log.info("IA indisponível para a cidade {} (plano: {}). Retornando centroide.",
                    ocorrencia.getCidade(), planoEfetivo);
            return new SugestaoIaDto(
                    centroide.lat, centroide.lng,
                    0.5,
                    "Posicionamento por centroide geográfico. " +
                    "A análise por IA está disponível apenas no Plano PRO.",
                    centroide.totalRelatos
            );
        }

        // --- 3. Verificar se a API key está configurada ---
        String apiKey = geminiConfig.getApi().getKey();
        if (apiKey == null || apiKey.isBlank() || apiKey.equals("SUA_CHAVE_AQUI")) {
            log.error("GEMINI_API_KEY não configurada! Verifique o .env do servidor.");
            notificarAdminFalhaIa(ocorrencia, "API Key do Gemini não está configurada no servidor.");
            return fallbackCentroide(centroide, "IA indisponível: chave de API não configurada.");
        }

        // --- 4. Chamar Gemini ---
        return chamarGemini(ocorrencia, centroide, apiKey);
    }

    // =========================================================================
    // CENTROIDE PostGIS — leve, roda no banco local, sem custo
    // =========================================================================

    private CentroideResult calcularCentroidePostGIS(Ocorrencia ocorrencia) {
        try {
            // Busca relatos do mesmo tipo, dentro de 200m, nas últimas 2h
            // (query nativa com ST_DWithin — índice GIST garante performance)
            String query = """
                SELECT
                    COUNT(*) as total,
                    AVG(latitude) as lat_centro,
                    AVG(longitude) as lng_centro
                FROM ocorrencias
                WHERE tipo = :tipo
                  AND status NOT IN ('RECUSADA', 'RESOLVIDA')
                  AND data_hora >= NOW() - INTERVAL ':horas hours'
                  AND ST_DWithin(
                      geom::geography,
                      ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
                      :raio
                  )
                """;

            // Executa via JDBC nativo (Hibernate EntityManager)
            var result = ocorrenciaRepository.buscarCentroideProximo(
                    ocorrencia.getTipo(),
                    ocorrencia.getLatitude(),
                    ocorrencia.getLongitude(),
                    RAIO_CLUSTER_METROS,
                    JANELA_HORAS
            );

            if (result != null && result.length == 3) {
                int total = ((Number) result[0]).intValue();
                double latC = ((Number) result[1]).doubleValue();
                double lngC = ((Number) result[2]).doubleValue();
                return new CentroideResult(latC, lngC, Math.max(1, total));
            }
        } catch (Exception e) {
            log.warn("Falha ao calcular centroide PostGIS: {}. Usando coordenada original.", e.getMessage());
        }
        // Fallback: coordenada informada pelo cidadão
        return new CentroideResult(ocorrencia.getLatitude(), ocorrencia.getLongitude(), 1);
    }

    // =========================================================================
    // CHAMADA GEMINI — multimodal (texto + foto)
    // =========================================================================

    private SugestaoIaDto chamarGemini(Ocorrencia ocorrencia, CentroideResult centroide, String apiKey) {
        try {
            String prompt = buildPrompt(ocorrencia, centroide);
            String requestBody;

            // Se a ocorrência tem foto, envia como multimodal
            String caminhoFoto = ocorrencia.getCaminhoFoto();
            if (caminhoFoto != null && !caminhoFoto.isBlank()) {
                try {
                    byte[] imageBytes = minioService.baixarArquivo(caminhoFoto);
                    if (imageBytes != null && imageBytes.length > 0) {
                        String base64 = Base64.getEncoder().encodeToString(imageBytes);
                        String mime = caminhoFoto.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";
                        requestBody = buildRequestComFoto(prompt, base64, mime);
                        log.debug("Enviando ocorrência {} ao Gemini com foto ({} bytes)", ocorrencia.getId(), imageBytes.length);
                    } else {
                        requestBody = buildRequestSoTexto(prompt);
                    }
                } catch (Exception e) {
                    log.warn("Não foi possível baixar foto do MinIO para IA: {}. Enviando só texto.", e.getMessage());
                    requestBody = buildRequestSoTexto(prompt);
                }
            } else {
                requestBody = buildRequestSoTexto(prompt);
            }

            String url = String.format(GEMINI_URL, geminiConfig.getModel(), apiKey);
            Request request = new Request.Builder()
                    .url(url)
                    .post(RequestBody.create(requestBody, MediaType.parse("application/json")))
                    .build();

            try (Response response = http.newCall(request).execute()) {
                if (response.code() == 429) {
                    // Quota atingida
                    log.warn("Gemini: quota de requisições atingida (429).");
                    notificarAdminFalhaIa(ocorrencia, "Quota diária do Gemini atingida. Verifique o plano da API.");
                    return fallbackCentroide(centroide, "Quota da IA temporariamente esgotada.");
                }
                if (response.code() == 400 || response.code() == 401 || response.code() == 403) {
                    // Chave inválida ou sem permissão
                    String body = response.body() != null ? response.body().string() : "";
                    log.error("Gemini: chave de API inválida ou sem permissão ({}): {}", response.code(), body);
                    notificarAdminFalhaIa(ocorrencia,
                        "Chave do Gemini inválida ou sem permissão (HTTP " + response.code() + "). " +
                        "Verifique a GEMINI_API_KEY no .env. " +
                        "Nota: chaves Gemini normalmente começam com 'AIza...'");
                    return fallbackCentroide(centroide, "IA indisponível: erro de autenticação com a API.");
                }
                if (!response.isSuccessful() || response.body() == null) {
                    log.warn("Gemini retornou erro HTTP {}", response.code());
                    notificarAdminFalhaIa(ocorrencia, "Gemini retornou erro HTTP " + response.code());
                    return fallbackCentroide(centroide, "IA temporariamente indisponível.");
                }

                String json = response.body().string();
                SugestaoIaDto resultado = parseResposta(json, centroide);
                resultado.setTotalRelatosCluster(centroide.totalRelatos);
                log.info("Gemini processou ocorrência {} → confiança: {}", ocorrencia.getId(), resultado.getConfianca());
                return resultado;
            }

        } catch (java.net.SocketTimeoutException e) {
            log.warn("Gemini: timeout na requisição para ocorrência {}", ocorrencia.getId());
            notificarAdminFalhaIa(ocorrencia, "Timeout na chamada ao Gemini (>30s). Servidor pode estar sobrecarregado.");
            return fallbackCentroide(centroide, "IA indisponível por timeout. Tente novamente.");
        } catch (Exception e) {
            log.error("Erro inesperado ao chamar Gemini: {}", e.getMessage(), e);
            notificarAdminFalhaIa(ocorrencia, "Erro inesperado na IA: " + e.getMessage());
            return fallbackCentroide(centroide, "IA indisponível no momento.");
        }
    }

    // =========================================================================
    // PROMPT
    // =========================================================================

    private String buildPrompt(Ocorrencia ocorrencia, CentroideResult centroide) {
        return String.format("""
            Você é um assistente especializado da Defesa Civil brasileira.
            Analise a ocorrência abaixo e sugira a melhor coordenada geográfica \
            para posicionar o pin no mapa. Se houver foto, use-a como evidência.

            TIPO: %s
            DESCRIÇÃO DO CIDADÃO: %s
            COORDENADA INFORMADA: %.6f, %.6f
            CENTROIDE DE %d RELATO(S) SIMILARES (raio 200m, últimas 2h): %.6f, %.6f

            Responda APENAS em JSON válido, sem markdown:
            {"lat": <número>, "lng": <número>, "confianca": <0.0 a 1.0>, "justificativa": "<texto em português>"}

            Regras:
            - Prefira o centroide se houver múltiplos relatos consistentes.
            - Se a foto confirmar o tipo, aumente a confiança.
            - Se a foto mostrar algo inconsistente com o tipo declarado, reduza a confiança e explique.
            - Não crie coordenadas fora da região de referência.
            - Seja conciso na justificativa (máx. 2 frases).
            """,
            ocorrencia.getTipo(),
            ocorrencia.getDescricao(),
            ocorrencia.getLatitude(), ocorrencia.getLongitude(),
            centroide.totalRelatos,
            centroide.lat, centroide.lng
        );
    }

    private String buildRequestComFoto(String prompt, String base64, String mime) {
        String escapedPrompt = escapeJson(prompt);
        return """
            {
              "contents": [{
                "parts": [
                  {"text": "%s"},
                  {"inline_data": {"mime_type": "%s", "data": "%s"}}
                ]
              }],
              "generationConfig": {"temperature": 0.1, "maxOutputTokens": 300}
            }
            """.formatted(escapedPrompt, mime, base64);
    }

    private String buildRequestSoTexto(String prompt) {
        return """
            {
              "contents": [{"parts": [{"text": "%s"}]}],
              "generationConfig": {"temperature": 0.1, "maxOutputTokens": 300}
            }
            """.formatted(escapeJson(prompt));
    }

    // =========================================================================
    // PARSE DA RESPOSTA
    // =========================================================================

    private SugestaoIaDto parseResposta(String json, CentroideResult fallback) {
        try {
            JsonNode root = objectMapper.readTree(json);
            String text = root.path("candidates").get(0)
                              .path("content").path("parts").get(0)
                              .path("text").asText();

            // Remove possíveis blocos markdown que o modelo insira por engano
            text = text.replaceAll("```json", "").replaceAll("```", "").trim();

            JsonNode result = objectMapper.readTree(text);
            return new SugestaoIaDto(
                result.get("lat").asDouble(),
                result.get("lng").asDouble(),
                result.get("confianca").asDouble(),
                result.get("justificativa").asText()
            );
        } catch (Exception e) {
            log.warn("Falha ao parsear resposta do Gemini: {}. Usando centroide.", e.getMessage());
            return fallbackCentroide(fallback, "Resposta da IA inválida. Usando centroide geográfico.");
        }
    }

    // =========================================================================
    // NOTIFICAÇÃO DE FALHA AO ADMIN
    // =========================================================================

    /**
     * Envia notificação push para o admin quando a IA falha.
     * Não lança exceção — falha silenciosa para não bloquear o fluxo principal.
     */
    private void notificarAdminFalhaIa(Ocorrencia ocorrencia, String motivo) {
        try {
            notificationService.notificarAdminsPorCidade(
                ocorrencia.getCidade(),
                "⚠️ IA indisponível",
                "A análise por IA falhou para a ocorrência #" +
                ocorrencia.getId().substring(0, 8) + ". " + motivo
            );
        } catch (Exception e) {
            log.warn("Falha ao enviar notificação de erro IA: {}", e.getMessage());
        }
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    private SugestaoIaDto fallbackCentroide(CentroideResult c, String justificativa) {
        return new SugestaoIaDto(c.lat, c.lng, 0.5, justificativa, c.totalRelatos);
    }

    private String escapeJson(String s) {
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "");
    }

    /** Resultado intermediário do cálculo de centroide. */
    private record CentroideResult(double lat, double lng, int totalRelatos) {}
}
