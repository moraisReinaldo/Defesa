import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Serviço centralizado para gerenciar anúncios do Google AdMob.
///
/// Regra Mestra: Anúncios só são exibidos para usuários NÃO logados.
/// Quando o usuário faz login, todos os anúncios são desativados.
class AdService extends ChangeNotifier {
  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;

  // --- IDs de Teste do Google (trocar pelos reais antes de publicar) ---
  // Android IDs do usuário:
  static const String _androidBannerAdUnitId = 'ca-app-pub-7666166064406107/5984106372';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-7666166064406107/6382461548';
  static const String _androidNativeAdUnitId = 'ca-app-pub-7666166064406107/7294308296';

  // iOS IDs (Reais do usuário):
  static const String _iosBannerAdUnitId = 'ca-app-pub-7666166064406107/6483101144';
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-7666166064406107/3804966919';
  static const String _iosNativeAdUnitId = 'ca-app-pub-7666166064406107/7110776785';

  // Getters públicos para os IDs (usados pelos widgets)
  String get bannerAdUnitId => Platform.isAndroid ? _androidBannerAdUnitId : _iosBannerAdUnitId;
  String get interstitialAdUnitId => Platform.isAndroid ? _androidInterstitialAdUnitId : _iosInterstitialAdUnitId;
  String get nativeAdUnitId => Platform.isAndroid ? _androidNativeAdUnitId : _iosNativeAdUnitId;
  bool get isInterstitialReady => _isInterstitialReady;

  /// Inicializa o SDK do Google Mobile Ads.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      
      // Configurar dispositivos de teste (substitua pelo ID do seu dispositivo que aparece no logcat)
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: ['COLOQUE_O_ID_DO_SEU_DISPOSITIVO_AQUI']),
      );

      _isInitialized = true;
      if (kDebugMode) print('✅ AdMob SDK inicializado com sucesso');
      // Pré-carregar o interstitial
      _carregarInterstitial();
    } catch (e) {
      if (kDebugMode) print('⚠️ Erro ao inicializar AdMob: $e');
    }
  }

  /// Cria um BannerAd para o Empty State (Medium Rectangle 300x250).
  BannerAd criarBannerAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) print('📢 Banner Ad carregado');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) print('❌ Banner Ad falhou: $error');
          ad.dispose();
          onFailed?.call();
        },
      ),
    );
  }

  /// Cria um NativeAd para o feed de ocorrências.
  NativeAd criarNativeAd({
    required void Function(NativeAd) onLoaded,
    required void Function() onFailed,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: 'listTile', // Factory padrão do plugin
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) print('📢 Native Ad carregado');
          onLoaded(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) print('❌ Native Ad falhou: $error');
          ad.dispose();
          onFailed();
        },
      ),
    );
  }

  /// Pré-carrega um Interstitial Ad para exibir após o registro de ocorrência.
  void _carregarInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          if (kDebugMode) print('📢 Interstitial Ad pré-carregado');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialReady = false;
              _interstitialAd = null;
              // Recarregar para a próxima vez
              _carregarInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) print('❌ Interstitial falhou ao exibir: $error');
              ad.dispose();
              _isInterstitialReady = false;
              _interstitialAd = null;
              _carregarInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) print('❌ Interstitial falhou ao carregar: $error');
          _isInterstitialReady = false;
        },
      ),
    );
  }

  /// Exibe o Interstitial se estiver pronto. Retorna true se exibiu.
  bool mostrarInterstitial() {
    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
      return true;
    }
    if (kDebugMode) print('⚠️ Interstitial não estava pronto');
    return false;
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }
}
