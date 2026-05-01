package com.defesacivil.backend.domain;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "pontos_interesse")
public class PontoInteresse {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @jakarta.validation.constraints.NotBlank
    @jakarta.persistence.Column(name = "tipo")
    private String tipo;

    @jakarta.validation.constraints.NotBlank
    @jakarta.persistence.Column(name = "descricao", columnDefinition = "TEXT")
    private String descricao;

    @jakarta.persistence.Column(name = "latitude")
    private double latitude;

    @jakarta.persistence.Column(name = "longitude")
    private double longitude;

    @jakarta.persistence.Column(name = "cidade")
    private String cidade;

    @jakarta.persistence.Column(name = "criado_por", nullable = true)
    private String criadoPor;

    public PontoInteresse() {}

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }
    public String getDescricao() { return descricao; }
    public void setDescricao(String descricao) { this.descricao = descricao; }
    public double getLatitude() { return latitude; }
    public void setLatitude(double latitude) { this.latitude = latitude; }
    public double getLongitude() { return longitude; }
    public void setLongitude(double longitude) { this.longitude = longitude; }
    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }
    public String getCriadoPor() { return criadoPor; }
    public void setCriadoPor(String criadoPor) { this.criadoPor = criadoPor; }
}
