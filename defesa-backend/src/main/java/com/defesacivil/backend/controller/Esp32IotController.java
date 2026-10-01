package com.defesacivil.backend.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Controller planejado para integração com módulos IoT (ESP32).
 * Futuramente, as estações meteorológicas locais enviarão dados (MQTT ou HTTP POST) para cá.
 * Atualmente em fase de planejamento/prototipação ("meio encaixado").
 */
@RestController
@RequestMapping("/api/iot/esp32")
public class Esp32IotController {

    private static final Logger log = LoggerFactory.getLogger(Esp32IotController.class);

    /**
     * Endpoint para receber leituras dos sensores (Pluviômetro, DHT22, etc) do ESP32.
     * 
     * Exemplo de Payload do ESP32:
     * {
     *   "macAddress": "A1:B2:C3:D4:E5:F6",
     *   "temperatura": 28.5,
     *   "umidade": 60.2,
     *   "chuvaAcumulada": 15.0
     * }
     */
    @PostMapping("/leitura")
    public ResponseEntity<String> receberLeituraSensor(@RequestBody Map<String, Object> payload) {
        log.info("📡 [IoT ESP32] Nova leitura recebida: {}", payload);
        
        // TODO: Buscar EstacaoMeteorologica no banco pelo macAddress
        // TODO: Salvar a LeituraSensor no banco de dados
        // TODO: Avaliar Regra 30-30-30 (Temp > 30, Umidade < 30) e emitir alerta automático se necessário
        
        return ResponseEntity.ok("Leitura recebida com sucesso em " + LocalDateTime.now());
    }

    /**
     * Endpoint para o ESP32 consultar configurações ou limites de alarme ao ligar (Deep Sleep Wake up).
     */
    @GetMapping("/config/{macAddress}")
    public ResponseEntity<Map<String, Object>> obterConfiguracaoEstacao(@PathVariable String macAddress) {
        log.info("⚙️ [IoT ESP32] Solicitando configurações para o MAC: {}", macAddress);
        
        // Retorna configs placeholder (limites para o ESP32 acionar alarme localmente, tempo de sleep, etc)
        return ResponseEntity.ok(Map.of(
            "sleepTimeMinutos", 15,
            "limiteChuvaCriticoMm", 30.0,
            "status", "ATIVO"
        ));
    }
}
