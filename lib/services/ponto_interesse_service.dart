import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/ponto_interesse.dart';
import 'api_client.dart';

class PontoInteresseService {
  final ApiClient _client;

  PontoInteresseService(this._client);

  Future<List<PontoInteresse>> listarPontosInteresse({String? cidade}) async {
    try {
      final Map<String, dynamic>? query = (cidade != null && cidade.trim().isNotEmpty) 
          ? {'cidade': cidade.trim()} 
          : null;
      final res = await _client.dio.get(
        '/marcacoes',
        queryParameters: query,
      );
      if (res.data is List) {
        return (res.data as List).map((p) => PontoInteresse.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao listar pontos de interesse: $e');
      return [];
    }
  }

  Future<PontoInteresse?> criarPontoInteresse(PontoInteresse ponto) async {
    try {
      final data = ponto.toJson();
      if (kDebugMode) print('📤 Enviando PontoInteresse: $data');
      final res = await _client.dio.post('/marcacoes', data: data);
      return PontoInteresse.fromJson(res.data);
    } on DioException catch (e) {
      if (kDebugMode) print('❌ Erro Dio ao criar PontoInteresse: ${e.message} | Response: ${e.response?.data}');
      throw _client.handleDioError(e);
    } catch (e) {
      if (kDebugMode) print('❌ Erro genérico ao criar PontoInteresse: $e');
      rethrow;
    }
  }

  Future<PontoInteresse?> atualizarPontoInteresse(PontoInteresse ponto) async {
    try {
      final data = ponto.toJson();
      if (kDebugMode) print('🔄 Atualizando PontoInteresse ${ponto.id}: $data');
      final res = await _client.dio.put('/marcacoes/${ponto.id}', data: data);
      return PontoInteresse.fromJson(res.data);
    } on DioException catch (e) {
      if (kDebugMode) print('❌ Erro Dio ao atualizar PontoInteresse: ${e.message} | Response: ${e.response?.data}');
      throw _client.handleDioError(e);
    } catch (e) {
      if (kDebugMode) print('❌ Erro genérico ao atualizar PontoInteresse: $e');
      rethrow;
    }
  }

  Future<void> deletarPontoInteresse(String id) async {
    try {
      await _client.dio.delete('/marcacoes/$id');
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
