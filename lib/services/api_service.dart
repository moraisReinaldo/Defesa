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

  static const Duration _timeoutLimit = Duration(seconds: 90);

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

  Future<http.Response> _post(String path, dynamic body, {bool secure = true}) async {
    final headers = secure ? await _getHeaders() : {'Content-Type': 'application/json'};
    try {
      return await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeoutLimit);
    } on TimeoutException {
      throw Exception('O servidor está acordando (Render Cloud). Por favor, aguarde alguns segundos e tente novamente.');
    } catch (e) {
      throw Exception('Erro de conexão ($e): Verifique sua internet ou tente mais tarde.');
    }
  }

  Future<http.Response> _get(String path) async {
    final headers = await _getHeaders();
    try {
      return await http
          .get(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(_timeoutLimit);
    } on TimeoutException {
      throw Exception('O servidor demorou para responder. Tente novamente em instantes.');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor.');
    }
  }

  Future<http.Response> _delete(String path) async {
    final headers = await _getHeaders();
    try {
      return await http
          .delete(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(_timeoutLimit);
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
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data; 
      } else {
        return {
          'sucesso': false,
          'message': data is Map ? data['message'] : response.body,
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

    final response = await _post('/ocorrencias', body);

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
    return null;
  }

  Future<Ocorrencia?> registrarChegadaAgente(String id) async {
    final response = await _post('/ocorrencias/$id/chegada', {});
    
    if (response.statusCode == 200) {
      return Ocorrencia.fromJson(jsonDecode(response.body));
    }
    return null;
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
          return vindoDaApi.map((e) => {
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
  final bool concordaLGPD;

  UsuarioRequest({
    required this.nome,
    required this.email,
    required this.senha,
    required this.telefone,
    required this.cidade,
    required this.role,
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
      'concordaLGPD': concordaLGPD,
    };
  }
}
