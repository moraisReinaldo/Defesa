import 'package:flutter/foundation.dart';
import '../services/clima_service.dart';
import '../services/hive_service.dart';

class ClimaProvider extends ChangeNotifier {
  final ClimaService _climaService = ClimaService();

  DadosClimaticos? _dados;
  bool _carregando = false;
  String? _cidadeAtual;

  static const double limiteChuvaDiariaPadrao = 50.0; // 50mm em 24h
  static const double limiteChuva72hPadrao = 80.0;   // 80mm em 72h

  ClimaProvider([HiveService? _]);

  DadosClimaticos? get dados => _dados;
  bool get carregando => _carregando;
  String? get cidadeAtual => _cidadeAtual;

  bool get alertaChuvaDiariaCritica =>
      _dados != null && _dados!.chuvaHoje >= limiteChuvaDiariaPadrao;

  bool get alertaChuva72hCritica =>
      _dados != null && _dados!.chuvaAcumulada72h >= limiteChuva72hPadrao;

  bool get alertaChuvaAcumuladaCritica =>
      alertaChuvaDiariaCritica || alertaChuva72hCritica;

  bool get regra303030Ativa => _dados?.regra303030Ativa ?? false;

  Future<void> carregarClima(String? cidade) async {
    if (_cidadeAtual == cidade && _dados != null) return;
    _cidadeAtual = cidade;
    _carregando = true;
    notifyListeners();

    try {
      _dados = await _climaService.buscarClimaCidade(cidade);
    } catch (e) {
      if (kDebugMode) print('Erro no ClimaProvider: $e');
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> atualizar() async {
    if (_cidadeAtual != null) {
      _carregando = true;
      notifyListeners();
      _dados = await _climaService.buscarClimaCidade(_cidadeAtual);
      _carregando = false;
      notifyListeners();
    }
  }
}
