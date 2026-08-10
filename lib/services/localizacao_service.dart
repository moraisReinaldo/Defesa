import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalizacaoService {
  static final LocalizacaoService _instance = LocalizacaoService._internal();

  factory LocalizacaoService() {
    return _instance;
  }

  LocalizacaoService._internal();

  Future<bool> verificarPermissoes() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  Future<Position?> obterPosicaoAtual() async {
    try {
      // Verificar permissões
      bool temPermissao = await verificarPermissoes();
      if (!temPermissao) {
        return null;
      }

      // Verificar se o serviço de localização está habilitado
      bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicoHabilitado) {
        return null;
      }

      // Tentar pegar a última localização conhecida primeiro (muito mais rápido na Web)
      Position? position = await Geolocator.getLastKnownPosition();
      
      // Se não tiver, pedir a localização atual (com precisão menor na Web para evitar timeout)
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return position;
    } catch (e) {
      if (kDebugMode) print('Erro ao obter localização: $e');
      return null;
    }
  }

  Future<double> calcularDistancia(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Stream<Position> obterFluxoPosicao({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int intervaloMs = 1000,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        timeLimit:  const Duration(seconds: 30),
      ),
    );
  }
}
