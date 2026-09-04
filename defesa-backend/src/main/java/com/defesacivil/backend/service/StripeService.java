package com.defesacivil.backend.service;

import com.stripe.Stripe;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Customer;
import com.stripe.model.CustomerCollection;
import com.stripe.model.Event;
import com.stripe.model.checkout.Session;
import com.stripe.model.checkout.SessionCollection;
import com.stripe.net.Webhook;
import com.stripe.param.CustomerListParams;
import com.stripe.param.checkout.SessionListParams;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class StripeService {

    private static final Logger log = LoggerFactory.getLogger(StripeService.class);

    @Value("${stripe.secret-key:}")
    private String secretKey;

    @Value("${stripe.webhook-secret:}")
    private String webhookSecret;

    @PostConstruct
    public void init() {
        if (isConfigurado()) {
            Stripe.apiKey = secretKey.trim();
            log.info("[STRIPE] SDK inicializado com sucesso.");
        } else {
            log.warn("[STRIPE] Chave secreta não configurada (STRIPE_SECRET_KEY). Verificação ao vivo desativada.");
        }
    }

    public boolean isConfigurado() {
        return secretKey != null && !secretKey.trim().isBlank() && !secretKey.contains("placeholder");
    }

    public boolean isWebhookConfigurado() {
        return webhookSecret != null && !webhookSecret.trim().isBlank() && !webhookSecret.contains("placeholder");
    }

    /**
     * Consulta a API do Stripe para verificar se existe um pagamento aprovado
     * para o e-mail informado (compra da licença vitalícia).
     *
     * @param email E-mail do munícipe no sistema
     * @return true se o pagamento foi confirmado no Stripe, false caso contrário
     */
    public boolean verificarPagamentoVitalicio(String email) {
        if (!isConfigurado()) {
            log.warn("[STRIPE] Consulta ignorada: Stripe API Key não configurada. Não é possível verificar pagamento.");
            return false;
        }

        if (email == null || email.trim().isBlank()) {
            return false;
        }

        String emailBusca = email.trim().toLowerCase();

        try {
            // 1. Busca por Sessões de Checkout completas
            SessionListParams sessionParams = SessionListParams.builder()
                .setLimit(100L)
                .setStatus(SessionListParams.Status.COMPLETE)
                .build();

            SessionCollection sessions = Session.list(sessionParams);
            if (sessions != null && sessions.getData() != null) {
                for (Session session : sessions.getData()) {
                    String customerEmail = null;
                    if (session.getCustomerDetails() != null && session.getCustomerDetails().getEmail() != null) {
                        customerEmail = session.getCustomerDetails().getEmail().trim().toLowerCase();
                    } else if (session.getCustomerEmail() != null) {
                        customerEmail = session.getCustomerEmail().trim().toLowerCase();
                    }

                    if (emailBusca.equalsIgnoreCase(customerEmail)) {
                        String paymentStatus = session.getPaymentStatus();
                        boolean isAssinatura = "subscription".equalsIgnoreCase(session.getMode());
                        if ("paid".equalsIgnoreCase(paymentStatus) && !isAssinatura) {
                            log.info("[STRIPE] Pagamento vitalício confirmado via Checkout Session {} para e-mail: {}",
                                session.getId(), emailBusca);
                            return true;
                        }
                    }
                }
            }

            // 2. Busca por Customer cadastrado no Stripe com o mesmo e-mail
            CustomerListParams customerParams = CustomerListParams.builder()
                .setEmail(emailBusca)
                .setLimit(5L)
                .build();

            CustomerCollection customers = Customer.list(customerParams);
            if (customers != null && customers.getData() != null) {
                for (Customer customer : customers.getData()) {
                    SessionListParams customerSessionParams = SessionListParams.builder()
                        .setCustomer(customer.getId())
                        .setStatus(SessionListParams.Status.COMPLETE)
                        .setLimit(10L)
                        .build();

                    SessionCollection custSessions = Session.list(customerSessionParams);
                    if (custSessions != null && custSessions.getData() != null) {
                        for (Session custSession : custSessions.getData()) {
                            boolean isAssinatura = "subscription".equalsIgnoreCase(custSession.getMode());
                            if ("paid".equalsIgnoreCase(custSession.getPaymentStatus()) && !isAssinatura) {
                                log.info("[STRIPE] Pagamento vitalício confirmado via Customer {} para e-mail: {}",
                                    customer.getId(), emailBusca);
                                return true;
                            }
                        }
                    }
                }
            }

            log.warn("[STRIPE] Nenhum pagamento 'paid' encontrado no Stripe para o e-mail: {}", emailBusca);
            return false;

        } catch (StripeException e) {
            log.error("[STRIPE] Erro ao consultar a API do Stripe para e-mail {}: {}", emailBusca, e.getMessage(), e);
            return false;
        }
    }

    /**
     * Valida e constrói o evento criptográfico do Webhook do Stripe.
     */
    public Event construirEventoWebhook(String payload, String sigHeader) throws SignatureVerificationException {
        if (!isWebhookConfigurado()) {
            throw new IllegalStateException("Stripe Webhook Secret não configurado (STRIPE_WEBHOOK_SECRET).");
        }
        return Webhook.constructEvent(payload, sigHeader, webhookSecret.trim());
    }
}
