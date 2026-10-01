package com.defesacivil.backend.dto;

import java.time.LocalDateTime;

public class ClimaDto {
    private double temperatura;
    private double umidade;
    private double velocidadeVento;
    private double precipitacaoAtual;
    private double chuvaAcumulada24h;
    private double chuvaAcumulada48h;
    private double chuvaAcumulada72h;
    private LocalDateTime dataHora;
    private String fonte; // Ex: "INMET", "CEMADEN", "Open-Meteo"

    // Getters and Setters
    public double getTemperatura() { return temperatura; }
    public void setTemperatura(double temperatura) { this.temperatura = temperatura; }

    public double getUmidade() { return umidade; }
    public void setUmidade(double umidade) { this.umidade = umidade; }

    public double getVelocidadeVento() { return velocidadeVento; }
    public void setVelocidadeVento(double velocidadeVento) { this.velocidadeVento = velocidadeVento; }

    public double getPrecipitacaoAtual() { return precipitacaoAtual; }
    public void setPrecipitacaoAtual(double precipitacaoAtual) { this.precipitacaoAtual = precipitacaoAtual; }

    public double getChuvaAcumulada24h() { return chuvaAcumulada24h; }
    public void setChuvaAcumulada24h(double chuvaAcumulada24h) { this.chuvaAcumulada24h = chuvaAcumulada24h; }

    public double getChuvaAcumulada48h() { return chuvaAcumulada48h; }
    public void setChuvaAcumulada48h(double chuvaAcumulada48h) { this.chuvaAcumulada48h = chuvaAcumulada48h; }

    public double getChuvaAcumulada72h() { return chuvaAcumulada72h; }
    public void setChuvaAcumulada72h(double chuvaAcumulada72h) { this.chuvaAcumulada72h = chuvaAcumulada72h; }

    public LocalDateTime getDataHora() { return dataHora; }
    public void setDataHora(LocalDateTime dataHora) { this.dataHora = dataHora; }

    public String getFonte() { return fonte; }
    public void setFonte(String fonte) { this.fonte = fonte; }
}
