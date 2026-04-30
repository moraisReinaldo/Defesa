import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/usuario.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class UsuarioProvider extends ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;
  Usuario? _usuarioLogado;
  bool _isAdmin = false;
  bool _isLoading = false;
  bool _estaInicializado = false;
  bool get estaInicializado => _estaInicializado;
  List<Usuario> _todosAgentes = [];
  List<Map<String, String>> _cidadesSuportadas = [];
  String? _cidadeDetectadaGps;

  UsuarioProvider(this._storageService, this._apiService) {
    // A inicialização pesada será feita pela LoadingScreen chamando carregarTudo()
  }

  /// Retorna a cidade "ativa" para o contexto atual:
  /// 1. Cidade do perfil se logado
  /// 2. Cidade detectada via GPS se anônimo
  String? get cidadeAtiva => _usuarioLogado?.cidade ?? _cidadeDetectadaGps;

  ApiService get apiService => _apiService;
  Usuario? get usuarioLogado => _usuarioLogado;
  bool get estaLogado => _usuarioLogado != null;
  bool get isAdmin => _isAdmin;
  bool get isAgente => _usuarioLogado?.isAgente ?? false;
  bool get isLoading => _isLoading;
  List<Map<String, String>> get cidadesSuportadas => _cidadesSuportadas;
  List<Usuario> get todosAgentes => _todosAgentes;

  DateTime? _ultimoSync;

  Future<void> carregarTudo() async {
    try {
      // 1. Cidades Suportadas (CRÍTICO: essencial para mapear localização)
      await carregarCidades();
      
      // 2. Verificar Sessão (CRÍTICO: define se usamos perfil ou GPS)
      await verificarUsuarioLogado();
      
      // Nesse ponto, cidades e usuário estão resolvidos.
      // O GPS será tratado pela LoadingScreen se necessário.
    } catch (e) {
      if (kDebugMode) print('Erro na carga crítica: $e');
    } finally {
      // NOTA: O LoadingScreen chamará 'determinarCidadePorGps' antes de liberar,
      // então 'estaInicializado' pode ser setado aqui ou pela LoadingScreen.
      // Vamos setar aqui como sinalizador de que a Carga Base acabou.
      _estaInicializado = true;
      notifyListeners();

      // Tarefas não-críticas rodam silenciosamente em background
      if (_isAdmin) {
        carregarAgentes();
      }
      _ultimoSync = DateTime.now();
    }
  }

  /// Determina a cidade atual via GPS para usuários não logados.
  Future<void> determinarCidadePorGps() async {
    try {
      // 1. Obter coordenadas com timeout agressivo
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, 
        timeLimit: const Duration(seconds: 4),
      );

      // 2. Tentar geocoding com timeout manual (pois a lib geocoding não tem nativo)
      final placemarks = await Future.any([
        placemarkFromCoordinates(position.latitude, position.longitude),
        Future.delayed(const Duration(seconds: 3)).then((_) => <Placemark>[])
      ]);

      if (placemarks.isNotEmpty) {
        String? cidadeGps = placemarks.first.subAdministrativeArea ?? placemarks.first.locality;
        if (cidadeGps != null && cidadeGps.isNotEmpty) {
          final correspondente = _cidadesSuportadas.firstWhere(
            (c) => c['nome']?.toLowerCase() == cidadeGps.toLowerCase() || 
                   cidadeGps.toLowerCase().contains(c['nome']!.toLowerCase()),
            orElse: () => {},
          );
          
          if (correspondente.isNotEmpty) {
            _cidadeDetectadaGps = correspondente['codigo'];
            notifyListeners();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ GPS timeout ou erro: $e');
    }
  }

  /// Sincronização global disparada por interações do usuário.
  /// Implementa um 'throttle' de 5 segundos para evitar excesso de requisições.
  Future<void> sincronizarGlobal({bool force = false}) async {
    // Se estiver carregando ou se o último sync foi há menos de 5 segundos, ignora
    if (_isLoading) return;
    
    final agora = DateTime.now();
    if (!force && _ultimoSync != null && agora.difference(_ultimoSync!).inSeconds < 5) {
      return; 
    }

    if (kDebugMode) print('🔄 Sincronização Global Ativada...');
    
    // Rodar em background sem setar isLoading=true para não travar a UI com spinners centrais
    await carregarTudo();
  }

  bool _buscandoCidades = false;

  Future<void> carregarCidades() async {
    if (_buscandoCidades) return;
    _buscandoCidades = true;
    try {
      final list = await _apiService.listarCidades();
      _cidadesSuportadas = list;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar cidades no Provider: $e');
      // Fallback for UI if API fails completely
      if (_cidadesSuportadas.isEmpty) {
         _cidadesSuportadas = ApiService.fallbackCidades;
      }
    } finally {
      _buscandoCidades = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarPerfil({
    required String nome,
    required String telefone,
    String? cidade,
  }) async {
    if (_usuarioLogado == null) return false;
    _setLoading(true);
    try {
      final req = UsuarioRequest(
        nome: nome,
        email: _usuarioLogado!.email,
        senha: '', // O backend não deve exigir senha se não for alterada, ou podemos enviar opcional
        telefone: telefone,
        role: _usuarioLogado!.role.name.toUpperCase(),
        cidade: cidade ?? _usuarioLogado!.cidade ?? '',
        concordaLGPD: true,
      );

      final atualizado = await _apiService.atualizarUsuario(_usuarioLogado!.id, req);
      if (atualizado != null) {
        _usuarioLogado = atualizado;
        await _storageService.salvarUsuarioLogado(atualizado);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Erro ao atualizar perfil: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletarUsuario(String id) async {
    _setLoading(true);
    try {
      await _apiService.deletarUsuario(id);
      if (_isAdmin) {
        _todosAgentes.removeWhere((u) => u.id == id);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao deletar usuário: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> promoverParaAgente(String email) async {
    _setLoading(true);
    try {
      final res = await _apiService.promoverParaAgente(email);
      if (res != null) {
        await carregarAgentes();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Erro ao promover agente: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
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
        
        if (usuario.status.toUpperCase() == 'PENDENTE') {
          throw Exception('Conta de administrador aguardando ativação manual. Solicite via e-mail.');
        }

        final token = response['token'];

        // Salvar sessão segura
        await _storageService.salvarUsuarioLogado(usuario);
        await _storageService.salvarToken(token);

        _usuarioLogado = usuario;
        _isAdmin = usuario.role == Role.administrador;
        
        // Registrar ID no OneSignal para receber push diretos
        OneSignal.login(usuario.id);
        
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
          'message': response['message'] ?? response['msg'] ?? 'Sucesso!',
          'pendente': response['pendente'] == true || request.status == 'PENDENTE',
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
    _estaInicializado = false; // Reset essencial para evitar loop de carregamento
    _todosAgentes = [];
    _cidadesSuportadas = [];
    OneSignal.logout();
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
      String? originalCidade = _usuarioLogado?.cidade;
      String? cidadeBusca = originalCidade;
      
      // Mapeamento de Nome para Código (Garante que enviamos o código pro backend)
      if (cidadeBusca != null && cidadeBusca.isNotEmpty) {
        final searchCidade = cidadeBusca; // Captura para estabilizar o null-safety
        final cidades = await _apiService.listarCidades();
        final correspondente = cidades.firstWhere(
          (c) => c['nome']?.toLowerCase() == searchCidade.toLowerCase() || 
                 c['codigo']?.toLowerCase() == searchCidade.toLowerCase(),
          orElse: () => {},
        );
        if (correspondente.isNotEmpty) {
          cidadeBusca = correspondente['codigo'];
        }
      }

      if (kDebugMode) print('🔍 Buscando agentes. Original: $originalCidade -> Busca: $cidadeBusca');
      
      var agentes = await _apiService.listarAgentes(cidade: cidadeBusca);
      
      // FALLBACK: Se o admin não encontrar agentes na sua cidade, 
      // busca globalmente para evitar que erros de cadastro de cidade bloqueiem a visão.
      if (agentes.isEmpty && cidadeBusca != null && _isAdmin) {
        if (kDebugMode) print('⚠️ Nenhum agente na cidade $cidadeBusca. Tentando busca global...');
        agentes = await _apiService.listarAgentes(cidade: null);
      }

      _todosAgentes = agentes;
      if (kDebugMode) print('✅ Agentes carregados: ${agentes.length}');
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao carregar agentes: $e');
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
