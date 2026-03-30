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

  // ========== HEADERS SECURE ==========

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.obterToken();
    final user = await _storageService.obterUsuarioLogado();
    
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token'; // JWT Token
    }
    
    if (user != null) {
      headers['X-User-Id'] = user.id; // Para verificação rápida de Role no Service Layer
    }
    
    return headers;
  }

  // ========== AUTH & USUARIO ==========

  Future<Map<String, dynamic>?> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Retorna {usuario: {...}, token: "..."}
    }
    
    // Trata erro de pendência de aprovação (403 do controller)
    if (response.statusCode == 403) {
      throw Exception(response.body); 
    }
    
    return null;
  }

  Future<Map<String, dynamic>?> cadastrarUsuario(UsuarioRequest req) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/cadastro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Retorna {message: "...", pendente: true/false}
    }
    return null;
  }

  // ========== OCORRÊNCIAS ==========

  Future<List<Ocorrencia>> listarOcorrencias() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/ocorrencias'), headers: headers);
    
    if (response.statusCode == 200) {
      final List vindoDaApi = jsonDecode(response.body);
      return vindoDaApi.map((o) => Ocorrencia.fromJson(o)).toList();
    }
    return [];
  }

  Future<Ocorrencia?> criarOcorrencia(Ocorrencia ocorrencia) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/ocorrencias'),
      headers: headers,
      body: jsonEncode(ocorrencia.toJson()),
    );

    if (response.statusCode == 200) {
      return Ocorrencia.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Ocorrencia?> aprovarOcorrencia(String id) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/ocorrencias/$id/aprovar'), headers: headers);
    
    if (response.statusCode == 200) {
      return Ocorrencia.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Ocorrencia?> registrarChegadaAgente(String id) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/ocorrencias/$id/chegada'), headers: headers);
    
    if (response.statusCode == 200) {
      return Ocorrencia.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // ========== ADMIN (ROOT) ==========

  Future<String?> loginAdmin(String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/admin-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'senha': senha}),
    );
    
    if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token']; // Retorna o Master JWT
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
