import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/cidade.dart';
import '../models/usuario.dart';

/// Serviço centralizado para gerenciar anúncios do Google AdMob.
///
/// Governança por Plano de Município:
/// - Plano Base (Gratuito) ou Expirado: Anúncios ativos (feed e detalhes da ocorrência).
/// - Plano Gestão Municipal, PRO ou Trial PRO (90 Dias): ZERO ANÚNCIOS para toda a cidade.
/// - Super Admin: ZERO ANÚNCIOS sempre.
/// - Anúncios de tela cheia (Interstitial) FORAM REMOVIDOS para manter a usabilidade perfeita.
class AdService extends ChangeNotifier {
  bool _isInitialized = false;

  // --- IDs de Teste do Google (substituíveis pelos IDs reais de produção) ---
  // Android:
  static const String _androidBannerAdUnitId = 'ca-app-pub-7666166064406107/5984106372';
  static const String _androidNativeAdUnitId = 'ca-app-pub-7666166064406107/7294308296';

  // iOS:
  static const String _iosBannerAdUnitId = 'ca-app-pub-7666166064406107/6483101144';
  static const String _iosNativeAdUnitId = 'ca-app-pub-7666166064406107/7110776785';

  // Getters públicos para os IDs (usados pelos widgets)
  String get bannerAdUnitId => defaultTargetPlatform == TargetPlatform.android ? _androidBannerAdUnitId : _iosBannerAdUnitId;
  String get nativeAdUnitId => defaultTargetPlatform == TargetPlatform.android ? _androidNativeAdUnitId : _iosNativeAdUnitId;

  /// Regra Mestra de Governança de Anúncios
  static bool deveExibirAnuncio({
    required Usuario? usuarioLogado,
    required Cidade? cidadeAtiva,
    bool isVitalicio = false,
  }) {
    // 0. Licença Vitalícia de Munícipe: ZERO ANÚNCIOS PARA SEMPRE EM QUALQUER CIDADE
    if (isVitalicio || usuarioLogado?.isSemAnunciosVitalicio == true) return false;

    // 1. Super Admin NUNCA vê anúncios em hipótese alguma
    if (usuarioLogado?.isSuperAdmin == true) return false;

    // 2. Se não houver cidade definida, assume Plano Base (exibe)
    if (cidadeAtiva == null) return true;

    // 3. Se estiver em Trial PRO de 90 dias ativo -> ZERO ANÚNCIOS
    if (cidadeAtiva.isTrialAtivo) return false;

    // 4. Se o plano for Gestão Municipal ou PRO Municipal -> ZERO ANÚNCIOS
    if (cidadeAtiva.plano == PlanoCidade.gestaoMunicipal ||
        cidadeAtiva.plano == PlanoCidade.proMunicipal) {
      return false;
    }

    // 5. Plano Base Gratuito ou expirado -> EXIBIR ANÚNCIOS
    return true;
  }

  /// Inicializa o SDK do Google Mobile Ads.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      if (kDebugMode) print('✅ AdMob SDK inicializado com sucesso (Modo Discreto)');
    } catch (e) {
      if (kDebugMode) print('⚠️ Erro ao inicializar AdMob: $e');
    }
  }

  /// Cria um Banner discreto (320x50) para os Detalhes da Ocorrência.
  BannerAd criarBannerDetalhesAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) print('📢 Banner de Detalhes carregado');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) print('❌ Banner de Detalhes falhou: $error');
          ad.dispose();
          onFailed?.call();
        },
      ),
    );
  }

  /// Cria um NativeAd para o feed de ocorrências no histórico.
  NativeAd criarNativeAd({
    required void Function(NativeAd) onLoaded,
    required void Function() onFailed,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) print('📢 Native Ad do feed carregado');
          onLoaded(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) print('❌ Native Ad do feed falhou: $error');
          ad.dispose();
          onFailed();
        },
      ),
    );
  }

  /// Mantido para compatibilidade onde for chamado, mas sem travar a tela
  bool mostrarInterstitial() => false;
}
