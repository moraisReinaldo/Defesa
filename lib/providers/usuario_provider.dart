import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/usuario.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';

class UsuarioProvider extends ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;
  final HiveService _hiveService;
  Usuario? _usuarioLogado;
  bool _isAdmin = false;
  bool _isLoading = false;
  bool _estaInicializado = false;
  bool get estaInicializado => _estaInicializado;
  List<Usuario> _todosAgentes = [];
  List<Map<String, String>> _cidadesSuportadas = [];
  String? _cidadeDetectadaGps;

  UsuarioProvider(this._storageService, this._apiService, this._hiveService) {
    // Carregar cidade salva no Hive como fallback rápido (sem esperar GPS)
    _cidadeDetectadaGps = _hiveService.cidadeFavorita;
    // A inicialização pesada será feita pela LoadingScreen chamando carregarTudo()
  }

  /// Retorna a cidade "ativa" para o contexto atual:
  /// 1. Cidade do perfil se logado
  /// 2. Cidade detectada via GPS se anônimo
  String? get cidadeAtiva => _usuarioLogado?.cidade ?? _cidadeDetectadaGps;

  ApiService get apiService => _apiService;
  StorageService get storageService => _storageService;
  Usuario? get usuarioLogado => _usuarioLogado;
  bool get estaLogado => _usuarioLogado != null;
  bool get isAdmin => _isAdmin;
  bool get isAgente => _usuarioLogado?.isAgente ?? false;
  bool get isSuperAdmin => _usuarioLogado?.isSuperAdmin ?? false;
  bool get isSemAnunciosVitalicio =>
      (_usuarioLogado?.isSemAnunciosVitalicio == true) ||
      _hiveService.isSemAnunciosVitalicio ||
      _storageService.obterStatusVitalicio();
  bool get isLoading => _isLoading;
  List<Map<String, String>> get cidadesSuportadas => _cidadesSuportadas;
  List<Usuario> get todosAgentes => _todosAgentes;

  DateTime? _ultimoSync;

  void finalizarInicializacao() {
    _estaInicializado = true;
    notifyListeners();
  }

  Future<void> carregarTudo() async {
    try {
      // 1. Cidades Suportadas (CRÍTICO: essencial para mapear localização)
      await carregarCidades();
      
      // 2. Verificar Sessão (CRÍTICO: define se usamos perfil ou GPS)
      await verificarUsuarioLogado();
      
      // Tarefas não-críticas rodam silenciosamente em background
      if (_isAdmin) {
        carregarAgentes();
      }
      _ultimoSync = DateTime.now();
    } catch (e) {
      if (kDebugMode) print('Erro na carga crítica: $e');
    }
  }

  /// Determina a cidade atual via GPS para usuários não logados.
  Future<void> determinarCidadePorGps() async {
    try {
      // 1. Obter coordenadas com timeout adaptado (maior na Web para dar tempo de aceitar a permissão)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, 
        timeLimit: const Duration(seconds: 4),
      );

      // 2. Tentar geocoding com timeout manual (pois a lib geocoding não tem nativo)
      final placemarks = await Future.any(<Future<List<Placemark>>>[
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
            // Persistir no Hive para próximas inicializações [CR2 - Recursos Nativos]
            await _hiveService.salvarCidadeFavorita(correspondente['codigo']!);
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

  Future<Map<String, dynamic>> cadastrarAgente({
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
      especialidade: especialidade,
    ));
    if (res['sucesso'] == true) {
      await carregarAgentes();
    }
    return res;
  }

  // ========== LOGIN & AUTH ==========

  Future<bool> login(String email, String senha) async {
    _setLoading(true);
    try {
      final response = await _apiService.login(email, senha);
      
      if (response != null) {
        final usuario = Usuario.fromJson(response['usuario']);
        final token = response['token'];

        // Salvar sessão segura (inclusive para coordenador pendente de homologação)
        await _storageService.salvarUsuarioLogado(usuario);
        await _storageService.salvarToken(token);

        _usuarioLogado = usuario;
        _isAdmin = usuario.role == Role.administrador || usuario.role == Role.superAdmin;

        // Sincronizar status vitalício com armazenamentos locais resilientes
        if (usuario.isSemAnunciosVitalicio) {
          await _hiveService.salvarStatusVitalicio(true);
          await _storageService.salvarStatusVitalicio(true);
        } else if (_hiveService.isSemAnunciosVitalicio || _storageService.obterStatusVitalicio()) {
          // Se o cache local tem registro mas o backend ainda não, sincroniza com o servidor
          _apiService.ativarSemAnunciosVitalicio();
        }
        
        // Registrar ID no OneSignal para receber push diretos
        if (!kIsWeb) {
          OneSignal.login(usuario.id);
          // Tag de cidade para segmentação de notificações [CR3 - Recursos Nativos]
          if (usuario.cidade != null && usuario.cidade!.isNotEmpty) {
            OneSignal.User.addTagWithKey('cidade', usuario.cidade!);
          }
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Erro ao fazer login: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> solicitarResetSenha(String email) async {
    return await _apiService.solicitarResetSenha(email);
  }

  Future<bool> resetarSenha(String email, String codigo, String novaSenha) async {
    return await _apiService.resetarSenha(email, codigo, novaSenha);
  }

  Future<Map<String, dynamic>> cadastrar(UsuarioRequest request) async {
    _setLoading(true);
    try {
      final response = await _apiService.cadastrarUsuario(request);
      if (response != null && response['sucesso'] != false) {
        // Auto-login imediato: salvar sessão se token e usuário foram retornados
        if (response['token'] != null && response['usuario'] != null) {
          final usuario = Usuario.fromJson(response['usuario']);
          final token = response['token'];

          await _storageService.salvarUsuarioLogado(usuario);
          await _storageService.salvarToken(token);

          _usuarioLogado = usuario;
          _isAdmin = usuario.role == Role.administrador || usuario.role == Role.superAdmin;

          if (!kIsWeb) {
            OneSignal.login(usuario.id);
            if (usuario.cidade != null && usuario.cidade!.isNotEmpty) {
              OneSignal.User.addTagWithKey('cidade', usuario.cidade!);
            }
          }
          notifyListeners();
        }

        return {
          'sucesso': true,
          'message': response['message'] ?? response['msg'] ?? 'Cadastro realizado com sucesso!',
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
      String erroMsg = 'Erro de conexão ou servidor. Verifique sua internet.';
      if (e.toString().contains('E-mail já cadastrado') || e.toString().contains('Exception:')) {
        erroMsg = e.toString().replaceAll('Exception: ', '');
      }
      return {'sucesso': false, 'message': erroMsg};
    } finally {
      _setLoading(false);
    }
  }

  /// Exclui a própria conta do usuário autenticado.
  /// Chama a API primeiro (precisa do token), depois faz logout local.
  Future<void> excluirMinhaConta() async {
    _setLoading(true);
    try {
      await _apiService.excluirMinhaConta();
      await logout();
    } catch (e) {
      if (kDebugMode) print('Erro ao excluir conta: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _storageService.limparSessao();
    // Limpar prefer\u00eancias do Hive ao sair [CR2 - Recursos Nativos]
    await _hiveService.limparPreferencias();
    _usuarioLogado = null;
    _isAdmin = false;
    _estaInicializado = false; // Reset essencial para evitar loop de carregamento
    _todosAgentes = [];
    _cidadesSuportadas = [];
    _cidadeDetectadaGps = null;
    if (!kIsWeb) {
      OneSignal.logout();
    }
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
      _isAdmin = logado.role == Role.administrador || logado.role == Role.superAdmin;

      // Sincronizar status vitalício com armazenamentos locais resilientes
      if (logado.isSemAnunciosVitalicio) {
        await _hiveService.salvarStatusVitalicio(true);
        await _storageService.salvarStatusVitalicio(true);
      } else if (_hiveService.isSemAnunciosVitalicio || _storageService.obterStatusVitalicio()) {
        _apiService.ativarSemAnunciosVitalicio();
      }

      if (_isAdmin) {
        carregarAgentes();
      }
      
      // Registrar ID no OneSignal para usuários que já estavam logados
      if (!kIsWeb) {
        OneSignal.login(logado.id);
        if (logado.cidade != null && logado.cidade!.isNotEmpty) {
          OneSignal.User.addTagWithKey('cidade', logado.cidade!);
        }
      }

      notifyListeners();
    }
  }

  /// Ativa a licença vitalícia sem anúncios vinculada a tudo (Hive, Storage e Backend)
  /// Valida obrigatoriamente a confirmação de pagamento junto à API / Stripe antes de autorizar.
  Future<bool> ativarAcessoVitalicio() async {
    try {
      if (!estaLogado) {
        return false;
      }

      // 1. Chama o backend, que valida se há pagamento confirmado na API do Stripe
      final sucesso = await _apiService.ativarSemAnunciosVitalicio();
      if (!sucesso) {
        if (kDebugMode) print('Pagamento não localizado no Stripe ou não aprovado.');
        return false;
      }

      // 2. Pagamento 100% confirmado: grava nos armazenamentos locais resilientes
      await _hiveService.salvarStatusVitalicio(true);
      await _storageService.salvarStatusVitalicio(true);

      if (_usuarioLogado != null) {
        final atualizado = Usuario(
          id: _usuarioLogado!.id,
          nome: _usuarioLogado!.nome,
          email: _usuarioLogado!.email,
          telefone: _usuarioLogado!.telefone,
          role: _usuarioLogado!.role,
          concordaLGPD: _usuarioLogado!.concordaLGPD,
          cidade: _usuarioLogado!.cidade,
          especialidade: _usuarioLogado!.especialidade,
          fcmToken: _usuarioLogado!.fcmToken,
          status: _usuarioLogado!.status,
          isSemAnunciosVitalicio: true,
          dataCriacao: _usuarioLogado!.dataCriacao,
        );
        _usuarioLogado = atualizado;
        await _storageService.salvarUsuarioLogado(atualizado);
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Erro ao ativar acesso vitalício: $e');
      return false;
    }
  }

  Future<void> carregarAgentes() async {
    try {
      String? originalCidade = _usuarioLogado?.cidade;
      String? cidadeBusca = originalCidade;
      
      // Mapeamento de Nome para Código
      if (cidadeBusca != null && cidadeBusca.isNotEmpty) {
        final searchCidade = cidadeBusca;
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
      
      // Fallback: se não encontrou com o código (ex: PIR), tenta pelo nome completo original (ex: PIRACAIA)
      if (agentes.isEmpty && originalCidade != null && originalCidade != cidadeBusca) {
        if (kDebugMode) print('🔄 Tentando fallback com nome original da cidade: $originalCidade');
        agentes = await _apiService.listarAgentes(cidade: originalCidade);
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
