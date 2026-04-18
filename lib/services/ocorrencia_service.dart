import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/ocorrencia.dart';
import 'api_client.dart';

class OcorrenciaService {
  final ApiClient _client;

  OcorrenciaService(this._client);

  Future<List<Ocorrencia>> listarOcorrencias({String? cidade}) async {
    try {
      final response = await _client.dio.get(
        '/ocorrencias',
        queryParameters: cidade != null && cidade.isNotEmpty ? {'cidade': cidade} : null,
      );
      final list = response.data as List;
      return list.map((o) => Ocorrencia.fromJson(o)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Ocorrencia?> criarOcorrencia(Ocorrencia ocorrencia) async {
    final Map<String, dynamic> body = ocorrencia.toJson();

    if (ocorrencia.caminhoFoto != null && ocorrencia.caminhoFoto!.isNotEmpty) {
      final file = File(ocorrencia.caminhoFoto!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        body['caminhoFoto'] = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    }

    try {
      final response = await _client.dio.post('/ocorrencias', data: body);
      return Ocorrencia.fromJson(response.data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<Ocorrencia?> aprovarOcorrencia(String id) async {
    try {
      final res = await _client.dio.post('/ocorrencias/$id/aprovar', data: {});
      return Ocorrencia.fromJson(res.data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<Ocorrencia?> registrarChegadaAgente(String id, {String? parecer}) async {
    try {
      final res = await _client.dio.post(
        '/ocorrencias/$id/chegada',
        data: parecer != null ? {'parecer': parecer} : {},
      );
      return Ocorrencia.fromJson(res.data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<Ocorrencia?> resolverOcorrencia(String id, {String? parecer}) async {
    try {
      final res = await _client.dio.post(
        '/ocorrencias/$id/resolver',
        data: parecer != null ? {'parecer': parecer} : {},
      );
      return Ocorrencia.fromJson(res.data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<Ocorrencia?> reativarOcorrencia(String id) async {
    try {
      final res = await _client.dio.post('/ocorrencias/$id/reativar', data: {});
      return Ocorrencia.fromJson(res.data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<Ocorrencia?> atualizarOcorrencia(Ocorrencia ocorrencia) async {
    try {
      final res = await _client.dio.patch('/ocorrencias/${ocorrencia.id}', data: ocorrencia.toJson());
      return Ocorrencia.fromJson(res.data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<void> deletarOcorrencia(String id) async {
    try {
      await _client.dio.delete('/ocorrencias/$id');
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
