import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../models/cidade.dart';
import '../models/usuario.dart';

/// Serviço centralizado para gerenciar anúncios do Google AdMob.
///
/// Governança por Plano de Município:
/// - Plano Base (Gratuito) ou Expirado: Anúncios ativos (feed e detalhes da ocorrência).
/// - Plano Gestão Municipal, PRO ou Trial PRO (120 Dias): ZERO ANÚNCIOS para toda a cidade.
/// - Super Admin: ZERO ANÚNCIOS sempre.
/// - Anúncios de tela cheia (Interstitial) FORAM REMOVIDOS para manter a usabilidade perfeita.
///
/// iOS ATT (App Tracking Transparency):
/// - O prompt de permissão é exibido ANTES da inicialização do AdMob.
/// - Se o usuário negar, o AdMob serve anúncios não personalizados automaticamente.
/// - A chave NSUserTrackingUsageDescription está configurada no Info.plist.
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

    // 3. Se estiver em Trial PRO de 120 dias ativo -> ZERO ANÚNCIOS
    if (cidadeAtiva.isTrialAtivo) return false;

    // 4. Se o plano for Gestão Municipal ou PRO Municipal -> ZERO ANÚNCIOS
    if (cidadeAtiva.plano == PlanoCidade.gestaoMunicipal ||
        cidadeAtiva.plano == PlanoCidade.proMunicipal) {
      return false;
    }

    // 5. Plano Base Gratuito ou expirado -> EXIBIR ANÚNCIOS
    return true;
  }

  /// Solicita permissão ATT no iOS antes de inicializar o AdMob.
  ///
  /// No Android, pula direto para a inicialização do SDK.
  /// No iOS, exibe o prompt nativo de App Tracking Transparency.
  /// Se o usuário negar, o AdMob serve anúncios não personalizados automaticamente.
  ///
  /// IMPORTANTE: Este método DEVE ser chamado somente após o primeiro frame
  /// ter sido renderizado (dentro de addPostFrameCallback ou initState de um widget).
  /// Chamar de main() antes de runApp() faz o prompt falhar silenciosamente
  /// no iPadOS 27+ com SceneDelegate, pois a janela ainda não está ativa.
  Future<void> _solicitarATT() async {
    if (!Platform.isIOS) return;

    try {
      // Verificar status atual do ATT
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (kDebugMode) print('🔒 ATT Status atual: $status');

      // Só exibir o prompt se o status ainda for "não determinado"
      if (status == TrackingStatus.notDetermined) {
        // Aguardar o app estar verdadeiramente ativo (UIApplicationState.active)
        // Essencial no iPadOS 27+ com SceneDelegate, onde a janela pode não
        // estar ativa imediatamente. Sem isso, o prompt é silenciosamente ignorado.
        await _aguardarAppAtivo();

        final resultado = await AppTrackingTransparency.requestTrackingAuthorization();
        if (kDebugMode) print('🔒 ATT Resultado da solicitação: $resultado');
      }
    } catch (e) {
      // Em caso de erro (simulador, versão antiga do iOS, etc.), continua normalmente
      if (kDebugMode) print('⚠️ ATT não disponível ou erro: $e');
    }
  }

  /// Aguarda o app atingir o estado "resumed" (ativo).
  ///
  /// No iPadOS 27 com SceneDelegate, o app pode ainda estar em estado "inactive"
  /// quando o primeiro frame é renderizado. O ATT exige que o app esteja em
  /// estado UIApplicationState.active para exibir o prompt.
  Future<void> _aguardarAppAtivo() async {
    final binding = WidgetsBinding.instance;

    // Se já está em resumed, um breve delay para estabilização é suficiente
    if (binding.lifecycleState == AppLifecycleState.resumed) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    // Caso contrário, aguarda o app entrar em estado ativo via observer
    if (kDebugMode) print('🔒 ATT: Aguardando app ficar ativo...');
    final completer = Completer<void>();
    final observer = _LifecycleObserver(onResumed: () {
      if (!completer.isCompleted) completer.complete();
    });
    binding.addObserver(observer);

    try {
      // Timeout de segurança de 5 segundos para não travar o app
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) print('⚠️ ATT: Timeout aguardando app ativo, prosseguindo...');
        },
      );
    } finally {
      binding.removeObserver(observer);
    }

    // Delay adicional de estabilização após ficar ativo
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Inicializa o ATT (se iOS) e o SDK do Google Mobile Ads.
  ///
  /// DEVE ser chamado de dentro de um Widget (após o primeiro frame renderizar),
  /// NÃO de main(). No iPadOS 27+ com SceneDelegate, chamar antes de runApp()
  /// faz o prompt ATT falhar silenciosamente.
  ///
  /// Isso garante que o SDK do Google receba o status correto do IDFA
  /// e sirva anúncios personalizados (se permitido) ou não personalizados.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // 1. Solicitar ATT no iOS (ANTES do AdMob)
      await _solicitarATT();

      // 2. Inicializar o SDK do AdMob (já recebe o status ATT correto)
      await MobileAds.instance.initialize();
      _isInitialized = true;
      if (kDebugMode) print('✅ AdMob SDK inicializado com sucesso (ATT processado)');
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

/// Observer interno para monitorar mudanças no ciclo de vida do app.
/// Usado pelo AdService para aguardar o estado "resumed" antes de
/// solicitar permissão ATT no iOS.
class _LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResumed;

  _LifecycleObserver({required this.onResumed});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
