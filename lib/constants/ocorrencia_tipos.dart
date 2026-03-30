import 'package:flutter/material.dart';
import 'app_colors.dart';

class OcorrenciaTipos {
  static const Map<String, String> tipos = {
    'alagamento': 'Alagamento / Inundação',
    'deslizamento': 'Deslizamento de Terra',
    'queda_arvore': 'Queda de Árvore',
    'incendio_vegetacao': 'Incêndio em Vegetação',
    'colapso_estrutural': 'Colapso Estrutural',
    'vazamento_perigoso': 'Vazamento Perigoso',
    'tempestade': 'Tempestade / Vendaval',
    'outro': 'Outro (Emergência)',
  };

  static const Map<String, String> tiposDescricao = {
    'alagamento': 'Água acumulada em áreas urbanas ou rurais',
    'deslizamento': 'Movimento de terra em encostas ou terrenos',
    'queda_arvore': 'Árvore caída bloqueando via ou ameaçando estruturas',
    'incendio_vegetacao': 'Fogo em áreas de vegetação',
    'colapso_estrutural': 'Desabamento ou colapso de estruturas',
    'vazamento_perigoso': 'Vazamento de substâncias químicas ou perigosas',
    'tempestade': 'Tempestade, vendaval ou fenômeno meteorológico severo',
    'outro': 'Outra emergência não classificada',
  };

  static const Map<String, IconData> tiposIcones = {
    'alagamento': Icons.water_drop_rounded,
    'deslizamento': Icons.terrain_rounded,
    'queda_arvore': Icons.park_rounded,
    'incendio_vegetacao': Icons.local_fire_department_rounded,
    'colapso_estrutural': Icons.domain_disabled_rounded,
    'vazamento_perigoso': Icons.warning_amber_rounded,
    'tempestade': Icons.thunderstorm_rounded,
    'outro': Icons.emergency_rounded,
  };

  static List<String> getTiposLista() => tipos.keys.toList();

  static String getTipoNome(String tipo) => tipos[tipo] ?? 'Desconhecido';

  static String getTipoDescricao(String tipo) =>
      tiposDescricao[tipo] ?? 'Emergência';

  static IconData getTipoIcone(String tipo) =>
      tiposIcones[tipo] ?? Icons.emergency_rounded;

  static Color getTipoColor(String tipo) => AppColors.getTipoColor(tipo);

  static Color getTipoColorLight(String tipo) =>
      AppColors.getTipoColorLight(tipo);
}
