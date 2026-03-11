import 'package:uuid/uuid.dart';

class Comentario {
  final String id;
  final String texto;
  final String? usuarioId;
  final String usuarioNome;
  final DateTime dataHora;
  final String? agentes; // Agentes associados ao comentário

  Comentario({
    String? id,
    required this.texto,
    this.usuarioId,
    required this.usuarioNome,
    DateTime? dataHora,
    this.agentes,
  })  : id = id ?? const Uuid().v4(),
        dataHora = dataHora ?? DateTime.now();

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texto': texto,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'dataHora': dataHora.toIso8601String(),
      'agentes': agentes,
    };
  }

  // Criar Comentario a partir de JSON
  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      texto: json['texto'],
      usuarioId: json['usuarioId'],
      usuarioNome: json['usuarioNome'],
      dataHora: DateTime.parse(json['dataHora']),
      agentes: json['agentes'],
    );
  }

  // Copiar com alterações
  Comentario copyWith({
    String? id,
    String? texto,
    String? usuarioId,
    String? usuarioNome,
    DateTime? dataHora,
    String? agentes,
  }) {
    return Comentario(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      dataHora: dataHora ?? this.dataHora,
      agentes: agentes ?? this.agentes,
    );
  }
}
