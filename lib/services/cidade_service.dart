import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/cidade.dart';
import 'api_client.dart';

class CidadeService {
  final ApiClient _client;

  CidadeService(this._client);

  /// Busca dados de uma cidade (incluindo plano e status de trial) pelo código (ex: 'PIR', 'ATI')
  Future<Cidade?> buscarCidadePorCodigo(String codigo) async {
    try {
      final response = await _client.dio.get(
        '/cidades/codigo/$codigo',
        options: Options(extra: {'secure': false}),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Cidade.fromJson(response.data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar cidade por código: $e');
      return null;
    }
  }

  /// Lista todas as cidades cadastradas no sistema
  Future<List<Cidade>> listarCidades() async {
    try {
      final response = await _client.dio.get(
        '/cidades',
        options: Options(extra: {'secure': false}),
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => Cidade.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('Erro ao listar cidades: $e');
      return [];
    }
  }

  // ========== SUPER ADMIN ENDPOINTS ==========

  /// Lista prefeituras pendentes de homologação
  Future<List<Map<String, dynamic>>> listarCidadesPendentesSuper() async {
    try {
      final response = await _client.dio.get('/super/cidades/pendentes');
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('Erro ao listar pendentes super: $e');
      rethrow;
    }
  }

  /// Lista todas as cidades com dados consolidados para o Super Admin
  Future<List<Map<String, dynamic>>> listarTodasCidadesSuper() async {
    try {
      final response = await _client.dio.get('/super/cidades');
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('Erro ao listar cidades super: $e');
      rethrow;
    }
  }

  /// Obtém a minuta da cláusula jurídica mastigada dos 90 dias para esta cidade
  Future<String?> obterClausulaTrialSuper(String cidadeId) async {
    try {
      final response = await _client.dio.get('/super/cidades/$cidadeId/clausula-trial');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['termoHomologacao']?.toString();
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Erro ao obter cláusula trial: $e');
      return null;
    }
  }

  /// Homologa a cidade e ativa os 90 dias de Trial PRO
  Future<Map<String, dynamic>?> aprovarCidadeSuper(String cidadeId) async {
    try {
      final response = await _client.dio.post('/super/cidades/$cidadeId/aprovar');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Erro ao aprovar cidade: $e');
      rethrow;
    }
  }

  /// Atualiza manualmente plano, status ou expiração
  Future<Map<String, dynamic>?> atualizarPlanoManualSuper(
    String cidadeId, {
    String? plano,
    String? status,
    String? contratoExpiracao,
  }) async {
    try {
      final Map<String, String> body = {};
      if (plano != null) body['plano'] = plano;
      if (status != null) body['status'] = status;
      if (contratoExpiracao != null) body['contratoExpiracao'] = contratoExpiracao;

      final response = await _client.dio.patch('/super/cidades/$cidadeId/plano', data: body);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Erro ao atualizar plano: $e');
      rethrow;
    }
  }
}
