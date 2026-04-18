import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import 'api_client.dart';
import 'api_service.dart'; // Para UsuarioRequest

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<Map<String, dynamic>?> login(String email, String senha) async {
    try {
      final response = await _client.dio.post(
        '/usuarios/login',
        data: {'email': email, 'senha': senha},
        options: Options(extra: {'secure': false}),
      );
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>?> cadastrarUsuario(UsuarioRequest req) async {
    try {
      final response = await _client.dio.post(
        '/auth/cadastro',
        data: req.toJson(),
        options: Options(extra: {'secure': false}),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return {...data, 'sucesso': true};
      }
      return {'sucesso': true};
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] : null) ?? e.message ?? 'Erro no cadastro';
      return {'sucesso': false, 'message': msg};
    }
  }

  Future<String?> loginAdmin(String senha) async {
    try {
      final res = await _client.dio.post(
        '/auth/admin-login',
        data: {'senha': senha},
        options: Options(extra: {'secure': false}),
      );
      return res.data['token'] as String?;
    } on DioException catch (_) {
      return null;
    }
  }

  Future<dynamic> promoverParaAgente(String email) async {
    try {
      final res = await _client.dio.post('/usuarios/promover', data: {'email': email});
      return res.data;
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<List<Usuario>> listarAgentes({String? cidade}) async {
    try {
      final res = await _client.dio.get(
        '/usuarios/agentes',
        queryParameters: cidade != null ? {'cidade': cidade} : null,
      );
      final list = res.data as List;
      return list.map((u) => Usuario.fromJson(u)).toList();
    } catch (e) {
      if (kDebugMode) print('Erro ao listar agentes: $e');
      return [];
    }
  }

  Future<void> deletarUsuario(String id) async {
    try {
      await _client.dio.delete('/usuarios/$id');
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
