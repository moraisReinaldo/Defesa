import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/rota_emergencia.dart';
import 'api_client.dart';
import 'hive_service.dart';

class RotaEmergenciaService {
  final ApiClient _client;
  final HiveService? _hiveService;

  RotaEmergenciaService(this._client, [this._hiveService]);

  Future<List<RotaEmergencia>> buscarRotas({String? cidade, bool apenasAtivas = false}) async {
    try {
      final Map<String, dynamic> params = {'apenasAtivas': apenasAtivas};
      if (cidade != null && cidade.isNotEmpty) params['cidade'] = cidade;

      final res = await _client.dio.get('/rotas-emergencia', queryParameters: params);

      if (res.data is List) {
        final rotas = (res.data as List).map((r) => RotaEmergencia.fromJson(r)).toList();
        
        // Cacheia offline em tempo de crise se for busca por cidade
        if (cidade != null && _hiveService != null) {
          final ativasJson = rotas.where((r) => r.ativa).map((r) => r.toJson()).toList();
          if (ativasJson.isNotEmpty) {
            await _hiveService.salvarRotasOffline(cidade, ativasJson);
          }
        }

        return rotas;
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar rotas de emergência na API: $e. Tentando cache offline...');
      // Fallback para cache offline do Hive
      if (cidade != null && _hiveService != null) {
        final cache = _hiveService.obterRotasOffline(cidade);
        if (cache != null && cache.isNotEmpty) {
          if (kDebugMode) print('Recuperadas ${cache.length} rotas do cache offline Hive!');
          return cache.map((r) => RotaEmergencia.fromJson(r)).toList();
        }
      }
      return [];
    }
  }

  Future<RotaEmergencia?> buscarRotaPorId(String id) async {
    try {
      final res = await _client.dio.get('/rotas-emergencia/$id');
      if (res.data is Map<String, dynamic>) {
        return RotaEmergencia.fromJson(res.data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar rota por ID: $e');
      return null;
    }
  }

  Future<RotaEmergencia?> criarRota(RotaEmergencia rota) async {
    try {
      final res = await _client.dio.post('/rotas-emergencia', data: rota.toJson());
      return RotaEmergencia.fromJson(res.data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<RotaEmergencia?> atualizarRota(RotaEmergencia rota) async {
    try {
      final res = await _client.dio.put('/rotas-emergencia/${rota.id}', data: rota.toJson());
      return RotaEmergencia.fromJson(res.data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<RotaEmergencia?> alternarStatus(String id, bool ativa) async {
    try {
      final res = await _client.dio.patch('/rotas-emergencia/$id/status', data: {'ativa': ativa});
      return RotaEmergencia.fromJson(res.data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<void> deletarRota(String id) async {
    try {
      await _client.dio.delete('/rotas-emergencia/$id');
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
