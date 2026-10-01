import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

class RotaEmergencia {
  final String id;
  final String nome;
  final String? descricao;
  final String cidade;
  final List<LatLng> pontos;
  final List<Map<String, dynamic>> pontosInteresse;
  final bool ativa;
  final String? alertaVinculadoId;
  final String? criadoPorId;
  final DateTime dataCriacao;

  RotaEmergencia({
    String? id,
    required this.nome,
    this.descricao,
    required this.cidade,
    required this.pontos,
    this.pontosInteresse = const [],
    this.ativa = false,
    this.alertaVinculadoId,
    this.criadoPorId,
    DateTime? dataCriacao,
  })  : id = id ?? const Uuid().v4(),
        dataCriacao = dataCriacao ?? DateTime.now();

  Map<String, dynamic> toJson() {
    final pontosJson = pontos
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'cidade': cidade,
      'pontos': jsonEncode(pontosJson),
      'pontosInteresse': jsonEncode(pontosInteresse),
      'ativa': ativa,
      'alertaVinculadoId': alertaVinculadoId,
      'criadoPorId': criadoPorId,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory RotaEmergencia.fromJson(Map<String, dynamic> json) {
    List<LatLng> pontosList = [];
    if (json['pontos'] != null) {
      try {
        dynamic parsed = json['pontos'];
        if (parsed is String) {
          parsed = jsonDecode(parsed);
        }
        if (parsed is List) {
          pontosList = parsed.map((p) {
            final lat = (p['lat'] as num).toDouble();
            final lng = (p['lng'] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();
        }
      } catch (_) {}
    }

    List<Map<String, dynamic>> poisList = [];
    if (json['pontosInteresse'] != null) {
      try {
        dynamic parsed = json['pontosInteresse'];
        if (parsed is String) {
          parsed = jsonDecode(parsed);
        }
        if (parsed is List) {
          poisList = List<Map<String, dynamic>>.from(parsed);
        }
      } catch (_) {}
    }

    return RotaEmergencia(
      id: json['id'] ?? '',
      nome: json['nome'] ?? 'Rota de Emergência',
      descricao: json['descricao'],
      cidade: json['cidade'] ?? '',
      pontos: pontosList,
      pontosInteresse: poisList,
      ativa: json['ativa'] ?? false,
      alertaVinculadoId: json['alertaVinculadoId'],
      criadoPorId: json['criadoPorId'],
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.tryParse(json['dataCriacao'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  RotaEmergencia copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? cidade,
    List<LatLng>? pontos,
    List<Map<String, dynamic>>? pontosInteresse,
    bool? ativa,
    String? alertaVinculadoId,
    String? criadoPorId,
    DateTime? dataCriacao,
  }) {
    return RotaEmergencia(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      cidade: cidade ?? this.cidade,
      pontos: pontos ?? this.pontos,
      pontosInteresse: pontosInteresse ?? this.pontosInteresse,
      ativa: ativa ?? this.ativa,
      alertaVinculadoId: alertaVinculadoId ?? this.alertaVinculadoId,
      criadoPorId: criadoPorId ?? this.criadoPorId,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}
