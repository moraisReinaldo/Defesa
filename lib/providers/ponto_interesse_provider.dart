import 'package:flutter/foundation.dart';
import '../models/ponto_interesse.dart';
import '../services/api_service.dart';

class PontoInteresseProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<PontoInteresse> _pontos = [];

  PontoInteresseProvider(this._apiService);

  List<PontoInteresse> get pontos => _pontos;

  Future<void> carregarPontos({String? cidade}) async {
    try {
      final vindoDaApi = await _apiService.listarPontosInteresse(cidade: cidade);
      _pontos = vindoDaApi;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar pontos de interesse: $e');
    }
  }

  Future<void> adicionarPonto(PontoInteresse ponto) async {
    try {
      final salvo = await _apiService.criarPontoInteresse(ponto);
      if (salvo != null) {
        _pontos.add(salvo);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao adicionar ponto de interesse: $e');
    }
  }

  Future<void> deletarPonto(String id) async {
    try {
      final sucesso = await _apiService.deletarPontoInteresse(id);
      if (sucesso) {
        _pontos.removeWhere((p) => p.id == id);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao deletar ponto de interesse: $e');
    }
  }
}
