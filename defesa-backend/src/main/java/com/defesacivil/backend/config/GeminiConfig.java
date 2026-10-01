package com.defesacivil.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Configuração da API Gemini (Google AI).
 * Lê as propriedades gemini.api.key e gemini.model do application.properties.
 */
@Configuration
@ConfigurationProperties(prefix = "gemini")
public class GeminiConfig {

    private Api api = new Api();
    private String model = "gemini-2.5-flash-lite-preview-06-17";

    public Api getApi() { return api; }
    public void setApi(Api api) { this.api = api; }
    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }

    public static class Api {
        private String key;
        public String getKey() { return key; }
        public void setKey(String key) { this.key = key; }
    }
}
