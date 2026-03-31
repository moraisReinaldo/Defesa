import 'package:uuid/uuid.dart';

class PontoInteresse {
  final String id;
  final String tipo;
  final String descricao;
  final double latitude;
  final double longitude;
  final String? cidade;
  final String? criadoPor;

  PontoInteresse({
    String? id,
    required this.tipo,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    this.cidade,
    this.criadoPor,
  }) : id = id ??  const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'descricao': descricao,
      'latitude': latitude,
      'longitude': longitude,
      'cidade': cidade,
      'criadoPor': criadoPor,
    };
  }

  factory PontoInteresse.fromJson(Map<String, dynamic> json) {
    return PontoInteresse(
      id: json['id'] ?? '',
      tipo: json['tipo'] ?? 'OUTRO',
      descricao: json['descricao'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      cidade: json['cidade'],
      criadoPor: json['criadoPor'],
    );
  }

  PontoInteresse copyWith({
    String? id,
    String? tipo,
    String? descricao,
    double? latitude,
    double? longitude,
    String? cidade,
    String? criadoPor,
  }) {
    return PontoInteresse(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cidade: cidade ?? this.cidade,
      criadoPor: criadoPor ?? this.criadoPor,
    );
  }
}
