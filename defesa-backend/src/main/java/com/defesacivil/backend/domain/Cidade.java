package com.defesacivil.backend.domain;

import com.defesacivil.backend.domain.enums.PlanoCidade;
import com.defesacivil.backend.domain.enums.StatusCidade;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

@Entity
@Table(name = "cidades")
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Cidade {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    
    @Column(unique = true, nullable = false)
    private String codigo;

    @Column(nullable = false)
    private String nome;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PlanoCidade plano = PlanoCidade.BASE_GRATUITO;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatusCidade status = StatusCidade.PENDENTE_APROVACAO;

    private LocalDateTime trialInicio;
    private LocalDateTime trialFim;
    private LocalDateTime contratoExpiracao;

    private String stripeCustomerId;
    private String stripeSubscriptionId;

    public Cidade() {}

    public Cidade(String codigo, String nome) {
        this.codigo = codigo;
        this.nome = nome;
        this.plano = PlanoCidade.BASE_GRATUITO;
        this.status = StatusCidade.PENDENTE_APROVACAO;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    
    public String getCodigo() { return codigo; }
    public void setCodigo(String codigo) { this.codigo = codigo; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public PlanoCidade getPlano() { return plano; }
    public void setPlano(PlanoCidade plano) { this.plano = plano; }

    public StatusCidade getStatus() { return status; }
    public void setStatus(StatusCidade status) { this.status = status; }

    public LocalDateTime getTrialInicio() { return trialInicio; }
    public void setTrialInicio(LocalDateTime trialInicio) { this.trialInicio = trialInicio; }

    public LocalDateTime getTrialFim() { return trialFim; }
    public void setTrialFim(LocalDateTime trialFim) { this.trialFim = trialFim; }

    public LocalDateTime getContratoExpiracao() { return contratoExpiracao; }
    public void setContratoExpiracao(LocalDateTime contratoExpiracao) { this.contratoExpiracao = contratoExpiracao; }

    public String getStripeCustomerId() { return stripeCustomerId; }
    public void setStripeCustomerId(String stripeCustomerId) { this.stripeCustomerId = stripeCustomerId; }

    public String getStripeSubscriptionId() { return stripeSubscriptionId; }
    public void setStripeSubscriptionId(String stripeSubscriptionId) { this.stripeSubscriptionId = stripeSubscriptionId; }

    // ========== REGRAS DE NEGÓCIO E GETTERS DERIVADOS ==========

    @JsonProperty("trialAtivo")
    public boolean isTrialAtivo() {
        if (status == StatusCidade.TRIAL_ATIVO && trialFim != null) {
            return trialFim.isAfter(LocalDateTime.now());
        }
        return false;
    }

    @JsonProperty("contratoAtivo")
    public boolean isContratoAtivo() {
        if (status == StatusCidade.CONTRATO_ATIVO) {
            return contratoExpiracao == null || contratoExpiracao.isAfter(LocalDateTime.now());
        }
        return false;
    }

    @JsonProperty("diasRestantesTrial")
    public long getDiasRestantesTrial() {
        if (isTrialAtivo() && trialFim != null) {
            long dias = ChronoUnit.DAYS.between(LocalDateTime.now(), trialFim);
            return dias >= 0 ? dias : 0;
        }
        return 0;
    }

    @JsonProperty("planoEfetivo")
    public PlanoCidade getPlanoEfetivo() {
        if (isTrialAtivo()) {
            return PlanoCidade.PRO_MUNICIPAL;
        }
        if (isContratoAtivo() && plano != null) {
            return plano;
        }
        return PlanoCidade.BASE_GRATUITO;
    }

    @JsonProperty("recursoAgentesLiberado")
    public boolean isRecursoAgentesLiberado() {
        return getPlanoEfetivo().isPermiteAgentes();
    }

    @JsonProperty("recursoAlertasLiberado")
    public boolean isRecursoAlertasLiberado() {
        return getPlanoEfetivo().isPermiteAlertasPush();
    }

    @JsonProperty("recursoPoiLiberado")
    public boolean isRecursoPoiLiberado() {
        return getPlanoEfetivo().isPermitePoi();
    }

    @JsonProperty("recursoDashboardWebLiberado")
    public boolean isRecursoDashboardWebLiberado() {
        return getPlanoEfetivo().isPermiteDashboardWeb();
    }

    @JsonProperty("recursoCobradeOficialLiberado")
    public boolean isRecursoCobradeOficialLiberado() {
        return getPlanoEfetivo().isPermiteCobradeOficial();
    }

    @JsonProperty("deveExibirAnuncios")
    public boolean deveExibirAnuncios() {
        return getPlanoEfetivo().isExibeAnuncios();
    }

    @JsonProperty("limiteGestores")
    public int getLimiteGestores() {
        return getPlanoEfetivo().getLimiteGestores();
    }
}
