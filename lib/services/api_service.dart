import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ocorrencia.dart';
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
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
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

  Future<List<Ocorrencia>> listarOcorrencias() async {
    try {
      final response = await _get('/ocorrencias');
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
    final response = await _post('/ocorrencias', ocorrencia.toJson());

    if (response.statusCode == 200) {
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
