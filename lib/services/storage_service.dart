import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ocorrencia.dart';
import '../models/usuario.dart';

class StorageService {
  static const String _ocorrenciasKey = 'ocorrencias';
  static const String _usuarioLogadoKey = 'usuario_logado';
  static const String _tokenKey = 'auth_token';

  late SharedPreferences _prefs;
  final _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== TOKEN (SECURE) ==========

  Future<void> salvarToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> obterToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> limparToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // ========== OCORRÊNCIAS (LOCAL CACHE) ==========

  Future<void> salvarOcorrencia(Ocorrencia ocorrencia) async {
    final ocorrencias = await obterOcorrencias();
    ocorrencias.add(ocorrencia);
    final json = ocorrencias.map((o) => jsonEncode(o.toJson())).toList();
    await _prefs.setStringList(_ocorrenciasKey, json);
  }

  Future<List<Ocorrencia>> obterOcorrencias() async {
    final json = _prefs.getStringList(_ocorrenciasKey) ?? [];
    return json
        .map((j) => Ocorrencia.fromJson(jsonDecode(j)))
        .toList();
  }

  Future<void> atualizarOcorrencia(Ocorrencia ocorrencia) async {
    final ocorrencias = await obterOcorrencias();
    final index = ocorrencias.indexWhere((o) => o.id == ocorrencia.id);
    if (index != -1) {
      ocorrencias[index] = ocorrencia;
      final json = ocorrencias.map((o) => jsonEncode(o.toJson())).toList();
      await _prefs.setStringList(_ocorrenciasKey, json);
    }
  }

  Future<void> deletarOcorrencia(String id) async {
    final ocorrencias = await obterOcorrencias();
    ocorrencias.removeWhere((o) => o.id == id);
    final json = ocorrencias.map((o) => jsonEncode(o.toJson())).toList();
    await _prefs.setStringList(_ocorrenciasKey, json);
  }

  // ========== USUÁRIO LOGADO ==========

  Future<void> salvarUsuarioLogado(Usuario usuario) async {
    // Remover senha antes de salvar no SharedPreferences (não-seguro)
    final Map<String, dynamic> dados = usuario.toJson();
    dados.remove('senha');
    final json = jsonEncode(dados);
    await _prefs.setString(_usuarioLogadoKey, json);
  }

  Future<Usuario?> obterUsuarioLogado() async {
    final json = _prefs.getString(_usuarioLogadoKey);
    if (json == null) return null;
    return Usuario.fromJson(jsonDecode(json));
  }

  Future<void> limparSessao() async {
    await _prefs.remove(_usuarioLogadoKey);
    await limparToken();
  }

  Future<bool> temUsuarioLogado() async {
    final token = await obterToken();
    return token != null && _prefs.containsKey(_usuarioLogadoKey);
  }

  // ========== LIMPEZA ==========

  Future<void> limparTudo() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}
