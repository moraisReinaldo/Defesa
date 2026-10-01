package com.defesacivil.backend.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import java.time.LocalDateTime;

@Entity
@Table(name = "rotas_emergencia")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class RotaEmergencia {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @NotBlank(message = "O nome da rota é obrigatório")
    @Column(nullable = false)
    private String nome;

    @Column(columnDefinition = "TEXT")
    private String descricao;

    @NotBlank(message = "A cidade é obrigatória")
    @Column(nullable = false)
    private String cidade;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cidade_id")
    private Cidade cidadeEntidade;

    /**
     * Representação JSON da lista de coordenadas:
     * [{"lat": -23.5505, "lng": -46.6333}, ...]
     */
    @NotBlank(message = "Os pontos da rota são obrigatórios")
    @Column(columnDefinition = "TEXT", nullable = false)
    private String pontos;

    /**
     * Pontos de apoio / abrigos ao longo da rota em JSON:
     * [{"nome": "Abrigo 1", "lat": -23.55, "lng": -46.63, "tipo": "ABRIGO"}]
     */
    @Column(columnDefinition = "TEXT")
    private String pontosInteresse;

    @Column(nullable = false)
    private boolean ativa = false;

    @Column(name = "alerta_vinculado_id")
    private String alertaVinculadoId;

    @Column(name = "criado_por_id")
    private String criadoPorId;

    @Column(name = "data_criacao")
    private LocalDateTime dataCriacao;

    @Column(name = "data_atualizacao")
    private LocalDateTime dataAtualizacao;

    public RotaEmergencia() {
        this.dataCriacao = LocalDateTime.now();
        this.dataAtualizacao = LocalDateTime.now();
        this.ativa = false;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getDescricao() { return descricao; }
    public void setDescricao(String descricao) { this.descricao = descricao; }

    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }

    public Cidade getCidadeEntidade() { return cidadeEntidade; }
    public void setCidadeEntidade(Cidade cidadeEntidade) { this.cidadeEntidade = cidadeEntidade; }

    public String getPontos() { return pontos; }
    public void setPontos(String pontos) { this.pontos = pontos; }

    public String getPontosInteresse() { return pontosInteresse; }
    public void setPontosInteresse(String pontosInteresse) { this.pontosInteresse = pontosInteresse; }

    public boolean isAtiva() { return ativa; }
    public void setAtiva(boolean ativa) { this.ativa = ativa; }

    public String getAlertaVinculadoId() { return alertaVinculadoId; }
    public void setAlertaVinculadoId(String alertaVinculadoId) { this.alertaVinculadoId = alertaVinculadoId; }

    public String getCriadoPorId() { return criadoPorId; }
    public void setCriadoPorId(String criadoPorId) { this.criadoPorId = criadoPorId; }

    public LocalDateTime getDataCriacao() { return dataCriacao; }
    public void setDataCriacao(LocalDateTime dataCriacao) { this.dataCriacao = dataCriacao; }

    public LocalDateTime getDataAtualizacao() { return dataAtualizacao; }
    public void setDataAtualizacao(LocalDateTime dataAtualizacao) { this.dataAtualizacao = dataAtualizacao; }
}
