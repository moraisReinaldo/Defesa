import 'package:flutter/foundation.dart';
import '../models/cidade.dart';
import '../services/api_service.dart';

class CidadeProvider extends ChangeNotifier {
  final ApiService _apiService;

  Cidade? _cidadeAtiva;
  bool _carregando = false;

  CidadeProvider(this._apiService);

  Cidade? get cidadeAtiva => _cidadeAtiva;
  bool get carregando => _carregando;

  PlanoCidade get planoAtual => _cidadeAtiva?.planoEfetivo ?? PlanoCidade.baseGratuito;
  StatusCidade get statusAtual => _cidadeAtiva?.status ?? StatusCidade.pendenteAprovacao;
  bool get isTrialAtivo => _cidadeAtiva?.isTrialAtivo ?? false;
  int get diasRestantesTrial => _cidadeAtiva?.diasRestantesTrial ?? 0;

  bool get recursoAgentesLiberado => _cidadeAtiva?.recursoAgentesLiberado ?? false;
  bool get recursoPoiLiberado => _cidadeAtiva?.recursoPoiLiberado ?? false;
  bool get recursoDashboardWebLiberado => _cidadeAtiva?.recursoDashboardWebLiberado ?? false;
  bool get recursoAlertasLiberado => _cidadeAtiva?.recursoAlertasLiberado ?? false;
  bool get recursoCobradeOficialLiberado => _cidadeAtiva?.recursoCobradeOficialLiberado ?? false;
  bool get deveExibirAnuncios => _cidadeAtiva?.deveExibirAnuncios ?? true;

  Future<void> carregarPlanoCidade(String? codigoOuNome) async {
    if (codigoOuNome == null || codigoOuNome.trim().isEmpty) return;
    _carregando = true;
    notifyListeners();

    try {
      final cidade = await _apiService.buscarCidadePorCodigo(codigoOuNome.trim());
      if (cidade != null) {
        _cidadeAtiva = cidade;
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar plano da cidade: $e');
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void atualizarCidade(Cidade cidade) {
    _cidadeAtiva = cidade;
    notifyListeners();
  }
}
