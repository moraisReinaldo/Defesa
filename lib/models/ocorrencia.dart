import 'package:uuid/uuid.dart';
import 'comentario.dart';

enum OcorrenciaStatus {
  pendenteAprovacao,
  aprovada,
  recusada,
  resolvida
}

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
  final bool resolvida;
  final DateTime? dataResolucao;
  final String? agentes; 
  final List<Comentario> comentarios;
  final bool criadoPorAgente;
  final bool agenteNoLocal;
  final DateTime? dataChegadaAgente;

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
    this.resolvida = false,
    this.dataResolucao,
    this.agentes,
    List<Comentario>? comentarios,
    this.criadoPorAgente = false,
    this.agenteNoLocal = false,
    this.dataChegadaAgente,
  })  : id = id ?? const Uuid().v4(),
        dataHora = dataHora ?? DateTime.now(),
        comentarios = comentarios ?? [];

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
      'status': status.name.toUpperCase(),
      'resolvida': resolvida,
      'dataResolucao': dataResolucao?.toIso8601String(),
      'agentes': agentes,
      'comentarios': comentarios.map((c) => c.toJson()).toList(),
      'criadoPorAgente': criadoPorAgente,
      'agenteNoLocal': agenteNoLocal,
      'dataChegadaAgente': dataChegadaAgente?.toIso8601String(),
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
        (e) => e.name.toUpperCase() == (json['status'] as String?)?.toUpperCase(),
        orElse: () => OcorrenciaStatus.pendenteAprovacao,
      ),
      resolvida: json['resolvida'] ?? false,
      dataResolucao: _parseSafe(json['dataResolucao']),
      agentes: json['agentes'],
      comentarios: json['comentarios'] != null
          ? (json['comentarios'] as List).map((c) => Comentario.fromJson(c)).toList()
          : [],
      criadoPorAgente: json['criadoPorAgente'] ?? false,
      agenteNoLocal: json['agenteNoLocal'] ?? false,
      dataChegadaAgente: _parseSafe(json['dataChegadaAgente']),
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
    bool? resolvida,
    DateTime? dataResolucao,
    String? agentes,
    List<Comentario>? comentarios,
    bool? criadoPorAgente,
    bool? agenteNoLocal,
    DateTime? dataChegadaAgente,
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
      resolvida: resolvida ?? this.resolvida,
      dataResolucao: dataResolucao ?? this.dataResolucao,
      agentes: agentes ?? this.agentes,
      comentarios: comentarios ?? this.comentarios,
      criadoPorAgente: criadoPorAgente ?? this.criadoPorAgente,
      agenteNoLocal: agenteNoLocal ?? this.agenteNoLocal,
      dataChegadaAgente: dataChegadaAgente ?? this.dataChegadaAgente,
    );
  }
}
