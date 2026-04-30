package com.defesacivil.backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpEntity;
import org.springframework.http.ResponseEntity;
import org.springframework.http.MediaType;
import java.util.Map;
import java.util.HashMap;
import java.util.List;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);
    private static final String ONESIGNAL_APP_ID = "6537856b-c264-42af-b2a9-583652a175d2";
    private static final String ONESIGNAL_REST_KEY = "os_v2_app_mu3yk26cmrbk7mvjla3ffilv2kvtmvxnhcsecv4syuosibksl2mlu6ecwjj33njcogmzl64vorabjaogqbjtsmzyx7b435hguiykxdy";
    private final RestTemplate restTemplate;

    public NotificationService() {
        this.restTemplate = new RestTemplate();
    }

    public void sendPushNotification(String userId, String title, String body) {
        if (userId == null || userId.isEmpty()) return;
        
        try {
            String url = "https://onesignal.com/api/v1/notifications";
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Key " + ONESIGNAL_REST_KEY);
            headers.set("accept", "application/json");
            
            Map<String, Object> payload = new HashMap<>();
            payload.put("app_id", ONESIGNAL_APP_ID);
            payload.put("target_channel", "push");
            payload.put("include_aliases", Map.of("external_id", List.of(userId)));
            payload.put("headings", Map.of("en", title, "pt", title));
            payload.put("contents", Map.of("en", body, "pt", body));
            
            HttpEntity<Map<String, Object>> request = new HttpEntity<>(payload, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(url, request, String.class);
            
            log.info("[OneSignal] Notificação enviada para {}. Status: {}", userId, response.getStatusCode());
        } catch (Exception e) {
            log.error("[OneSignal] Erro ao enviar notificação: {}", e.getMessage());
        }
    }
}
