import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

class OfflineMapService {
  static final OfflineMapService _instance = OfflineMapService._internal();
  factory OfflineMapService() => _instance;
  OfflineMapService._internal();

  bool get isDownloading => false;
  bool get isInitialized => false;

  Future<void> init() async {
    // Stubbed for Web compatibility (removed objectbox/fmtc)
    if (kDebugMode) print('OfflineMapService: Mapa offline desativado para compilação Web.');
  }

  TileProvider? getTileProvider() {
    return null; // Fallback para o provider padrão de rede
  }

  Future<void> garantirMapaCidade(String? cidadeNome, double lat, double lng) async {
    return;
  }

  Future<void> baixarRegiaoCidade(double lat, double lng, {String? nomeCidade}) async {
    return;
  }
}
