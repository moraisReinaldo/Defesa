import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ocorrencia.dart';
import '../models/usuario.dart';

class StorageService {
  static const String _ocorrenciasKey = 'ocorrencias';
  static const String _usuarioLogadoKey = 'usuario_logado';
  static const String _tokenKey = 'auth_token';
  static const String _avisoAceitoKey = 'aviso_comunitario_aceito';
  static const String _superAdminCidadeKey = 'super_admin_cidade';

  late SharedPreferences _prefs;
  final _secureStorage = const FlutterSecureStorage();

  // ========== AVISO COMUNITÁRIO ==========

  Future<void> salvarAvisoComunitarioAceito(bool aceito) async {
    await _prefs.setBool(_avisoAceitoKey, aceito);
  }

  bool obterAvisoComunitarioAceito() {
    return _prefs.getBool(_avisoAceitoKey) ?? false;
  }

  Future<void> salvarCidadeSuperAdmin(String codigo) async {
    await _prefs.setString(_superAdminCidadeKey, codigo);
  }

  String? obterCidadeSuperAdmin() {
    final val = _prefs.getString(_superAdminCidadeKey);
    return (val != null && val.isNotEmpty) ? val : null;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Auto-recuperação: se SharedPreferences foi limpo, restaura vitalício do SecureStorage
    if (_prefs.getBool(_vitalicioKey) != true) {
      final secureVal = await _secureStorage.read(key: _vitalicioKey);
      if (secureVal == 'true') {
        await _prefs.setBool(_vitalicioKey, true);
      }
    }
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

  /// Salva (ou atualiza, se já existir um registro com o mesmo id) uma ocorrência no cache local.
  Future<void> salvarOcorrencia(Ocorrencia ocorrencia) async {
    final ocorrencias = await obterOcorrencias();
    final index = ocorrencias.indexWhere((o) => o.id == ocorrencia.id);
    if (index != -1) {
      ocorrencias[index] = ocorrencia;
    } else {
      ocorrencias.add(ocorrencia);
    }
    final json = ocorrencias.map((o) => jsonEncode(o.toJson())).toList();
    await _prefs.setStringList(_ocorrenciasKey, json);
  }

  Future<List<Ocorrencia>> obterOcorrencias() async {
    final json = _prefs.getStringList(_ocorrenciasKey) ?? [];
    final lista = json
        .map((j) => Ocorrencia.fromJson(jsonDecode(j)))
        .toList();
    // Auto-cura: remove duplicatas de instalações antigas (mesmo id salvo múltiplas
    // vezes), mantendo sempre a versão mais recente de cada ocorrência.
    final idsVistos = <String>{};
    final semDuplicatas = <Ocorrencia>[];
    for (final oc in lista.reversed) {
      if (idsVistos.add(oc.id)) semDuplicatas.add(oc);
    }
    return semDuplicatas.reversed.toList();
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

  // ========== STATUS VITALÍCIO (PERSISTÊNCIA REDUNDANTE PREFS + SECURE) ==========
  static const String _vitalicioKey = 'sem_anuncios_vitalicio';

  Future<void> salvarStatusVitalicio(bool ativo) async {
    await _prefs.setBool(_vitalicioKey, ativo);
    await _secureStorage.write(key: _vitalicioKey, value: ativo ? 'true' : 'false');
  }

  bool obterStatusVitalicio() {
    return _prefs.getBool(_vitalicioKey) ?? false;
  }

  // ========== LIMPEZA ==========

  Future<void> limparTudo() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}
