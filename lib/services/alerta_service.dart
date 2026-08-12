import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import 'package:uuid/uuid.dart';

class AlertaEmergencia {
  final String id;
  final String cidade;
  final String titulo;
  final String mensagem;
  final String nivel; // INFORMATIVO, ATENCAO, CRITICO
  final DateTime dataCriacao;
  final bool ativo;

  AlertaEmergencia({
    String? id,
    required this.cidade,
    required this.titulo,
    required this.mensagem,
    required this.nivel,
    DateTime? dataCriacao,
    this.ativo = true,
  })  : id = id ?? const Uuid().v4(),
        dataCriacao = dataCriacao ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cidade': cidade,
      'titulo': titulo,
      'mensagem': mensagem,
      'nivel': nivel,
      'dataCriacao': dataCriacao.toIso8601String(),
      'ativo': ativo,
    };
  }

  factory AlertaEmergencia.fromJson(Map<String, dynamic> json) {
    return AlertaEmergencia(
      id: json['id'] ?? '',
      cidade: json['cidade'] ?? '',
      titulo: json['titulo'] ?? 'Alerta de Emergência',
      mensagem: json['mensagem'] ?? '',
      nivel: json['nivel'] ?? 'ATENCAO',
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.tryParse(json['dataCriacao'].toString()) ?? DateTime.now()
          : DateTime.now(),
      ativo: json['ativo'] ?? true,
    );
  }
}

class AlertaService {
  final ApiClient _client;

  AlertaService(this._client);

  Future<List<AlertaEmergencia>> buscarAlertasAtivos({String? cidade}) async {
    try {
      final res = await _client.dio.get(
        '/alertas',
        queryParameters: cidade != null && cidade.isNotEmpty ? {'cidade': cidade} : null,
      );

      if (res.data is List) {
        return (res.data as List).map((a) => AlertaEmergencia.fromJson(a)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('ℹ️ Nenhum alerta retornado pela API: $e');
      return [];
    }
  }

  Future<AlertaEmergencia?> emitirAlerta(AlertaEmergencia alerta) async {
    try {
      final res = await _client.dio.post('/alertas', data: alerta.toJson());
      return AlertaEmergencia.fromJson(res.data);
    } catch (e) {
      if (kDebugMode) print('🚨 Erro ao emitir alerta na API: $e');
      return alerta; // Fallback para exibição em memória se endpoint ainda for implementado
    }
  }

  Future<void> cancelarAlerta(String id) async {
    try {
      await _client.dio.delete('/alertas/$id');
    } catch (e) {
      if (kDebugMode) print('Erro ao cancelar alerta: $e');
    }
  }
}
