package com.defesacivil.backend.controller;

import com.defesacivil.backend.domain.Cidade;
import com.defesacivil.backend.domain.enums.PlanoCidade;
import com.defesacivil.backend.repository.CidadeRepository;
import com.defesacivil.backend.service.StripeService;
import com.defesacivil.backend.service.UsuarioService;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.model.Event;
import com.stripe.model.EventDataObjectDeserializer;
import com.stripe.model.Subscription;
import com.stripe.model.checkout.Session;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/webhooks")
public class StripeWebhookController {

    private static final Logger log = LoggerFactory.getLogger(StripeWebhookController.class);

    private final StripeService stripeService;
    private final UsuarioService usuarioService;
    private final CidadeRepository cidadeRepository;

    public StripeWebhookController(StripeService stripeService,
                                   UsuarioService usuarioService,
                                   CidadeRepository cidadeRepository) {
        this.stripeService = stripeService;
        this.usuarioService = usuarioService;
        this.cidadeRepository = cidadeRepository;
    }

    /**
     * Endpoint oficial para receber eventos HTTP disparados pelo Stripe (Webhooks).
     * Rota pública liberada no SecurityConfig, validada criptograficamente via Header Stripe-Signature.
     */
    @PostMapping("/stripe")
    public ResponseEntity<?> handleStripeWebhook(
            @RequestBody String payload,
            @RequestHeader(value = "Stripe-Signature", required = false) String sigHeader) {

        if (sigHeader == null || sigHeader.isBlank()) {
            log.warn("[STRIPE WEBHOOK] Requisição rejeitada: cabeçalho 'Stripe-Signature' ausente.");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Cabeçalho Stripe-Signature ausente.");
        }

        Event event;
        try {
            event = stripeService.construirEventoWebhook(payload, sigHeader);
        } catch (SignatureVerificationException e) {
            log.error("[STRIPE WEBHOOK] Falha na verificação de assinatura: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Assinatura inválida do Stripe.");
        } catch (Exception e) {
            log.error("[STRIPE WEBHOOK] Erro ao construir evento: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erro interno ao processar webhook.");
        }

        log.info("[STRIPE WEBHOOK] Evento recebido: {} (ID: {})", event.getType(), event.getId());

        EventDataObjectDeserializer dataObjectDeserializer = event.getDataObjectDeserializer();
        if (!dataObjectDeserializer.getObject().isPresent()) {
            log.warn("[STRIPE WEBHOOK] Objeto de dados vazio para o evento: {}", event.getType());
            return ResponseEntity.ok(Map.of("status", "skipped", "reason", "no_data_object"));
        }

        switch (event.getType()) {
            case "checkout.session.completed":
                processarCheckoutSessionCompleted((Session) dataObjectDeserializer.getObject().get());
                break;

            case "customer.subscription.deleted":
                processarAssinaturaCancelada((Subscription) dataObjectDeserializer.getObject().get());
                break;

            default:
                log.info("[STRIPE WEBHOOK] Evento {} ignorado (não requer ação).", event.getType());
                break;
        }

        return ResponseEntity.ok(Map.of("status", "success", "event", event.getType()));
    }

    private void processarCheckoutSessionCompleted(Session session) {
        String email = null;
        if (session.getCustomerDetails() != null && session.getCustomerDetails().getEmail() != null) {
            email = session.getCustomerDetails().getEmail().trim();
        } else if (session.getCustomerEmail() != null) {
            email = session.getCustomerEmail().trim();
        }

        log.info("[STRIPE WEBHOOK] Checkout session concluída: {} | Modo: {} | Email: {}",
                session.getId(), session.getMode(), email);

        // 1. Ativação de Munícipe Vitalício Sem Anúncios
        if (email != null && !email.isBlank()) {
            try {
                usuarioService.ativarSemAnunciosVitalicio(email, false);
                log.info("[STRIPE WEBHOOK] Munícipe ativado com sucesso para vitalício: {}", email);
            } catch (Exception e) {
                log.warn("[STRIPE WEBHOOK] Não foi possível ativar usuário direto por e-mail (pode ser prefeitura): {}", e.getMessage());
            }
        }

        // 2. Se for assinatura municipal (Plano Gestão ou PRO)
        if ("subscription".equalsIgnoreCase(session.getMode())) {
            String subscriptionId = session.getSubscription();
            String customerId = session.getCustomer();

            // Verifica se possui metadados com identificação de cidade
            Map<String, String> metadata = session.getMetadata();
            String cidadeCodigo = metadata != null ? metadata.get("cidade_codigo") : null;

            if (cidadeCodigo != null && !cidadeCodigo.isBlank()) {
                Optional<Cidade> optCidade = cidadeRepository.findByCodigo(cidadeCodigo);
                if (optCidade.isPresent()) {
                    Cidade cidade = optCidade.get();
                    cidade.setStripeSubscriptionId(subscriptionId);
                    cidade.setStripeCustomerId(customerId);

                    // Identifica se é Gestão ou PRO
                    long amountTotal = session.getAmountTotal() != null ? session.getAmountTotal() : 0L;
                    if (amountTotal >= 140000) { // >= R$ 1.400 -> Plano PRO
                        cidade.setPlano(PlanoCidade.PRO_MUNICIPAL);
                    } else { // Plano Gestão
                        cidade.setPlano(PlanoCidade.GESTAO_MUNICIPAL);
                    }

                    cidadeRepository.save(cidade);
                    log.info("[STRIPE WEBHOOK] Cidade {} promovida para {} via assinatura {}",
                            cidade.getNome(), cidade.getPlano(), subscriptionId);
                }
            }
        }
    }

    private void processarAssinaturaCancelada(Subscription subscription) {
        String subscriptionId = subscription.getId();
        log.info("[STRIPE WEBHOOK] Assinatura cancelada: {}", subscriptionId);

        Optional<Cidade> optCidade = cidadeRepository.findByStripeSubscriptionId(subscriptionId);
        if (optCidade.isPresent()) {
            Cidade cidade = optCidade.get();
            cidade.setPlano(PlanoCidade.BASE_GRATUITO);
            cidadeRepository.save(cidade);
            log.warn("[STRIPE WEBHOOK] Plano da cidade {} revertido para BASE_GRATUITO após cancelamento no Stripe.", cidade.getNome());
        }
    }
}
