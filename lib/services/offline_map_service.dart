import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineMapService {
  static final OfflineMapService _instance = OfflineMapService._internal();
  factory OfflineMapService() => _instance;
  OfflineMapService._internal();

  static const String storeName = 'defesa_civil_map';
  bool _initialized = false;
  FMTCStore? _store;
  bool _isDownloading = false;

  bool get isDownloading => _isDownloading;
  bool get isInitialized => _initialized && _store != null;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await FMTCObjectBoxBackend().initialise();
      _store = FMTCStore(storeName);
      await _store!.manage.create();
      _initialized = true;
      if (kDebugMode) print('FMTC inicializado com sucesso.');
    } catch (e) {
      if (kDebugMode) print('Erro ao inicializar FMTC: $e');
    }
  }

  TileProvider? getTileProvider() {
    if (!_initialized || _store == null || kIsWeb) {
      return null;
    }
    return _store!.getTileProvider();
  }

  /// Garante que o mapa da cidade esteja baixado localmente para uso offline.
  /// Baixa automaticamente se for a primeira vez que a cidade é aberta no app.
  Future<void> garantirMapaCidade(String? cidadeNome, double lat, double lng) async {
    if (kIsWeb || !_initialized || _store == null) return;
    if (cidadeNome == null || cidadeNome.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final chave = 'mapa_offline_baixado_${cidadeNome.toLowerCase().replaceAll(" ", "_")}';
      final jaBaixado = prefs.getBool(chave) ?? false;

      if (jaBaixado) {
        if (kDebugMode) print('Mapa offline de $cidadeNome já está no cache.');
        return;
      }

      await baixarRegiaoCidade(lat, lng, nomeCidade: cidadeNome);
      await prefs.setBool(chave, true);
    } catch (e) {
      if (kDebugMode) print('Erro ao verificar/garantir mapa da cidade: $e');
    }
  }

  Future<void> baixarRegiaoCidade(double lat, double lng, {String? nomeCidade}) async {
    if (!_initialized || _store == null || kIsWeb || _isDownloading) return;

    try {
      _isDownloading = true;
      if (kDebugMode) print('Iniciando download offline do mapa para: ${nomeCidade ?? "região"} ($lat, $lng)');

      final region = CircleRegion(
        LatLng(lat, lng),
        5.0, // 5 km de raio
      );

      final downloadStream = _store!.download.startForeground(
        region: region.toDownloadable(
          minZoom: 12,
          maxZoom: 15,
          options: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.defesacivil.app',
          ),
        ),
      );

      downloadStream.listen(
        (progress) {
          // Acompanhamento em background silencioso
        },
        onError: (err) {
          _isDownloading = false;
          if (kDebugMode) print('Aviso no download do mapa offline: $err');
        },
        onDone: () {
          _isDownloading = false;
          if (kDebugMode) print('Download do mapa offline concluído para ${nomeCidade ?? "cidade"}.');
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isDownloading = false;
      if (kDebugMode) print('Erro ao disparar download offline: $e');
    }
  }
}
