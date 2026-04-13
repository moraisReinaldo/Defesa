import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ocorrencia.dart';
import '../models/ponto_interesse.dart';
import '../models/usuario.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService;

  ApiService(this._storageService);

  // URL configurável via --dart-define=API_BASE_URL=https://sua-api.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://defesa-civil-backend.onrender.com/api',
  );

  static String getServerRoot() {
    return baseUrl.replaceAll('/api', '');
  }

  // Backup para desenvolvimento local (Android Emulator -> 10.0.2.2)
  static const String _localFallbackUrl = 'http://10.0.2.2:8080/api';

  // Timeout padrão de 30s (era 90s — excessivo para a maioria das operações)
  static const Duration _timeoutLimit = Duration(seconds: 30);
  // Timeout maior para uploads de imagem
  static const Duration _uploadTimeoutLimit = Duration(seconds: 60);

  String _extractMessageFromBody(String body) {
    if (body.isEmpty) return 'Erro desconhecido';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        if (decoded['message'] != null) return decoded['message'].toString();
        if (decoded['error'] != null) return decoded['error'].toString();
      }
    } catch (_) {
      // ignore
    }
    return body;
  }

  Exception _httpException(http.Response response) {
    final msg = _extractMessageFromBody(response.body);
    final safe = msg.trim().isEmpty ? 'Erro ${response.statusCode}' : msg.trim();
    return Exception(safe);
  }

  // ========== METODOS BASE COM RESILIÊNCIA ==========

  Future<http.Response> _post(String path, dynamic body, {bool secure = true, Duration? timeout}) async {
    final headers = secure ? await _getHeaders() : {'Content-Type': 'application/json'};
    final effectiveTimeout = timeout ?? _timeoutLimit;
    try {
      return await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(effectiveTimeout);
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('🚨 Erro de Socket em POST $path: $e');
        if (baseUrl.contains('onrender.com')) {
          print('🔄 Tentando fallback para backend local: $_localFallbackUrl$path');
          try {
            return await http
                .post(Uri.parse('$_localFallbackUrl$path'), headers: headers, body: jsonEncode(body))
                .timeout(const Duration(seconds: 10));
          } catch (e2) {
            print('⚠️ Fallback local também falhou em POST: $e2');
          }
        }
      }
      throw Exception('Erro de conexão: Não foi possível alcançar o servidor em $baseUrl$path. Verifique se o backend está rodando localmente ou se a URL $baseUrl é válida.');
    } on TimeoutException {
      throw Exception('O servidor demorou para responder em POST. Tente novamente em instantes.');
    } catch (e) {
      if (kDebugMode) print('🚨 Erro de conexão em POST $path: $e');
      throw Exception('Erro ao conectar com o servidor.');
    }
  }

  Future<http.Response> _get(String path) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$path');
    
    try {
      return await http
          .get(url, headers: headers)
          .timeout(_timeoutLimit);
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('🚨 Erro de Socket em $url: $e');
        // Se falhar no Render em debug, tentamos o fallback local (Android Emulator)
        if (baseUrl.contains('onrender.com')) {
          print('🔄 Tentando fallback para backend local: $_localFallbackUrl$path');
          try {
            return await http
                .get(Uri.parse('$_localFallbackUrl$path'), headers: headers)
                .timeout(const Duration(seconds: 5));
          } catch (e2) {
            print('⚠️ Fallback local também falhou: $e2');
          }
        }
      }
      throw Exception('Erro de conexão: Não foi possível alcançar o servidor em $url. Verifique se o backend está rodando localmente ou se a URL $baseUrl é válida.');
    } on TimeoutException {
      throw Exception('O servidor demorou para responder. Tente novamente em instantes.');
    } catch (e) {
      if (kDebugMode) print('🚨 Erro ao conectar em $url: $e');
      throw Exception('Erro ao conectar com o servidor.');
    }
  }

  Future<http.Response> _patch(String path, dynamic body, {bool secure = true}) async {
    final headers = secure ? await _getHeaders() : {'Content-Type': 'application/json'};
    try {
      return await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeoutLimit);
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('🚨 Erro de Socket em PATCH $path: $e');
        if (baseUrl.contains('onrender.com')) {
          print('🔄 Tentando fallback para backend local: $_localFallbackUrl$path');
          try {
            return await http
                .patch(Uri.parse('$_localFallbackUrl$path'), headers: headers, body: jsonEncode(body))
                .timeout(const Duration(seconds: 10));
          } catch (e2) {
             print('⚠️ Fallback local também falhou em PATCH: $e2');
          }
        }
      }
      throw Exception('Erro de conexão ao atualizar: Servidor inacessível.');
    } on TimeoutException {
      throw Exception('Tempo esgotado ao tentar atualizar.');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor para atualização.');
    }
  }

  Future<http.Response> _delete(String path) async {
    final headers = await _getHeaders();
    try {
      return await http
          .delete(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(_timeoutLimit);
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('🚨 Erro de Socket em DELETE $path: $e');
        if (baseUrl.contains('onrender.com')) {
          print('🔄 Tentando fallback para backend local: $_localFallbackUrl$path');
          try {
            return await http
                .delete(Uri.parse('$_localFallbackUrl$path'), headers: headers)
                .timeout(const Duration(seconds: 5));
          } catch (e2) {
             print('⚠️ Fallback local também falhou em DELETE: $e2');
          }
        }
      }
      throw Exception('Erro de conexão ao deletar: Servidor inacessível.');
    } on TimeoutException {
      throw Exception('Tempo esgotado ao tentar deletar.');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor para deletar.');
    }
  }

  // ========== HEADERS SECURE ==========

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.obterToken();
    final user = await _storageService.obterUsuarioLogado();
    
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    if (user != null) {
      headers['X-User-Id'] = user.id;
    }
    
    return headers;
  }

  // ========== AUTH & USUARIO ==========

  Future<Map<String, dynamic>?> login(String email, String senha) async {
    final response = await _post('/usuarios/login', {'email': email, 'senha': senha}, secure: false);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw _httpException(response);
  }

  Future<Map<String, dynamic>?> cadastrarUsuario(UsuarioRequest req) async {
    try {
      final response = await _post('/auth/cadastro', req.toJson(), secure: false);
      final dynamic data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is Map) {
          final Map<String, dynamic> result = Map<String, dynamic>.from(data);
          result['sucesso'] = true;
          return result;
        }
        return {'sucesso': true};
      } else {
        return {
          'sucesso': false,
          'message': (data is Map ? data['message'] : response.body) ?? 'Erro no cadastro',
        };
      }
    } catch (e) {
      return {'sucesso': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  // ========== OCORRÊNCIAS ==========

  Future<List<Ocorrencia>> listarOcorrencias({String? cidade}) async {
    try {
      final query = (cidade != null && cidade.isNotEmpty) ? '?cidade=$cidade' : '';
      final response = await _get('/ocorrencias$query');
      if (response.statusCode == 200) {
        final List vindoDaApi = jsonDecode(response.body);
        return vindoDaApi.map((o) => Ocorrencia.fromJson(o)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Ocorrencia?> criarOcorrencia(Ocorrencia ocorrencia) async {
    Map<String, dynamic> body = ocorrencia.toJson();
    
    // Se houver uma foto local, converter para Base64 (simplificado como solicitado pelo backend)
    if (ocorrencia.caminhoFoto != null && ocorrencia.caminhoFoto!.isNotEmpty) {
      final file = File(ocorrencia.caminhoFoto!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        body['caminhoFoto'] = 'data:image/jpeg;base64,$base64String';
      }
    }

    // Usar timeout maior para upload de imagem
    final response = await _post('/ocorrencias', body, timeout: _uploadTimeoutLimit);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Ocorrencia.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Ocorrencia?> aprovarOcorrencia(String id) async {
    final response = await _post('/ocorrencias/$id/aprovar', {});
    if (response.statusCode == 200) {
      return Ocorrencia.fromJson(jsonDecode(response.body));
    }
    throw _httpException(response);
  }

  Future<Ocorrencia?> registrarChegadaAgente(String id, {String? parecer}) async {
    final body = parecer != null ? {'parecer': parecer} : {};
    final response = await _post('/ocorrencias/$id/chegada', body);
    if (response.statusCode == 200) {
      return Ocorrencia.fromJson(jsonDecode(response.body));
    }
    throw _httpException(response);
  }

  Future<Ocorrencia?> resolverOcorrencia(String id, {String? parecer}) async {
    final body = parecer != null ? {'parecer': parecer} : {};
    final response = await _post('/ocorrencias/$id/resolver', body);
    if (response.statusCode == 200) {
      return Ocorrencia.fromJson(jsonDecode(response.body));
    }
    throw _httpException(response);
  }

  Future<Ocorrencia?> reativarOcorrencia(String id) async {
    final response = await _post('/ocorrencias/$id/reativar', {});
    if (response.statusCode == 200) {
      return Ocorrencia.fromJson(jsonDecode(response.body));
    }
    throw _httpException(response);
  }

  Future<Ocorrencia?> atualizarOcorrencia(Ocorrencia ocorrencia) async {
    final response = await _patch('/ocorrencias/${ocorrencia.id}', ocorrencia.toJson());
    if (response.statusCode == 200) {
      return Ocorrencia.fromJson(jsonDecode(response.body));
    }
    throw _httpException(response);
  }

  Future<void> deletarOcorrencia(String id) async {
    final response = await _delete('/ocorrencias/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _httpException(response);
    }
  }

  // ========== ADMIN (ROOT) ==========

  Future<String?> loginAdmin(String senha) async {
    final response = await _post('/auth/admin-login', {'senha': senha}, secure: false);
    
    if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
    }
    return null;
  }

  // ========== PONTOS DE INTERESSE ==========

  Future<List<PontoInteresse>> listarPontosInteresse({String? cidade}) async {
    try {
      final query = cidade != null ? '?cidade=$cidade' : '';
      final response = await _get('/pontos-interesse$query');
      if (response.statusCode == 200) {
        final List vindoDaApi = jsonDecode(response.body);
        return vindoDaApi.map((p) => PontoInteresse.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<PontoInteresse?> criarPontoInteresse(PontoInteresse ponto) async {
    final response = await _post('/pontos-interesse', ponto.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return PontoInteresse.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deletarPontoInteresse(String id) async {
    final response = await _delete('/pontos-interesse/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ========== USUARIOS / AGENTES ==========

  Future<dynamic> promoverParaAgente(String email) async {
    final response = await _post('/usuarios/promover', {'email': email});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw _httpException(response);
  }

  Future<List<Usuario>> listarAgentes({String? cidade}) async {
    try {
      final query = cidade != null ? '?cidade=$cidade' : '';
      final response = await _get('/usuarios/agentes$query');
      if (response.statusCode == 200) {
        final List vindoDaApi = jsonDecode(response.body);
        return vindoDaApi.map((u) => Usuario.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('Erro ao listar agentes: $e');
      return [];
    }
  }

  Future<void> deletarUsuario(String id) async {
    final response = await _delete('/usuarios/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _httpException(response);
    }
  }
  // ========== CIDADES ==========

  static const List<Map<String, String>> fallbackCidades = [
    {'codigo': 'ATI', 'nome': 'Atibaia'},
    {'codigo': 'BP', 'nome': 'Bragança Paulista'},
    {'codigo': 'JOA', 'nome': 'Joanópolis'},
    {'codigo': 'NAZ', 'nome': 'Nazaré Paulista'},
    {'codigo': 'PIR', 'nome': 'Piracaia'},
    {'codigo': 'TUI', 'nome': 'Tuiuti'},
    {'codigo': 'VAR', 'nome': 'Vargem'},
  ];

  Future<List<Map<String, String>>> listarCidades() async {
    try {
      final response = await _get('/cidades');
      if (response.statusCode == 200) {
        final List vindoDaApi = jsonDecode(response.body);
        if (vindoDaApi.isNotEmpty) {
          return vindoDaApi.map((e) => <String, String>{
            'codigo': e['codigo'].toString(),
            'nome': e['nome'].toString(),
          }).toList();
        }
      }
      return fallbackCidades;
    } catch (e) {
      if (kDebugMode) print('Erro ao listar cidades: $e');
      return fallbackCidades;
    }
  }
}

class UsuarioRequest {
  final String nome;
  final String email;
  final String senha;
  final String telefone;
  final String cidade;
  final String role;
  final String status;
  final bool concordaLGPD;

  UsuarioRequest({
    required this.nome,
    required this.email,
    required this.senha,
    required this.telefone,
    required this.cidade,
    required this.role,
    this.status = 'ATIVO',
    required this.concordaLGPD,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'senha': senha,
      'telefone': telefone,
      'cidade': cidade,
      'role': role,
      'status': status,
      'concordaLGPD': concordaLGPD,
    };
  }
}
