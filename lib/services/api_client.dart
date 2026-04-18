import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Cliente HTTP central com injeção automática de JWT via interceptor Dio.
class ApiClient {
  final StorageService _storageService;

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ware-particularly-taxi-atlantic.trycloudflare.com/api',
  );

  static const Duration _timeout = Duration(seconds: 60);
  static const Duration _uploadTimeout = Duration(seconds: 90);

  late final Dio dio;

  ApiClient(this._storageService) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _uploadTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor: injeta JWT em todas as requisições autenticadas
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['secure'] != false) {
          final token = await _storageService.obterToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final user = await _storageService.obterUsuarioLogado();
          if (user != null) {
            options.headers['X-User-Id'] = user.id;
          }
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          await _storageService.limparSessao();
        }
        if (kDebugMode) print('🚨 [ApiClient] ${e.requestOptions.path}: ${e.message}');
        handler.next(e);
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => print('🌐 [Dio] $o'),
      ));
    }
  }

  Exception handleDioError(DioException e) {
    final data = e.response?.data;
    String msg = 'Erro ao conectar com o servidor.';
    if (data is Map && data['message'] != null) {
      msg = data['message'].toString();
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      msg = 'O servidor demorou para responder. Tente novamente.';
    } else if (e.type == DioExceptionType.connectionError) {
      msg = 'Sem conexão com o servidor. Verifique sua internet.';
    }
    return Exception(msg);
  }
}
