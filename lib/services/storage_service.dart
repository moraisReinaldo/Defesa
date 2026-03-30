import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ocorrencia.dart';
import '../models/usuario.dart';

class StorageService {
  static const String _ocorrenciasKey = 'ocorrencias';
  static const String _usuarioLogadoKey = 'usuario_logado';
  static const String _usuariosKey = 'usuarios';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== OCORRÊNCIAS ==========

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

  Future<Ocorrencia?> obterOcorrenciaPorId(String id) async {
    final ocorrencias = await obterOcorrencias();
    try {
      return ocorrencias.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Ocorrencia>> obterOcorrenciasDoUsuario(String usuarioId) async {
    final ocorrencias = await obterOcorrencias();
    return ocorrencias.where((o) => o.usuarioId == usuarioId).toList();
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

  // ========== USUÁRIOS ==========

  Future<void> salvarUsuario(Usuario usuario) async {
    final usuarios = await obterTodosUsuarios();
    usuarios.add(usuario);
    final json = usuarios.map((u) => jsonEncode(u.toJson())).toList();
    await _prefs.setStringList(_usuariosKey, json);
  }

  Future<List<Usuario>> obterTodosUsuarios() async {
    final json = _prefs.getStringList(_usuariosKey) ?? [];
    return json
        .map((j) => Usuario.fromJson(jsonDecode(j)))
        .toList();
  }

  Future<Usuario?> obterUsuarioPorEmail(String email) async {
    final usuarios = await obterTodosUsuarios();
    try {
      return usuarios.firstWhere((u) => u.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<void> atualizarUsuario(Usuario usuario) async {
    final usuarios = await obterTodosUsuarios();
    final index = usuarios.indexWhere((u) => u.id == usuario.id);
    if (index != -1) {
      usuarios[index] = usuario;
      final json = usuarios.map((u) => jsonEncode(u.toJson())).toList();
      await _prefs.setStringList(_usuariosKey, json);
    }
  }

  Future<void> deletarUsuario(String id) async {
    final usuarios = await obterTodosUsuarios();
    usuarios.removeWhere((u) => u.id == id);
    final json = usuarios.map((u) => jsonEncode(u.toJson())).toList();
    await _prefs.setStringList(_usuariosKey, json);
  }

  // ========== USUÁRIO LOGADO ==========

  Future<void> salvarUsuarioLogado(Usuario usuario) async {
    final json = jsonEncode(usuario.toJson());
    await _prefs.setString(_usuarioLogadoKey, json);
  }

  Future<Usuario?> obterUsuarioLogado() async {
    final json = _prefs.getString(_usuarioLogadoKey);
    if (json == null) return null;
    return Usuario.fromJson(jsonDecode(json));
  }

  Future<void> limparUsuarioLogado() async {
    await _prefs.remove(_usuarioLogadoKey);
  }

  Future<bool> temUsuarioLogado() async {
    return _prefs.containsKey(_usuarioLogadoKey);
  }

  // ========== LIMPEZA ==========

  Future<void> limparTudo() async {
    await _prefs.clear();
  }
}
