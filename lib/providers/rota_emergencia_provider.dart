import 'package:flutter/foundation.dart';
import '../models/rota_emergencia.dart';
import '../services/rota_emergencia_service.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';

class RotaEmergenciaProvider extends ChangeNotifier {
  final ApiService _apiService;
  late final RotaEmergenciaService _rotaService;

  List<RotaEmergencia> _rotas = [];
  bool _carregando = false;
  String? _cidadeFiltro;

  // Modo Navegação estilo Google Maps
  RotaEmergencia? _rotaNavegacaoAtiva;
  bool _modoNavegacao = false;

  RotaEmergenciaProvider(this._apiService, [HiveService? hiveService]) {
    _rotaService = RotaEmergenciaService(_apiService.client, hiveService);
  }

  List<RotaEmergencia> get rotas => _rotas;
  List<RotaEmergencia> get rotasAtivas => _rotas.where((r) => r.ativa).toList();
  bool get carregando => _carregando;
  String? get cidadeFiltro => _cidadeFiltro;

  RotaEmergencia? get rotaNavegacaoAtiva => _rotaNavegacaoAtiva;
  bool get modoNavegacao => _modoNavegacao;

  Future<void> carregarRotas({String? cidade, bool apenasAtivas = false}) async {
    _cidadeFiltro = cidade;
    _carregando = true;
    notifyListeners();

    try {
      _rotas = await _rotaService.buscarRotas(cidade: cidade, apenasAtivas: apenasAtivas);
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar rotas no provider: $e');
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<RotaEmergencia?> criarRota(RotaEmergencia rota) async {
    _carregando = true;
    notifyListeners();

    try {
      final nova = await _rotaService.criarRota(rota);
      if (nova != null) {
        _rotas.insert(0, nova);
        notifyListeners();
        return nova;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Erro ao criar rota no provider: $e');
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<RotaEmergencia?> atualizarRota(RotaEmergencia rota) async {
    _carregando = true;
    notifyListeners();

    try {
      final atualizada = await _rotaService.atualizarRota(rota);
      if (atualizada != null) {
        final idx = _rotas.indexWhere((r) => r.id == rota.id);
        if (idx != -1) {
          _rotas[idx] = atualizada;
        }
        if (_rotaNavegacaoAtiva?.id == rota.id) {
          _rotaNavegacaoAtiva = atualizada;
        }
        notifyListeners();
        return atualizada;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Erro ao atualizar rota no provider: $e');
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> alternarStatus(String id, bool ativa) async {
    try {
      final atualizada = await _rotaService.alternarStatus(id, ativa);
      if (atualizada != null) {
        final idx = _rotas.indexWhere((r) => r.id == id);
        if (idx != -1) {
          _rotas[idx] = atualizada;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao alternar status da rota: $e');
      rethrow;
    }
  }

  Future<void> deletarRota(String id) async {
    try {
      await _rotaService.deletarRota(id);
      _rotas.removeWhere((r) => r.id == id);
      if (_rotaNavegacaoAtiva?.id == id) {
        pararNavegacao();
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Erro ao deletar rota: $e');
      rethrow;
    }
  }

  void iniciarNavegacao(RotaEmergencia rota) {
    _rotaNavegacaoAtiva = rota;
    _modoNavegacao = true;
    notifyListeners();
  }

  void pararNavegacao() {
    _rotaNavegacaoAtiva = null;
    _modoNavegacao = false;
    notifyListeners();
  }
}
