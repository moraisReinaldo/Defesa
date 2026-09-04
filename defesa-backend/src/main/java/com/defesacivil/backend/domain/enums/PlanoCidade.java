package com.defesacivil.backend.domain.enums;

public enum PlanoCidade {
    BASE_GRATUITO(1, false, false, false, false, false, true),
    GESTAO_MUNICIPAL(2, false, true, false, false, true, false),
    PRO_MUNICIPAL(5, true, true, true, true, true, false);

    private final int limiteGestores;
    private final boolean permiteAgentes;
    private final boolean permiteAlertasPush;
    private final boolean permitePoi;
    private final boolean permiteDashboardWeb;
    private final boolean permiteCobradeOficial;
    private final boolean exibeAnuncios;

    PlanoCidade(int limiteGestores, boolean permiteAgentes, boolean permiteAlertasPush,
                boolean permitePoi, boolean permiteDashboardWeb, boolean permiteCobradeOficial,
                boolean exibeAnuncios) {
        this.limiteGestores = limiteGestores;
        this.permiteAgentes = permiteAgentes;
        this.permiteAlertasPush = permiteAlertasPush;
        this.permitePoi = permitePoi;
        this.permiteDashboardWeb = permiteDashboardWeb;
        this.permiteCobradeOficial = permiteCobradeOficial;
        this.exibeAnuncios = exibeAnuncios;
    }

    public int getLimiteGestores() {
        return limiteGestores;
    }

    public boolean isPermiteAgentes() {
        return permiteAgentes;
    }

    public boolean isPermiteAlertasPush() {
        return permiteAlertasPush;
    }

    public boolean isPermitePoi() {
        return permitePoi;
    }

    public boolean isPermiteDashboardWeb() {
        return permiteDashboardWeb;
    }

    public boolean isPermiteCobradeOficial() {
        return permiteCobradeOficial;
    }

    public boolean isExibeAnuncios() {
        return exibeAnuncios;
    }
}
