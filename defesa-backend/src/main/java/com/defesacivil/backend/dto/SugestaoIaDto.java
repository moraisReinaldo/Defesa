package com.defesacivil.backend.dto;

/**
 * Resultado da análise de IA (Gemini) para sugestão de localização de ocorrência.
 */
public class SugestaoIaDto {

    private double lat;
    private double lng;
    private double confianca;     // 0.0 a 1.0
    private String justificativa; // Texto em português gerado pelo Gemini
    private int totalRelatosCluster;

    public SugestaoIaDto() {}

    public SugestaoIaDto(double lat, double lng, double confianca, String justificativa) {
        this.lat = lat;
        this.lng = lng;
        this.confianca = confianca;
        this.justificativa = justificativa;
        this.totalRelatosCluster = 1;
    }

    public SugestaoIaDto(double lat, double lng, double confianca, String justificativa, int totalRelatosCluster) {
        this.lat = lat;
        this.lng = lng;
        this.confianca = confianca;
        this.justificativa = justificativa;
        this.totalRelatosCluster = totalRelatosCluster;
    }

    public double getLat() { return lat; }
    public void setLat(double lat) { this.lat = lat; }
    public double getLng() { return lng; }
    public void setLng(double lng) { this.lng = lng; }
    public double getConfianca() { return confianca; }
    public void setConfianca(double confianca) { this.confianca = confianca; }
    public String getJustificativa() { return justificativa; }
    public void setJustificativa(String justificativa) { this.justificativa = justificativa; }
    public int getTotalRelatosCluster() { return totalRelatosCluster; }
    public void setTotalRelatosCluster(int totalRelatosCluster) { this.totalRelatosCluster = totalRelatosCluster; }
}
