import 'package:flutter/foundation.dart';
import '../services/alerta_service.dart';
import '../services/api_service.dart';

class AlertaProvider extends ChangeNotifier {
  final ApiService _apiService;
  late final AlertaService _alertaService;

  List<AlertaEmergencia> _alertasAtivos = [];
  bool _carregando = false;
  String? _cidadeFiltro;

  AlertaProvider(this._apiService) {
    // AlertaService usa ApiClient interno do ApiService
    _alertaService = AlertaService(_apiService.client);
  }

  List<AlertaEmergencia> get alertasAtivos => _alertasAtivos;
  bool get carregando => _carregando;
  bool get temAlertaAtivo => _alertasAtivos.isNotEmpty;
  String? get cidadeFiltro => _cidadeFiltro;

  Future<void> carregarAlertas({String? cidade}) async {
    _cidadeFiltro = cidade;
    _carregando = true;
    notifyListeners();

    try {
      _alertasAtivos = await _alertaService.buscarAlertasAtivos(cidade: cidade);
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar alertas: $e');
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<bool> emitirAlerta({
    required String cidade,
    required String titulo,
    required String mensagem,
    required String nivel,
  }) async {
    _carregando = true;
    notifyListeners();

    try {
      final novo = AlertaEmergencia(
        cidade: cidade,
        titulo: titulo,
        mensagem: mensagem,
        nivel: nivel,
      );

      final salvo = await _alertaService.emitirAlerta(novo);
      if (salvo != null) {
        _alertasAtivos.insert(0, salvo);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Erro ao emitir alerta: $e');
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> cancelarAlerta(String id) async {
    try {
      await _alertaService.cancelarAlerta(id);
      _alertasAtivos.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Erro ao cancelar alerta: $e');
    }
  }
}
