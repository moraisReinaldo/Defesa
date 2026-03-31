import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class UsuarioProvider extends ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;
  Usuario? _usuarioLogado;
  bool _isAdmin = false;
  bool _isLoading = false;
  List<Usuario> _todosAgentes = [];

  UsuarioProvider(this._storageService, this._apiService);

  ApiService get apiService => _apiService;
  Usuario? get usuarioLogado => _usuarioLogado;
  bool get estaLogado => _usuarioLogado != null;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  // Lista de agentes da cidade do administrador
  List<Usuario> get todosAgentes => _todosAgentes; 

  Future<void> carregarTudo() async {
    await verificarUsuarioLogado();
    if (_isAdmin) {
      await carregarAgentes();
    }
  }

  Future<bool> atualizarPerfil({
    required String nome,
    required String telefone,
    String? cidade,
  }) async {
    // TODO: Implementar PUT /api/usuarios/{id} no backend
    return true; 
  }

  Future<void> deletarUsuario(String id) async {
    // TODO: Implementar DELETE /api/usuarios/{id} no backend
  }

  Future<bool> cadastrarAgente({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    String? cidade,
    String? especialidade,
  }) async {
    final res = await cadastrar(UsuarioRequest(
      nome: nome,
      email: email,
      senha: senha,
      telefone: telefone,
      role: 'AGENTE',
      cidade: cidade ?? _usuarioLogado?.cidade ?? '',
      concordaLGPD: true,
    ));
    if (res['sucesso'] == true) {
      await carregarAgentes();
    }
    return res['sucesso'] == true;
  }

  // ========== LOGIN & AUTH ==========

  Future<bool> login(String email, String senha) async {
    _setLoading(true);
    try {
      final response = await _apiService.login(email, senha);
      
      if (response != null) {
        final usuario = Usuario.fromJson(response['usuario']);
        final token = response['token'];

        // Salvar sessão segura
        await _storageService.salvarUsuarioLogado(usuario);
        await _storageService.salvarToken(token);

        _usuarioLogado = usuario;
        _isAdmin = usuario.role == Role.administrador;
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Erro ao fazer login: $e');
      rethrow; // Repassar para a UI tratar (ex: conta pendente 403)
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> cadastrar(UsuarioRequest request) async {
    _setLoading(true);
    try {
      final response = await _apiService.cadastrarUsuario(request);
      if (response != null && response['sucesso'] != false) {
        return {
          'sucesso': true,
          'message': response['message'],
          'pendente': response['pendente'] ?? false,
        };
      } else {
        return {
          'sucesso': false,
          'message': response?['message'] ?? 'Erro inesperado no servidor.',
        };
      }
    } catch (e) {
      if (kDebugMode) print('Erro no cadastro: $e');
      return {'sucesso': false, 'message': 'Erro de conexão ou servidor.'};
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _storageService.limparSessao();
    _usuarioLogado = null;
    _isAdmin = false;
    notifyListeners();
  }

  // ========== ADMIN ROOT ACCESS ==========

  Future<bool> autenticarAdmin(String senhaAdmin) async {
    _setLoading(true);
    try {
      final token = await _apiService.loginAdmin(senhaAdmin);
      if (token != null) {
        // Para acesso Admin "Master", salvamos o token mas não necessariamente um usuário
        await _storageService.salvarToken(token);
        _isAdmin = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Erro na autenticação admin master: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== INITIALIZATION ==========

  Future<void> verificarUsuarioLogado() async {
    final logado = await _storageService.obterUsuarioLogado();
    final token = await _storageService.obterToken();
    
    if (logado != null && token != null) {
      _usuarioLogado = logado;
      _isAdmin = logado.role == Role.administrador;
      if (_isAdmin) {
        carregarAgentes();
      }
      notifyListeners();
    }
  }

  Future<void> carregarAgentes() async {
    try {
      final cidade = _usuarioLogado?.cidade;
      if (kDebugMode) print('Buscando agentes para cidade: $cidade (isAdmin=$_isAdmin)');
      
      final agentes = await _apiService.listarAgentes(cidade: cidade);
      _todosAgentes = agentes;
      if (kDebugMode) print('Agentes carregados: ${agentes.length}');
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar agentes: $e');
      _todosAgentes = [];
      notifyListeners();
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // Métodos de mock local 'cadastrarAgente', 'atualizarPerfil' local foram removidos 
  // para forçar o uso da API e garantir consistência de dados.
}
