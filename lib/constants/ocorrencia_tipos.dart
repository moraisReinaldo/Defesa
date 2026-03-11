import 'package:flutter/material.dart';

class OcorrenciaTipos {
  static const Map<String, String> tipos = {
    'alagamento': 'Alagamento / Inundação',
    'deslizamento': 'Deslizamento de Terra / Encosta',
    'queda_arvore': 'Queda de Árvore',
    'incendio_vegetacao': 'Incêndio em Vegetação (Queimada)',
    'colapso_estrutural': 'Colapso Estrutural (Prédio, Muro, Ponte)',
    'vazamento_perigoso': 'Vazamento de Produtos Perigosos',
    'tempestade': 'Tempestade / Vendaval Forte',
    'outro': 'Outro (Emergência Geral)',
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
    'alagamento': Icons.water_drop,
    'deslizamento': Icons.terrain,
    'queda_arvore': Icons.park,
    'incendio_vegetacao': Icons.local_fire_department,
    'colapso_estrutural': Icons.business,
    'vazamento_perigoso': Icons.warning,
    'tempestade': Icons.thunderstorm,
    'outro': Icons.emergency,
  };

  static List<String> getTiposLista() => tipos.keys.toList();

  static String getTipoNome(String tipo) => tipos[tipo] ?? 'Desconhecido';

  static String getTipoDescricao(String tipo) =>
      tiposDescricao[tipo] ?? 'Emergência';

  static IconData getTipoIcone(String tipo) => tiposIcones[tipo] ?? Icons.emergency;
}
