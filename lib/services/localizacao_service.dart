import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

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

      // Verificar se o serviço de localização está habilitado (pular na web)
      if (!kIsWeb) {
        bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
        if (!servicoHabilitado) {
          return null;
        }
      }

      Position? position;
      
      try {
        if (!kIsWeb) {
          // getLastKnownPosition() geralmente não é suportado na Web e pode lançar exceção
          position = await Geolocator.getLastKnownPosition();
        }
      } catch (e) {
        if (kDebugMode) print('Erro ao obter última posição: $e');
      }
      
      // Se não tiver, pedir a localização atual (com precisão menor na Web para evitar timeout)
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
        timeLimit: kIsWeb ? const Duration(seconds: 60) : const Duration(seconds: 15),
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
