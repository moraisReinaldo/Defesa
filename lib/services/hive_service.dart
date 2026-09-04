import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Serviço de preferências locais usando Hive.
/// Atende ao [CR2] de Recursos Nativos: "Uso do Hive para armazenar preferência de usuário."
class HiveService {
  // Versioned name avoids opening incompatible IndexedDB stores left by older web builds.
  static const String _boxName = 'user_preferences_v2';

  // Chaves de preferências
  static const String _chaveCidadeFavorita = 'cidade_favorita';
  static const String _chaveTemaEscuro = 'tema_escuro';
  static const String _chaveFiltroStatus = 'filtro_status';
  static const String _chaveFiltroTipo = 'filtro_tipo';
  static const String _chaveNotificacoesAtivas = 'notificacoes_ativas';
  static const String _chaveUltimaAtualizacao = 'ultima_atualizacao';
  static const String _chaveLimiteChuvaDiaria = 'limite_chuva_diaria';

  late Box<dynamic> _box;

  /// Inicializa o Hive e abre a box de preferências.
  /// Deve ser chamado antes de qualquer uso do serviço.
  Future<void> init() async {
    await Hive.initFlutter();
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
    } catch (e) {
      debugPrint('Erro ao abrir Hive box, tentando limpar banco corrompido: $e');
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        _box = await Hive.openBox<dynamic>(_boxName);
      } catch (e2) {
        debugPrint('Falha extrema no Hive: $e2');
      }
    }
  }

  // =========================================================================
  // CIDADE FAVORITA
  // =========================================================================

  /// Salva a cidade favorita/detectada do usuário.
  Future<void> salvarCidadeFavorita(String cidade) async {
    await _box.put(_chaveCidadeFavorita, cidade);
  }

  /// Recupera a cidade favorita/detectada do usuário.
  String? get cidadeFavorita => _box.get(_chaveCidadeFavorita) as String?;

  // =========================================================================
  // TEMA
  // =========================================================================

  /// Salva a preferência de tema (claro/escuro).
  Future<void> salvarTemaEscuro(bool escuro) async {
    await _box.put(_chaveTemaEscuro, escuro);
  }

  /// Recupera a preferência de tema. Padrão: false (tema claro).
  bool get temaEscuro => _box.get(_chaveTemaEscuro, defaultValue: false) as bool;

  // =========================================================================
  // FILTROS DE OCORRÊNCIA
  // =========================================================================

  /// Salva o filtro de status de ocorrência selecionado pelo usuário.
  Future<void> salvarFiltroStatus(String status) async {
    await _box.put(_chaveFiltroStatus, status);
  }

  /// Recupera o filtro de status. Padrão: 'TODOS'.
  String get filtroStatus =>
      _box.get(_chaveFiltroStatus, defaultValue: 'TODOS') as String;

  /// Salva o filtro de tipo de ocorrência selecionado pelo usuário.
  Future<void> salvarFiltroTipo(String tipo) async {
    await _box.put(_chaveFiltroTipo, tipo);
  }

  /// Recupera o filtro de tipo. Padrão: 'TODOS'.
  String get filtroTipo =>
      _box.get(_chaveFiltroTipo, defaultValue: 'TODOS') as String;

  // =========================================================================
  // NOTIFICAÇÕES
  // =========================================================================

  /// Salva se o usuário ativou notificações.
  Future<void> salvarNotificacoesAtivas(bool ativo) async {
    await _box.put(_chaveNotificacoesAtivas, ativo);
  }

  /// Recupera a preferência de notificações. Padrão: true.
  bool get notificacoesAtivas =>
      _box.get(_chaveNotificacoesAtivas, defaultValue: true) as bool;

  // =========================================================================
  // CONTROLE DE SINCRONIZAÇÃO
  // =========================================================================

  /// Salva o timestamp da última atualização de dados.
  Future<void> salvarUltimaAtualizacao() async {
    await _box.put(_chaveUltimaAtualizacao, DateTime.now().toIso8601String());
  }

  /// Recupera o timestamp da última atualização.
  DateTime? get ultimaAtualizacao {
    final val = _box.get(_chaveUltimaAtualizacao) as String?;
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  /// Salva o limite de chuva acumulada no dia (24h) em mm.
  Future<void> salvarLimiteChuvaDiaria(double limite) async {
    await _box.put(_chaveLimiteChuvaDiaria, limite);
  }

  /// Recupera o limite de chuva acumulada no dia. Padrão Defesa Civil: 50.0 mm.
  double get limiteChuvaDiaria =>
      (_box.get(_chaveLimiteChuvaDiaria, defaultValue: 50.0) as num).toDouble();

  // =========================================================================
  // LIMPEZA
  // =========================================================================

  /// Remove preferências normais de sessão mantendo o registro de licença vitalícia
  Future<void> limparPreferencias() async {
    final eraVitalicio = isSemAnunciosVitalicio;
    await _box.clear();
    if (eraVitalicio) {
      await salvarStatusVitalicio(true);
    }
  }

  // =========================================================================
  // ACESSO VITALÍCIO SEM ANÚNCIOS (PERSISTÊNCIA LOCAL RESILIENTE)
  // =========================================================================
  static const String _chaveSemAnunciosVitalicio = 'sem_anuncios_vitalicio';

  Future<void> salvarStatusVitalicio(bool ativo) async {
    await _box.put(_chaveSemAnunciosVitalicio, ativo);
  }

  bool get isSemAnunciosVitalicio =>
      _box.get(_chaveSemAnunciosVitalicio, defaultValue: false) as bool;

  /// Fecha a box do Hive (deve ser chamado ao fechar o app).
  Future<void> fechar() async {
    await _box.close();
  }
}
