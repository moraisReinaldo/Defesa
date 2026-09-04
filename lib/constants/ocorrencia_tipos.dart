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
    'animais_peconhentos': 'Animais Peçonhentos',
    'obstrucao_via': 'Obstrução de Via',
    'outro': 'Outro Tipo',
  };

  static const Map<String, String> tiposDescricao = {
    'alagamento': 'Água acumulada em áreas urbanas ou rurais',
    'deslizamento': 'Movimento de terra em encostas ou terrenos',
    'queda_arvore': 'Árvore caída bloqueando via ou ameaçando estruturas',
    'incendio_vegetacao': 'Fogo em áreas de vegetação',
    'colapso_estrutural': 'Desabamento ou colapso de estruturas',
    'vazamento_perigoso': 'Vazamento de substâncias químicas ou perigosas',
    'tempestade': 'Tempestade, vendaval ou fenômeno meteorológico severo',
    'animais_peconhentos': 'Presença de animais perigosos (serpentes, escorpiões, etc.)',
    'obstrucao_via': 'Vias bloqueadas por detritos, quedas ou acidentes',
    'outro': 'Outra observação',
  };

  static const Map<String, IconData> tiposIcones = {
    'alagamento': Icons.water_drop_rounded,
    'deslizamento': Icons.terrain_rounded,
    'queda_arvore': Icons.park_rounded,
    'incendio_vegetacao': Icons.local_fire_department_rounded,
    'colapso_estrutural': Icons.domain_disabled_rounded,
    'vazamento_perigoso': Icons.warning_amber_rounded,
    'tempestade': Icons.thunderstorm_rounded,
    'animais_peconhentos': Icons.bug_report_rounded,
    'obstrucao_via': Icons.block_rounded,
    'outro': Icons.emergency_rounded,
  };

  static const Map<String, String> cobradeCodigos = {
    'alagamento': '1.2.3.0.0',
    'deslizamento': '1.3.2.1.1',
    'queda_arvore': '1.3.1.1.1',
    'incendio_vegetacao': '1.4.1.1.0',
    'colapso_estrutural': '2.1.2.0.0',
    'vazamento_perigoso': '2.2.2.0.0',
    'tempestade': '1.3.2.1.4',
    'animais_peconhentos': '1.4.2.1.0',
    'obstrucao_via': '2.1.1.0.0',
    'outro': '9.9.9.9.9',
  };

  static const Map<String, String> cobradeDescricoes = {
    'alagamento': 'Alagamentos e Inundações Bruscas',
    'deslizamento': 'Deslizamentos de Solo e/ou Rocha',
    'queda_arvore': 'Vendavais / Queda de Árvores por Tempestades',
    'incendio_vegetacao': 'Incêndio Florestal em Áreas de Vegetação',
    'colapso_estrutural': 'Colapso de Edificações e Estruturas',
    'vazamento_perigoso': 'Liberação de Substâncias Perigosas / Químicos',
    'tempestade': 'Tempestades Convectivas - Chuvas Intensas / Granizo',
    'animais_peconhentos': 'Infestações / Animais Peçonhentos',
    'obstrucao_via': 'Interrupção de Vias Públicas e Transporte',
    'outro': 'Outros Desastres e Ocorrências Locais',
  };

  static List<String> getTiposLista() => tipos.keys.toList();

  static String getTipoNome(String tipo) => tipos[tipo] ?? 'Desconhecido';

  static String getTipoDescricao(String tipo) =>
      tiposDescricao[tipo] ?? 'Observação';

  static String getCobradeCodigo(String tipo) =>
      cobradeCodigos[tipo] ?? '9.9.9.9.9';

  static String getCobradeDescricao(String tipo) =>
      cobradeDescricoes[tipo] ?? 'Outros Desastres e Ocorrências Locais';

  static IconData getTipoIcone(String tipo) =>
      tiposIcones[tipo] ?? Icons.emergency_rounded;

  static Color getTipoColor(String tipo) => AppColors.getTipoColor(tipo);

  static Color getTipoColorLight(String tipo) =>
      AppColors.getTipoColorLight(tipo);
}
