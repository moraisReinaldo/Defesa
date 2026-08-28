import 'package:flutter/foundation.dart';
import '../models/ocorrencia.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';

class OcorrenciaProvider extends ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;
  final HiveService _hiveService;
  List<Ocorrencia> _ocorrencias = [];
  int _paginaAtual = 0;
  bool _temMais = true;
  bool _carregandoMais = false;
  final int _pageSize = 20;
  String _filtroTipoAtivo = 'TODOS';

  OcorrenciaProvider(this._storageService, this._apiService, this._hiveService) {
    // Restaurar filtro salvo no Hive [CR2 - Recursos Nativos]
    _filtroTipoAtivo = _hiveService.filtroTipo;
  }

  String get filtroTipoAtivo => _filtroTipoAtivo;

  /// Altera o filtro de tipo ativo e persiste no Hive.
  Future<void> setFiltroTipo(String tipo) async {
    _filtroTipoAtivo = tipo;
    await _hiveService.salvarFiltroTipo(tipo);
    notifyListeners();
  }

  List<Ocorrencia> get ocorrencias => _ocorrencias;
  bool get temMais => _temMais;
  bool get carregandoMais => _carregandoMais;

  List<Ocorrencia> get ocorrenciasAtivas =>
      _ocorrencias.where((o) => 
        (o.status == OcorrenciaStatus.aprovada || 
         o.status == OcorrenciaStatus.trabalhandoAtualmente ||
         o.status == OcorrenciaStatus.pendenteAprovacao ||
         o.isLocal) && o.status != OcorrenciaStatus.resolvida && o.status != OcorrenciaStatus.recusada
      ).toList();

  List<Ocorrencia> get ocorrenciasPendentes =>
      _ocorrencias.where((o) => o.status == OcorrenciaStatus.pendenteAprovacao).toList();

  List<Ocorrencia> get ocorrenciasResolvidas =>
      _ocorrencias.where((o) => o.status == OcorrenciaStatus.resolvida).toList();

  bool _mesmaCidade(String? c1, String? c2) {
    if (c1 == null || c2 == null || c1.isEmpty || c2.isEmpty) return false;
    final a = c1.trim().toUpperCase();
    final b = c2.trim().toUpperCase();
    if (a == b) return true;
    if ((a == 'PIR' || a == 'PIRACAIA') && (b == 'PIR' || b == 'PIRACAIA')) return true;
    if ((a == 'JOA' || a == 'JOANOPOLIS' || a == 'JOANÓPOLIS') && (b == 'JOA' || b == 'JOANOPOLIS' || b == 'JOANÓPOLIS')) return true;
    if ((a == 'ATI' || a == 'ATIBAIA') && (b == 'ATI' || b == 'ATIBAIA')) return true;
    if ((a == 'BP' || a.contains('BRAG')) && (b == 'BP' || b.contains('BRAG'))) return true;
    if ((a == 'NAZ' || a.contains('NAZA')) && (b == 'NAZ' || b.contains('NAZA'))) return true;
    if ((a == 'TUI' || a == 'TUIUTI') && (b == 'TUI' || b == 'TUIUTI')) return true;
    if ((a == 'VAR' || a == 'VARGEM') && (b == 'VAR' || b == 'VARGEM')) return true;
    return a.contains(b) || b.contains(a);
  }

  Future<void> carregarOcorrencias({String? cidade, String? userId, bool isAdmin = false}) async {
    _paginaAtual = 0;
    _temMais = true;
    _carregandoMais = false;

    final String? cidadeFiltro = (cidade != null && cidade.trim().isNotEmpty) ? cidade.trim() : null;

    try {
      // SEMPRE busca do servidor primeiro — fonte da verdade
      final vindoDaApi = await _apiService.listarOcorrencias(
        cidade: cidadeFiltro,
        page: _paginaAtual,
        size: _pageSize,
      );

      _ocorrencias = vindoDaApi
          .where((o) => 
            (cidadeFiltro == null) || 
            _mesmaCidade(o.cidade, cidadeFiltro) || 
            (userId != null && o.usuarioId == userId))
          .toList();
      _temMais = vindoDaApi.length >= _pageSize;

      // Atualizar storage local com os dados do servidor (sobrescreve itens locais sincronizados)
      final idsDoServidor = _ocorrencias.map((o) => o.id).toSet();
      final localAntes = await _storageService.obterOcorrencias();

      // Limpar do cache local ocorrências que foram deletadas no servidor
      // (existiam no cache local como sincronizadas, mas não vieram mais na API)
      for (final localOc in localAntes) {
        if (!idsDoServidor.contains(localOc.id) && !localOc.isLocal) {
          await _storageService.deletarOcorrencia(localOc.id);
        }
      }

      // Manter apenas ocorrências locais que nunca foram sincronizadas (criadas offline)
      final localNaoSincronizadas = localAntes
          .where((o) => !idsDoServidor.contains(o.id) && o.isLocal &&
              ((cidadeFiltro == null) || 
               _mesmaCidade(o.cidade, cidadeFiltro) || 
               (userId != null && o.usuarioId == userId)))
          .map((o) => o.copyWith(isLocal: true))
          .toList();

      // Combina: servidor primeiro, depois locais não sincronizadas (com badge)
      _ocorrencias = [..._ocorrencias, ...localNaoSincronizadas];

      // Atualiza cache local
      for (var oc in _ocorrencias.where((o) => !o.isLocal)) {
        await _storageService.salvarOcorrencia(oc);
      }
    } catch (e) {
      // Sem internet — usa cache local e marca todos como locais
      if (kDebugMode) print('⚠️ Offline: usando cache local. Erro: $e');
      final local = await _storageService.obterOcorrencias();
      _ocorrencias = local
          .where((o) => 
            (cidade == null || cidade.isEmpty) || 
            _mesmaCidade(o.cidade, cidade) || 
            (userId != null && o.usuarioId == userId))
          .map((o) => o.copyWith(isLocal: true))
          .toList();
    }
    notifyListeners();
  }

  Future<void> carregarMaisOcorrencias({String? cidade, String? userId, bool isAdmin = false}) async {
    if (!_temMais || _carregandoMais) return;
    
    _carregandoMais = true;
    notifyListeners();

    final String? cidadeFiltro = (cidade != null && cidade.trim().isNotEmpty) ? cidade.trim() : null;

    try {
      _paginaAtual++;
      final vindoDaApi = await _apiService.listarOcorrencias(
        cidade: cidadeFiltro, 
        page: _paginaAtual, 
        size: _pageSize
      );
      
      final novos = vindoDaApi
          .where((o) => 
            (cidadeFiltro == null) || 
            _mesmaCidade(o.cidade, cidadeFiltro) || 
            (userId != null && o.usuarioId == userId))
          .toList();
      
      // Evitar duplicatas
      final idsExistentes = _ocorrencias.map((o) => o.id).toSet();
      final filtrados = novos.where((o) => !idsExistentes.contains(o.id)).toList();
      
      _ocorrencias.addAll(filtrados);
      _temMais = vindoDaApi.length >= _pageSize;

      for (var oc in filtrados) {
        await _storageService.salvarOcorrencia(oc);
      }
    } catch (e) {
      _temMais = false;
    } finally {
      _carregandoMais = false;
      notifyListeners();
    }
  }

  Future<void> adicionarOcorrencia(Ocorrencia ocorrencia) async {
    try {
      final salvaNaApi = await _apiService.criarOcorrencia(ocorrencia);
      if (salvaNaApi != null) {
        _ocorrencias.add(salvaNaApi);
        notifyListeners();
      }
      // Sem fallback — se a API retornou null inesperadamente, lançamos erro
      // para o usuário saber que algo errado aconteceu
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      // Fallback LOCAL apenas em erros reais de conectividade (sem internet)
      final isSemInternet = msg.contains('connection') ||
          msg.contains('timeout') ||
          msg.contains('sem conexão') ||
          msg.contains('connect_error');

      if (isSemInternet) {
        await _storageService.salvarOcorrencia(ocorrencia);
        _ocorrencias.add(ocorrencia);
        notifyListeners();
      } else {
        // Erros de autenticação (401), permissão (403), validação, etc.
        // Re-lançar para que a tela exiba a mensagem correta ao usuário
        rethrow;
      }
    }
  }

  Future<void> aprovarOcorrencia(String id) async {
    try {
      final atualizada = await _apiService.aprovarOcorrencia(id);
      if (atualizada != null) {
        final index = _ocorrencias.indexWhere((o) => o.id == id);
        if (index != -1) {
          _ocorrencias[index] = atualizada;
          await _storageService.salvarOcorrencia(atualizada);
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao aprovar: $e");
    }
  }

  Future<void> registrarChegadaAgente(String id, {String? parecer}) async {
    final vindoDaApi = await _apiService.registrarChegadaAgente(id, parecer: parecer);
    if (vindoDaApi != null) {
      final index = _ocorrencias.indexWhere((o) => o.id == id);
      if (index != -1) {
        _ocorrencias[index] = vindoDaApi;
        await _storageService.salvarOcorrencia(vindoDaApi);
        notifyListeners();
      }
    }
  }

  Future<void> atualizarOcorrencia(Ocorrencia ocorrencia) async {
    try {
      final vindoDaApi = await _apiService.atualizarOcorrencia(ocorrencia);
      if (vindoDaApi != null) {
        final index = _ocorrencias.indexWhere((o) => o.id == vindoDaApi.id);
        if (index != -1) {
          _ocorrencias[index] = vindoDaApi;
          await _storageService.atualizarOcorrencia(vindoDaApi);
          notifyListeners();
        }
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isSemInternet = msg.contains('connection') || msg.contains('timeout') || msg.contains('sem conexão') || msg.contains('connect_error');
      
      if (isSemInternet) {
        if (kDebugMode) print("Sem internet: atualizando ocorrência no fallback local. $e");
        await _storageService.atualizarOcorrencia(ocorrencia);
        final index = _ocorrencias.indexWhere((o) => o.id == ocorrencia.id);
        if (index != -1) {
          _ocorrencias[index] = ocorrencia;
          notifyListeners();
        }
      } else {
        if (kDebugMode) print("Erro da API ao atualizar ocorrência: $e");
      }
      rethrow;
    }
  }

  Future<void> deletarOcorrencia(String id) async {
    try {
      await _apiService.deletarOcorrencia(id);
      await _storageService.deletarOcorrencia(id);
      _ocorrencias.removeWhere((o) => o.id == id);
      notifyListeners();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isSemInternet = msg.contains('connection') || msg.contains('timeout') || msg.contains('sem conexão') || msg.contains('connect_error');
      
      if (isSemInternet) {
        if (kDebugMode) print("Sem internet, mantendo experiência offline (apenas alerta do erro ao deletar). Erro: $e");
        await _storageService.deletarOcorrencia(id);
        _ocorrencias.removeWhere((o) => o.id == id);
        notifyListeners();
      } else {
        if (kDebugMode) print("Erro da API ao deletar ocorrência: $e");
      }
      rethrow;
    }
  }

  Future<void> resolverOcorrencia(String id, {String? parecer}) async {
    final index = _ocorrencias.indexWhere((o) => o.id == id);
    Ocorrencia? backup;
    
    if (index != -1) {
      backup = _ocorrencias[index];
      _ocorrencias[index] = backup.copyWith(status: OcorrenciaStatus.resolvida);
      notifyListeners();
    }

    try {
      final vindoDaApi = await _apiService.resolverOcorrencia(id, parecer: parecer);
      if (vindoDaApi != null && index != -1) {
        _ocorrencias[index] = vindoDaApi;
        await _storageService.atualizarOcorrencia(vindoDaApi);
        notifyListeners();
      }
    } catch (e) {
      if (backup != null && index != -1) {
        _ocorrencias[index] = backup;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> reativarOcorrencia(String id) async {
    final index = _ocorrencias.indexWhere((o) => o.id == id);
    Ocorrencia? backup;

    if (index != -1) {
      backup = _ocorrencias[index];
      _ocorrencias[index] = backup.copyWith(status: OcorrenciaStatus.aprovada);
      notifyListeners();
    }

    try {
      final vindoDaApi = await _apiService.reativarOcorrencia(id);
      if (vindoDaApi != null && index != -1) {
        _ocorrencias[index] = vindoDaApi;
        await _storageService.atualizarOcorrencia(vindoDaApi);
        notifyListeners();
      }
    } catch (e) {
      if (backup != null && index != -1) {
        _ocorrencias[index] = backup;
        notifyListeners();
      }
      rethrow;
    }
  }

  // Removido histórico de comentários
  List<Ocorrencia> obterOcorrenciasDoUsuario(String usuarioId) {
    return _ocorrencias.where((o) => o.usuarioId == usuarioId).toList();
  }

  List<Ocorrencia> filtrarPorTipo(String tipo) {
    return _ocorrencias.where((o) => o.tipo == tipo).toList();
  }

  /// Retorna ocorrências filtradas pelo tipo ativo (salvo no Hive).
  List<Ocorrencia> get ocorrenciasFiltradas {
    if (_filtroTipoAtivo == 'TODOS') return _ocorrencias;
    return _ocorrencias.where((o) => o.tipo == _filtroTipoAtivo).toList();
  }

  Ocorrencia? obterOcorrenciaPorId(String id) {
    try {
      return _ocorrencias.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }
}
