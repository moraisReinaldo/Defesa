import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DadosClimaticos {
  final double temperatura;
  final double umidade;
  final double velocidadeVento;
  final double precipitacaoAtual;
  final double chuvaAcumulada24h;
  final double chuvaAcumulada48h;
  final double chuvaAcumulada72h;
  final DateTime dataHora;

  DadosClimaticos({
    required this.temperatura,
    required this.umidade,
    required this.velocidadeVento,
    required this.precipitacaoAtual,
    required this.chuvaAcumulada24h,
    required this.chuvaAcumulada48h,
    required this.chuvaAcumulada72h,
    DateTime? dataHora,
  }) : dataHora = dataHora ?? DateTime.now();

  double get chuvaHoje => chuvaAcumulada24h;

  /// Regra 30-30-30 da Defesa Civil:
  /// Temp > 30°C AND Umidade < 30% AND Vento > 30km/h
  bool get regra303030Ativa =>
      temperatura >= 30.0 && umidade <= 30.0 && velocidadeVento >= 30.0;

  factory DadosClimaticos.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final daily = json['daily'] as Map<String, dynamic>? ?? {};

    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 25.0;
    final umid = (current['relative_humidity_2m'] as num?)?.toDouble() ?? 50.0;
    final vento = (current['wind_speed_10m'] as num?)?.toDouble() ?? 12.0;
    final prec = (current['precipitation'] as num?)?.toDouble() ?? 0.0;

    // Chuva acumulada nos últimos dias (a partir de daily['precipitation_sum'])
    final precipSumList = (daily['precipitation_sum'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];

    double c24 = 0;
    double c48 = 0;
    double c72 = 0;

    if (precipSumList.isNotEmpty) {
      c24 = precipSumList.first;
      if (precipSumList.length >= 2) {
        c48 = c24 + precipSumList[1];
      } else {
        c48 = c24;
      }
      if (precipSumList.length >= 3) {
        c72 = c48 + precipSumList[2];
      } else {
        c72 = c48;
      }
    }

    return DadosClimaticos(
      temperatura: temp,
      umidade: umid,
      velocidadeVento: vento,
      precipitacaoAtual: prec,
      chuvaAcumulada24h: c24,
      chuvaAcumulada48h: c48,
      chuvaAcumulada72h: c72,
    );
  }
}

class ClimaService {
  final Dio _dio = Dio();

  static const Map<String, Map<String, double>> _coordenadasCidades = {
    'ATI': {'lat': -23.1169, 'lng': -46.5503}, // Atibaia
    'BP': {'lat': -22.9525, 'lng': -46.5419},  // Bragança Paulista
    'JOA': {'lat': -22.9292, 'lng': -46.2753}, // Joanópolis
    'NAZ': {'lat': -23.1811, 'lng': -46.3975}, // Nazaré Paulista
    'PIR': {'lat': -23.0539, 'lng': -46.3575}, // Piracaia
    'TUI': {'lat': -22.8161, 'lng': -46.6806}, // Tuiuti
    'VAR': {'lat': -22.8889, 'lng': -46.4131}, // Vargem
  };

  static Map<String, double> obterCoordenadasCidade(String? codigoOuNome) {
    if (codigoOuNome == null || codigoOuNome.isEmpty) {
      return {'lat': -22.9525, 'lng': -46.5419}; // Default Bragança
    }

    final key = codigoOuNome.trim().toUpperCase();
    if (_coordenadasCidades.containsKey(key)) {
      return _coordenadasCidades[key]!;
    }

    // Busca aproximada por nome
    if (key.contains('ATIBAIA')) return _coordenadasCidades['ATI']!;
    if (key.contains('BRAGAN') || key.contains('PAULISTA')) return _coordenadasCidades['BP']!;
    if (key.contains('JOAN')) return _coordenadasCidades['JOA']!;
    if (key.contains('NAZAR')) return _coordenadasCidades['NAZ']!;
    if (key.contains('PIRACAIA')) return _coordenadasCidades['PIR']!;
    if (key.contains('TUIUTI')) return _coordenadasCidades['TUI']!;
    if (key.contains('VARGEM')) return _coordenadasCidades['VAR']!;

    return {'lat': -22.9525, 'lng': -46.5419};
  }

  Future<DadosClimaticos?> buscarClimaCidade(String? codigoOuNome) async {
    final coords = obterCoordenadasCidade(codigoOuNome);
    final lat = coords['lat']!;
    final lng = coords['lng']!;

    try {
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation&daily=precipitation_sum&timezone=America%2FSao_Paulo&past_days=3';

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return DadosClimaticos.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('🚨 Erro ao buscar clima Open-Meteo: $e');
      return null;
    }
  }
}
