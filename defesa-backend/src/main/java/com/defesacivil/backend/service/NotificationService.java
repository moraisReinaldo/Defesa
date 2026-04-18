package com.defesacivil.backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Serviço de notificações push.
 * O Firebase Cloud Messaging foi removido na migração para stack self-hosted.
 * Por enquanto, as chamadas apenas logam a intenção de notificação.
 * Para reativar push, integre com um serviço como OneSignal, Expo Notifications ou FCM via HTTP v1 API.
 */
@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    public void sendPushNotification(String token, String title, String body) {
        if (token == null || token.isEmpty()) return;
        // TODO: Integrar com provedor de push (ex: OneSignal, FCM HTTP v1)
        log.info("[Push - stub] Para token={} | título='{}' | corpo='{}'", token, title, body);
    }
}
