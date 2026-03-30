import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
        o.status == OcorrenciaStatus.APROVADA && !o.resolvida
      ).toList();

  List<Ocorrencia> get ocorrenciasPendentes =>
      _ocorrencias.where((o) => o.status == OcorrenciaStatus.PENDENTE_APROVACAO).toList();

  List<Ocorrencia> get ocorrenciasResolvidas =>
      _ocorrencias.where((o) => o.resolvida).toList();

  Future<void> carregarOcorrencias() async {
    // Tenta carregar da API primeiro, se falhar ou estiver Offline, usa o storage local
    try {
      final vindoDaApi = await _apiService.listarOcorrencias();
      if (vindoDaApi.isNotEmpty) {
        _ocorrencias = vindoDaApi;
        // Opcional: Atualizar storage local com o que veio da API
      } else {
        _ocorrencias = await _storageService.obterOcorrencias();
      }
    } catch (e) {
      _ocorrencias = await _storageService.obterOcorrencias();
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

  Future<void> registrarChegadaAgente(String id) async {
    try {
      final atualizada = await _apiService.registrarChegadaAgente(id);
      if (atualizada != null) {
        final index = _ocorrencias.indexWhere((o) => o.id == id);
        if (index != -1) {
          _ocorrencias[index] = atualizada;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao registrar chegada: $e");
    }
  }

  Future<void> atualizarOcorrencia(Ocorrencia ocorrencia) async {
    // Para simplificar, usamos o storage local e se possível a API (precisaria de endpoint de PUT)
    await _storageService.atualizarOcorrencia(ocorrencia);
    final index = _ocorrencias.indexWhere((o) => o.id == ocorrencia.id);
    if (index != -1) {
      _ocorrencias[index] = ocorrencia;
      notifyListeners();
    }
  }

  Future<void> deletarOcorrencia(String id) async {
    await _storageService.deletarOcorrencia(id);
    _ocorrencias.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  Future<void> resolverOcorrencia(String id) async {
    final ocorrencia = _ocorrencias.firstWhere((o) => o.id == id);
    final atualizada = ocorrencia.copyWith(
      resolvida: true,
      status: OcorrenciaStatus.RESOLVIDA,
      dataResolucao: DateTime.now(),
    );
    
    // Idealmente chamar API aqui também
    await _storageService.atualizarOcorrencia(atualizada);
    final index = _ocorrencias.indexWhere((o) => o.id == id);
    if (index != -1) {
      _ocorrencias[index] = atualizada;
      notifyListeners();
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
