import 'package:flutter/foundation.dart';
import '../models/ocorrencia.dart';
import '../models/ponto_interesse.dart';
import '../models/usuario.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'ocorrencia_service.dart';
import 'ponto_interesse_service.dart';
import 'storage_service.dart';

/// [ApiService] mantido como fachada para compatibilidade.
/// Delega chamadas para os serviços especializados ([AuthService], [OcorrenciaService], etc.)
class ApiService {
  late final ApiClient _client;
  late final AuthService _auth;
  late final OcorrenciaService _ocorrencia;
  late final PontoInteresseService _ponto;

  ApiService(StorageService storage) {
    _client = ApiClient(storage);
    _auth = AuthService(_client);
    _ocorrencia = OcorrenciaService(_client);
    _ponto = PontoInteresseService(_client);
  }

  // URL atual do backend — usada por getServerRoot() e buildImageUrl()
  static const String baseUrl = ApiClient.baseUrl;

  static String getServerRoot() => baseUrl.replaceAll('/api', '');

  // ========== AUTH & USUARIO ==========
  Future<Map<String, dynamic>?> login(String email, String senha) => _auth.login(email, senha);
  Future<Map<String, dynamic>?> cadastrarUsuario(UsuarioRequest req) => _auth.cadastrarUsuario(req);
  Future<String?> loginAdmin(String senha) => _auth.loginAdmin(senha);
  Future<dynamic> promoverParaAgente(String email) => _auth.promoverParaAgente(email);
  Future<List<Usuario>> listarAgentes({String? cidade}) => _auth.listarAgentes(cidade: cidade);
  Future<void> deletarUsuario(String id) => _auth.deletarUsuario(id);

  // ========== OCORRÊNCIAS ==========
  Future<List<Ocorrencia>> listarOcorrencias({String? cidade}) => _ocorrencia.listarOcorrencias(cidade: cidade);
  Future<Ocorrencia?> criarOcorrencia(Ocorrencia ocorrencia) => _ocorrencia.criarOcorrencia(ocorrencia);
  Future<Ocorrencia?> aprovarOcorrencia(String id) => _ocorrencia.aprovarOcorrencia(id);
  Future<Ocorrencia?> registrarChegadaAgente(String id, {String? parecer}) => _ocorrencia.registrarChegadaAgente(id, parecer: parecer);
  Future<Ocorrencia?> resolverOcorrencia(String id, {String? parecer}) => _ocorrencia.resolverOcorrencia(id, parecer: parecer);
  Future<Ocorrencia?> reativarOcorrencia(String id) => _ocorrencia.reativarOcorrencia(id);
  Future<Ocorrencia?> atualizarOcorrencia(Ocorrencia ocorrencia) => _ocorrencia.atualizarOcorrencia(ocorrencia);
  Future<void> deletarOcorrencia(String id) => _ocorrencia.deletarOcorrencia(id);

  // ========== PONTOS DE INTERESSE ==========
  Future<List<PontoInteresse>> listarPontosInteresse({String? cidade}) => _ponto.listarPontosInteresse(cidade: cidade);
  Future<PontoInteresse?> criarPontoInteresse(PontoInteresse ponto) => _ponto.criarPontoInteresse(ponto);
  Future<bool> deletarPontoInteresse(String id) => _ponto.deletarPontoInteresse(id);

  // ========== CIDADES ==========
  static const List<Map<String, String>> fallbackCidades = ApiClient.fallbackCidades;
  Future<List<Map<String, String>>> listarCidades() => _client.listarCidades();
}

class UsuarioRequest {
  final String nome;
  final String email;
  final String senha;
  final String telefone;
  final String role;
  final String cidade;
  final bool concordaLGPD;
  final String status;

  UsuarioRequest({
    required this.nome,
    required this.email,
    required this.senha,
    required this.telefone,
    required this.role,
    required this.cidade,
    required this.concordaLGPD,
    this.status = 'ATIVO',
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'senha': senha,
      'telefone': telefone,
      'role': role,
      'cidade': cidade,
      'concordaLGPD': concordaLGPD,
      'status': status,
    };
  }
}
