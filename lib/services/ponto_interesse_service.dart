import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/ponto_interesse.dart';
import 'api_client.dart';

class PontoInteresseService {
  final ApiClient _client;

  PontoInteresseService(this._client);

  Future<List<PontoInteresse>> listarPontosInteresse({String? cidade}) async {
    try {
      final res = await _client.dio.get(
        '/pontos-interesse',
        queryParameters: cidade != null ? {'cidade': cidade} : null,
      );
      final list = res.data as List;
      return list.map((p) => PontoInteresse.fromJson(p)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<PontoInteresse?> criarPontoInteresse(PontoInteresse ponto) async {
    try {
      final data = ponto.toJson();
      if (kDebugMode) print('📤 Enviando PontoInteresse: $data');
      final res = await _client.dio.post('/pontos-interesse', data: data);
      return PontoInteresse.fromJson(res.data);
    } on DioException catch (e) {
      if (kDebugMode) print('❌ Erro Dio ao criar PontoInteresse: ${e.message} | Response: ${e.response?.data}');
      throw _client.handleDioError(e);
    } catch (e) {
      if (kDebugMode) print('❌ Erro genérico ao criar PontoInteresse: $e');
      rethrow;
    }
  }

  Future<bool> deletarPontoInteresse(String id) async {
    try {
      final res = await _client.dio.delete('/pontos-interesse/$id');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
