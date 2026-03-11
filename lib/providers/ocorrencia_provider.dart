import 'package:flutter/material.dart';
import '../models/ocorrencia.dart';
import '../models/comentario.dart';
import '../services/storage_service.dart';

class OcorrenciaProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<Ocorrencia> _ocorrencias = [];

  OcorrenciaProvider(this._storageService);

  List<Ocorrencia> get ocorrencias => _ocorrencias;

  List<Ocorrencia> get ocorrenciasAtivas =>
      _ocorrencias.where((o) => !o.resolvida).toList();

  List<Ocorrencia> get ocorrenciasResolvidas =>
      _ocorrencias.where((o) => o.resolvida).toList();

  Future<void> carregarOcorrencias() async {
    _ocorrencias = await _storageService.obterOcorrencias();
    notifyListeners();
  }

  Future<void> adicionarOcorrencia(Ocorrencia ocorrencia) async {
    await _storageService.salvarOcorrencia(ocorrencia);
    _ocorrencias.add(ocorrencia);
    notifyListeners();
  }

  Future<void> atualizarOcorrencia(Ocorrencia ocorrencia) async {
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
      dataResolucao: DateTime.now(),
    );
    await atualizarOcorrencia(atualizada);
  }

  Future<void> adicionarComentario(String ocorrenciaId, Comentario comentario) async {
    final ocorrencia = _ocorrencias.firstWhere((o) => o.id == ocorrenciaId);
    final comentariosAtualizados = List<Comentario>.from(ocorrencia.comentarios)..add(comentario);
    final atualizada = ocorrencia.copyWith(comentarios: comentariosAtualizados);
    await atualizarOcorrencia(atualizada);
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
