import 'package:flutter/foundation.dart';
import '../models/ocorrencia.dart';
import '../models/comentario.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class OcorrenciaProvider extends ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;
  List<Ocorrencia> _ocorrencias = [];

  OcorrenciaProvider(this._storageService, this._apiService);

  List<Ocorrencia> get ocorrencias => _ocorrencias;

  List<Ocorrencia> get ocorrenciasAtivas =>
      _ocorrencias.where((o) => 
        (o.status == OcorrenciaStatus.aprovada || o.status == OcorrenciaStatus.trabalhandoAtualmente) && o.status != OcorrenciaStatus.resolvida
      ).toList();

  List<Ocorrencia> get ocorrenciasPendentes =>
      _ocorrencias.where((o) => o.status == OcorrenciaStatus.pendenteAprovacao).toList();

  List<Ocorrencia> get ocorrenciasResolvidas =>
      _ocorrencias.where((o) => o.status == OcorrenciaStatus.resolvida).toList();

  Future<void> carregarOcorrencias({String? cidade}) async {
    try {
      final vindoDaApi = await _apiService.listarOcorrencias(cidade: cidade);
      if (vindoDaApi.isNotEmpty) {
        _ocorrencias = vindoDaApi;
      } else {
        final local = await _storageService.obterOcorrencias();
        _ocorrencias = (cidade != null && cidade.isNotEmpty) 
            ? local.where((o) => o.cidade == cidade).toList()
            : local;
      }
    } catch (e) {
      final local = await _storageService.obterOcorrencias();
      _ocorrencias = (cidade != null && cidade.isNotEmpty) 
          ? local.where((o) => o.cidade == cidade).toList()
          : local;
    }
    notifyListeners();
  }

  Future<void> adicionarOcorrencia(Ocorrencia ocorrencia) async {
    try {
      final salvaNaApi = await _apiService.criarOcorrencia(ocorrencia);
      if (salvaNaApi != null) {
        _ocorrencias.add(salvaNaApi);
      } else {
        // Fallback local se estiver sem internet
        await _storageService.salvarOcorrencia(ocorrencia);
        _ocorrencias.add(ocorrencia);
      }
    } catch (e) {
      await _storageService.salvarOcorrencia(ocorrencia);
      _ocorrencias.add(ocorrencia);
    }
    notifyListeners();
  }

  Future<void> aprovarOcorrencia(String id) async {
    try {
      final atualizada = await _apiService.aprovarOcorrencia(id);
      if (atualizada != null) {
        final index = _ocorrencias.indexWhere((o) => o.id == id);
        if (index != -1) {
          _ocorrencias[index] = atualizada;
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
      // Fallback local se a API falhar (mantém viva a experiência off-line, mas avisa no log)
      if (kDebugMode) print("Erro ao atualizar ocorrência na API: $e");
      await _storageService.atualizarOcorrencia(ocorrencia);
      final index = _ocorrencias.indexWhere((o) => o.id == ocorrencia.id);
      if (index != -1) {
        _ocorrencias[index] = ocorrencia;
        notifyListeners();
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
      if (kDebugMode) print("Erro ao deletar ocorrência na API: $e");
      // Fallback local
      await _storageService.deletarOcorrencia(id);
      _ocorrencias.removeWhere((o) => o.id == id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resolverOcorrencia(String id, {String? parecer}) async {
    final vindoDaApi = await _apiService.resolverOcorrencia(id, parecer: parecer);
    if (vindoDaApi != null) {
      final index = _ocorrencias.indexWhere((o) => o.id == id);
      if (index != -1) {
        _ocorrencias[index] = vindoDaApi;
        await _storageService.atualizarOcorrencia(vindoDaApi);
        notifyListeners();
      }
    }
  }

  Future<void> reativarOcorrencia(String id) async {
    final vindoDaApi = await _apiService.reativarOcorrencia(id);
    if (vindoDaApi != null) {
      final index = _ocorrencias.indexWhere((o) => o.id == id);
      if (index != -1) {
        _ocorrencias[index] = vindoDaApi;
        await _storageService.atualizarOcorrencia(vindoDaApi);
        notifyListeners();
      }
    }
  }

  Future<void> adicionarComentario(String ocorrenciaId, Comentario comentario) async {
    final ocorrencia = _ocorrencias.firstWhere((o) => o.id == ocorrenciaId);
    final comentariosAtualizados = List<Comentario>.from(ocorrencia.comentarios)..add(comentario);
    final atualizada = ocorrencia.copyWith(comentarios: comentariosAtualizados);
    
    await _storageService.atualizarOcorrencia(atualizada);
    final index = _ocorrencias.indexWhere((o) => o.id == ocorrenciaId);
    if (index != -1) {
      _ocorrencias[index] = atualizada;
      notifyListeners();
    }
  }

  List<Ocorrencia> obterOcorrenciasDoUsuario(String usuarioId) {
    return _ocorrencias.where((o) => o.usuarioId == usuarioId).toList();
  }

  List<Ocorrencia> filtrarPorTipo(String tipo) {
    return _ocorrencias.where((o) => o.tipo == tipo).toList();
  }

  Ocorrencia? obterOcorrenciaPorId(String id) {
    try {
      return _ocorrencias.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }
}
