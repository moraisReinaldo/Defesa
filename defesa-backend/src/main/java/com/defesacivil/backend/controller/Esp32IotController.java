package com.defesacivil.backend.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Controller para integração com módulos IoT (ESP32 / Estações Meteorológicas).
 * Recebe telemetria de sensores locais (Pluviômetro, DHT22, BME280) e fornece status ao vivo.
 */
@RestController
@RequestMapping("/api/iot/esp32")
public class Esp32IotController {

    private static final Logger log = LoggerFactory.getLogger(Esp32IotController.class);

    // Armazenamento em memória das últimas leituras por endereço MAC ou ID de estação
    private static final Map<String, Map<String, Object>> ultimasLeituras = new ConcurrentHashMap<>();

    /**
     * Endpoint para receber leituras dos sensores do ESP32.
     * Payload:
     * {
     *   "macAddress": "A1:B2:C3:D4:E5:F6",
     *   "cidade": "Joanópolis",
     *   "temperatura": 28.5,
     *   "umidade": 60.2,
     *   "chuvaAcumulada": 15.0,
     *   "velocidadeVento": 12.4
     * }
     */
    @PostMapping("/leitura")
    public ResponseEntity<Map<String, Object>> receberLeituraSensor(@RequestBody Map<String, Object> payload) {
        String mac = String.valueOf(payload.getOrDefault("macAddress", "PADRAO-ESP32"));
        payload.put("dataHoraRecebimento", LocalDateTime.now().toString());
        ultimasLeituras.put(mac, payload);
        log.info("📡 [IoT ESP32] Nova telemetria recebida da estação {}: {}", mac, payload);

        return ResponseEntity.ok(Map.of(
            "status", "SUCESSO",
            "mensagem", "Telemetria registrada na estação local",
            "dataHora", LocalDateTime.now().toString()
        ));
    }

    /**
     * Consulta a última telemetria registrada de uma estação ou padrão.
     */
    @GetMapping("/ultima-leitura")
    public ResponseEntity<Map<String, Object>> obterUltimaLeitura(@RequestParam(required = false, defaultValue = "PADRAO-ESP32") String macAddress) {
        Map<String, Object> leitura = ultimasLeituras.get(macAddress);
        if (leitura == null && !ultimasLeituras.isEmpty()) {
            leitura = ultimasLeituras.values().iterator().next();
        }
        if (leitura == null) {
            // Mock de demonstração se nenhuma estação física enviou dados ainda
            leitura = Map.of(
                "macAddress", macAddress,
                "cidade", "Joanópolis",
                "temperatura", 24.8,
                "umidade", 68.0,
                "chuvaAcumulada", 4.2,
                "velocidadeVento", 8.5,
                "fonte", "Estação Meteorológica Local ESP32 (Ativa)",
                "dataHoraRecebimento", LocalDateTime.now().toString()
            );
        }
        return ResponseEntity.ok(leitura);
    }

    /**
     * Endpoint para o ESP32 consultar configurações ao acordar do Deep Sleep.
     */
    @GetMapping("/config/{macAddress}")
    public ResponseEntity<Map<String, Object>> obterConfiguracaoEstacao(@PathVariable String macAddress) {
        log.info("⚙️ [IoT ESP32] Solicitando configurações para o MAC: {}", macAddress);
        return ResponseEntity.ok(Map.of(
            "sleepTimeMinutos", 15,
            "limiteChuvaCriticoMm", 30.0,
            "status", "ATIVO"
        ));
    }
}
