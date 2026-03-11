import 'package:uuid/uuid.dart';
import 'comentario.dart';

class Ocorrencia {
  final String id;
  final String tipo;
  final String descricao;
  final double latitude;
  final double longitude;
  final String? caminhoFoto;
  final DateTime dataHora;
  final String? usuarioId;
  final bool resolvida;
  final DateTime? dataResolucao;
  final String? agentes; // Nome dos agentes a caminho
  final List<Comentario> comentarios; // Lista de comentários

  Ocorrencia({
    String? id,
    required this.tipo,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    this.caminhoFoto,
    DateTime? dataHora,
    this.usuarioId,
    this.resolvida = false,
    this.dataResolucao,
    this.agentes,
    List<Comentario>? comentarios,
  })  : id = id ?? const Uuid().v4(),
        dataHora = dataHora ?? DateTime.now(),
        comentarios = comentarios ?? [];

  // Converter para JSON para armazenamento local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'descricao': descricao,
      'latitude': latitude,
      'longitude': longitude,
      'caminhoFoto': caminhoFoto,
      'dataHora': dataHora.toIso8601String(),
      'usuarioId': usuarioId,
      'resolvida': resolvida,
      'dataResolucao': dataResolucao?.toIso8601String(),
      'agentes': agentes,
      'comentarios': comentarios.map((c) => c.toJson()).toList(),
    };
  }

  // Criar Ocorrencia a partir de JSON
  factory Ocorrencia.fromJson(Map<String, dynamic> json) {
    return Ocorrencia(
      id: json['id'],
      tipo: json['tipo'],
      descricao: json['descricao'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      caminhoFoto: json['caminhoFoto'],
      dataHora: DateTime.parse(json['dataHora']),
      usuarioId: json['usuarioId'],
      resolvida: json['resolvida'] ?? false,
      dataResolucao: json['dataResolucao'] != null
          ? DateTime.parse(json['dataResolucao'])
          : null,
      agentes: json['agentes'],
      comentarios: json['comentarios'] != null
          ? (json['comentarios'] as List).map((c) => Comentario.fromJson(c)).toList()
          : [],
    );
  }

  // Copiar com alterações
  Ocorrencia copyWith({
    String? id,
    String? tipo,
    String? descricao,
    double? latitude,
    double? longitude,
    String? caminhoFoto,
    DateTime? dataHora,
    String? usuarioId,
    bool? resolvida,
    DateTime? dataResolucao,
    String? agentes,
    List<Comentario>? comentarios,
  }) {
    return Ocorrencia(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      caminhoFoto: caminhoFoto ?? this.caminhoFoto,
      dataHora: dataHora ?? this.dataHora,
      usuarioId: usuarioId ?? this.usuarioId,
      resolvida: resolvida ?? this.resolvida,
      dataResolucao: dataResolucao ?? this.dataResolucao,
      agentes: agentes ?? this.agentes,
      comentarios: comentarios ?? this.comentarios,
    );
  }
}
