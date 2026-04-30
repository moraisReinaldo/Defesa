import 'package:uuid/uuid.dart';

enum OcorrenciaStatus {
  pendenteAprovacao,
  aprovada,
  trabalhandoAtualmente,
  recusada,
  resolvida
}

const _omit = Object();

class Ocorrencia {
  final String id;
  final String tipo;
  final String descricao;
  final double latitude;
  final double longitude;
  final String? cidade;
  final String? caminhoFoto;
  final DateTime dataHora;
  final String? usuarioId;
  final OcorrenciaStatus status;
  final DateTime? dataResolucao;
  final String? agentes; 
  final bool criadoPorAgente;
  final bool agenteNoLocal;
  final DateTime? dataChegadaAgente;
  final String? descricaoSituacao;
  /// true = salvo apenas localmente, não sincronizado com o servidor
  final bool isLocal;

  Ocorrencia({
    String? id,
    required this.tipo,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    this.cidade,
    this.caminhoFoto,
    DateTime? dataHora,
    this.usuarioId,
    this.status = OcorrenciaStatus.pendenteAprovacao,
    this.dataResolucao,
    this.agentes,
    this.criadoPorAgente = false,
    this.agenteNoLocal = false,
    this.dataChegadaAgente,
    this.descricaoSituacao,
    this.isLocal = false,
  })  : id = id ?? const Uuid().v4(),
        dataHora = dataHora ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'descricao': descricao,
      'latitude': latitude,
      'longitude': longitude,
      'cidade': cidade,
      'caminhoFoto': caminhoFoto,
      'dataHora': dataHora.toIso8601String(),
      'usuarioId': usuarioId,
      'status': status.name.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (m) => '_${m.group(0)!}',
      ).toUpperCase(),
      'dataResolucao': dataResolucao?.toIso8601String(),
      'agentes': agentes,
      'criadoPorAgente': criadoPorAgente,
      'agenteNoLocal': agenteNoLocal,
      'dataChegadaAgente': dataChegadaAgente?.toIso8601String(),
      'descricaoSituacao': descricaoSituacao,
    };
  }

  factory Ocorrencia.fromJson(Map<String, dynamic> json) {
    return Ocorrencia(
      id: json['id'] ?? '',
      tipo: json['tipo'] ?? 'OUTROS',
      descricao: json['descricao'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      cidade: json['cidade'],
      caminhoFoto: json['caminhoFoto'],
      dataHora: _parseSafe(json['dataHora']) ?? DateTime.now(),
      usuarioId: json['usuarioId'],
      status: OcorrenciaStatus.values.firstWhere(
        (e) {
          final jsonStatus = (json['status'] as String?)?.toUpperCase().replaceAll('_', '') ?? '';
          final enumStatus = e.name.toUpperCase();
          return enumStatus == jsonStatus;
        },
        orElse: () => OcorrenciaStatus.pendenteAprovacao,
      ),
      dataResolucao: _parseSafe(json['dataResolucao']),
      agentes: json['agentes'],
      criadoPorAgente: json['criadoPorAgente'] ?? false,
      agenteNoLocal: json['agenteNoLocal'] ?? false,
      dataChegadaAgente: _parseSafe(json['dataChegadaAgente']),
      descricaoSituacao: json['descricaoSituacao'],
    );
  }

  static DateTime? _parseSafe(dynamic val) {
    if (val == null) return null;
    try {
      String s = val.toString();
      if (s.contains('.')) {
        var parts = s.split('.');
        if (parts[1].length > 6) {
          s = '${parts[0]}.${parts[1].substring(0, 6)}';
        }
      }
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  Ocorrencia copyWith({
    String? id,
    String? tipo,
    String? descricao,
    double? latitude,
    double? longitude,
    String? cidade,
    String? caminhoFoto,
    DateTime? dataHora,
    String? usuarioId,
    OcorrenciaStatus? status,
    Object? dataResolucao = _omit,
    String? agentes,
    bool? criadoPorAgente,
    bool? agenteNoLocal,
    Object? dataChegadaAgente = _omit,
    String? descricaoSituacao,
    bool? isLocal,
  }) {
    return Ocorrencia(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cidade: cidade ?? this.cidade,
      caminhoFoto: caminhoFoto ?? this.caminhoFoto,
      dataHora: dataHora ?? this.dataHora,
      usuarioId: usuarioId ?? this.usuarioId,
      status: status ?? this.status,
      dataResolucao: dataResolucao == _omit
          ? this.dataResolucao
          : dataResolucao as DateTime?,
      agentes: agentes ?? this.agentes,
      criadoPorAgente: criadoPorAgente ?? this.criadoPorAgente,
      agenteNoLocal: agenteNoLocal ?? this.agenteNoLocal,
      dataChegadaAgente: dataChegadaAgente == _omit
          ? this.dataChegadaAgente
          : dataChegadaAgente as DateTime?,
      descricaoSituacao: descricaoSituacao ?? this.descricaoSituacao,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}
