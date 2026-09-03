enum PlanoCidade {
  baseGratuito,
  gestaoMunicipal,
  proMunicipal;

  static PlanoCidade fromString(String? val) {
    if (val == null) return PlanoCidade.baseGratuito;
    switch (val.toUpperCase()) {
      case 'GESTAO_MUNICIPAL':
        return PlanoCidade.gestaoMunicipal;
      case 'PRO_MUNICIPAL':
        return PlanoCidade.proMunicipal;
      default:
        return PlanoCidade.baseGratuito;
    }
  }

  String get label {
    switch (this) {
      case PlanoCidade.baseGratuito:
        return 'Plano Base (Gratuito)';
      case PlanoCidade.gestaoMunicipal:
        return 'Plano Gestão Municipal';
      case PlanoCidade.proMunicipal:
        return 'Plano PRO Municipal';
    }
  }

  int get limiteGestores {
    switch (this) {
      case PlanoCidade.baseGratuito:
        return 1;
      case PlanoCidade.gestaoMunicipal:
        return 2;
      case PlanoCidade.proMunicipal:
        return 5;
    }
  }

  bool get permiteAgentes => this == PlanoCidade.proMunicipal;
  bool get permiteAlertasPush => this != PlanoCidade.baseGratuito;
  bool get permitePoi => this == PlanoCidade.proMunicipal;
  bool get permiteDashboardWeb => this == PlanoCidade.proMunicipal;
  bool get permiteCobradeOficial => this != PlanoCidade.baseGratuito;
  bool get exibeAnuncios => this == PlanoCidade.baseGratuito;
}

enum StatusCidade {
  pendenteAprovacao,
  trialAtivo,
  contratoAtivo,
  expirado,
  bloqueado;

  static StatusCidade fromString(String? val) {
    if (val == null) return StatusCidade.pendenteAprovacao;
    switch (val.toUpperCase()) {
      case 'TRIAL_ATIVO':
        return StatusCidade.trialAtivo;
      case 'CONTRATO_ATIVO':
        return StatusCidade.contratoAtivo;
      case 'EXPIRADO':
        return StatusCidade.expirado;
      case 'BLOQUEADO':
        return StatusCidade.bloqueado;
      default:
        return StatusCidade.pendenteAprovacao;
    }
  }

  String get label {
    switch (this) {
      case StatusCidade.pendenteAprovacao:
        return 'Pendente de Aprovação';
      case StatusCidade.trialAtivo:
        return 'Trial PRO Ativo (90 Dias)';
      case StatusCidade.contratoAtivo:
        return 'Contrato Ativo';
      case StatusCidade.expirado:
        return 'Expirado';
      case StatusCidade.bloqueado:
        return 'Bloqueado';
    }
  }
}

class Cidade {
  final String id;
  final String codigo;
  final String nome;
  final PlanoCidade plano;
  final StatusCidade status;
  final DateTime? trialInicio;
  final DateTime? trialFim;
  final DateTime? contratoExpiracao;
  final int diasRestantesTrial;

  Cidade({
    required this.id,
    required this.codigo,
    required this.nome,
    this.plano = PlanoCidade.baseGratuito,
    this.status = StatusCidade.pendenteAprovacao,
    this.trialInicio,
    this.trialFim,
    this.contratoExpiracao,
    this.diasRestantesTrial = 0,
  });

  bool get isTrialAtivo {
    if (status == StatusCidade.trialAtivo && trialFim != null) {
      return trialFim!.isAfter(DateTime.now());
    }
    return false;
  }

  bool get isContratoAtivo {
    if (status == StatusCidade.contratoAtivo) {
      return contratoExpiracao == null || contratoExpiracao!.isAfter(DateTime.now());
    }
    return false;
  }

  PlanoCidade get planoEfetivo {
    if (isTrialAtivo) return PlanoCidade.proMunicipal;
    if (isContratoAtivo) return plano;
    return PlanoCidade.baseGratuito;
  }

  bool get recursoAgentesLiberado => planoEfetivo.permiteAgentes;
  bool get recursoAlertasLiberado => planoEfetivo.permiteAlertasPush;
  bool get recursoPoiLiberado => planoEfetivo.permitePoi;
  bool get recursoDashboardWebLiberado => planoEfetivo.permiteDashboardWeb;
  bool get recursoCobradeOficialLiberado => planoEfetivo.permiteCobradeOficial;
  bool get deveExibirAnuncios => planoEfetivo.exibeAnuncios;
  int get limiteGestores => planoEfetivo.limiteGestores;

  factory Cidade.fromJson(Map<String, dynamic> json) {
    DateTime? tInicio = json['trialInicio'] != null ? DateTime.tryParse(json['trialInicio'].toString()) : null;
    DateTime? tFim = json['trialFim'] != null ? DateTime.tryParse(json['trialFim'].toString()) : null;
    DateTime? cExp = json['contratoExpiracao'] != null ? DateTime.tryParse(json['contratoExpiracao'].toString()) : null;

    int dias = 0;
    if (json['diasRestantesTrial'] != null) {
      dias = int.tryParse(json['diasRestantesTrial'].toString()) ?? 0;
    } else if (tFim != null) {
      dias = tFim.difference(DateTime.now()).inDays;
      if (dias < 0) dias = 0;
    }

    return Cidade(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      plano: PlanoCidade.fromString(json['plano']?.toString()),
      status: StatusCidade.fromString(json['status']?.toString()),
      trialInicio: tInicio,
      trialFim: tFim,
      contratoExpiracao: cExp,
      diasRestantesTrial: dias,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nome': nome,
      'plano': plano.name,
      'status': status.name,
      'trialInicio': trialInicio?.toIso8601String(),
      'trialFim': trialFim?.toIso8601String(),
      'contratoExpiracao': contratoExpiracao?.toIso8601String(),
      'diasRestantesTrial': diasRestantesTrial,
    };
  }
}
