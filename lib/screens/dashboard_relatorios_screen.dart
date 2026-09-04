import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../models/ocorrencia.dart';
import '../models/ponto_interesse.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../providers/ponto_interesse_provider.dart';
import '../providers/alerta_provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/clima_widget.dart';
import '../services/clima_service.dart';
import '../constants/ocorrencia_tipos.dart';
import 'package:flutter/foundation.dart';
import '../models/cidade.dart';
import '../providers/cidade_provider.dart';
import '../constants/app_pagamentos.dart';
import 'kit_documental_dialog.dart';
import 'super_admin_screen.dart';

class DashboardRelatoriosScreen extends StatefulWidget {
  const DashboardRelatoriosScreen({super.key});

  @override
  State<DashboardRelatoriosScreen> createState() => _DashboardRelatoriosScreenState();
}

class _DashboardRelatoriosScreenState extends State<DashboardRelatoriosScreen> {
  final MapController _dashMapController = MapController();
  String _filtroTipoMapa = 'TODOS';
  String _filtroAnoMapa = 'TODOS';
  String _filtroStatusMapa = 'TODOS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userProv = context.read<UsuarioProvider>();
      final cidade = userProv.cidadeAtiva;
      final userId = userProv.usuarioLogado?.id;
      final isAdmin = userProv.isAdmin;
      context.read<OcorrenciaProvider>().carregarOcorrencias(
        cidade: cidade,
        userId: userId,
        isAdmin: isAdmin,
      );
      context.read<PontoInteresseProvider>().carregarPontos(cidade: cidade);
      if (cidade != null && cidade.isNotEmpty) {
        context.read<CidadeProvider>().carregarPlanoCidade(cidade);
      }
    });
  }

  void _abrirModalEmitirAlerta(BuildContext context, String cidade) {
    final tituloC = TextEditingController();
    final msgC = TextEditingController();
    String nivelSel = 'ATENCAO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Emitir Alerta • $cidade',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nível de Gravidade:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: nivelSel,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'INFORMATIVO', child: Text('🔵 Informativo (Aviso Geral)')),
                    DropdownMenuItem(value: 'ATENCAO', child: Text('🟡 Atenção (Risco Moderado)')),
                    DropdownMenuItem(value: 'CRITICO', child: Text('🔴 Alerta Vermelho / Evacuação')),
                  ],
                  onChanged: (v) => setDialogState(() => nivelSel = v!),
                ),
                const SizedBox(height: 16),
                const Text('Título do Alerta:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: tituloC,
                  decoration: InputDecoration(
                    hintText: 'Ex: Risco de Alagamento nas Próximas Horas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Mensagem / Orientações:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: msgC,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Evite trafegar por áreas baixas e contate a Defesa Civil se necessário.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.send_rounded),
              label: const Text('EMITIR ALERTA'),
              onPressed: () async {
                if (tituloC.text.trim().isEmpty || msgC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha o título e a mensagem.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final ok = await context.read<AlertaProvider>().emitirAlerta(
                      cidade: cidade,
                      titulo: tituloC.text.trim(),
                      mensagem: msgC.text.trim(),
                      nivel: nivelSel,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Alerta emitido com sucesso para a população!' : 'Erro ao emitir alerta.'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportarRelatorioOficial(BuildContext context, List<Ocorrencia> ocorrencias, String cidadeNome) {
    if (ocorrencias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há ocorrências para exportar.')),
      );
      return;
    }

    final buffer = StringBuffer();
    // UTF-8 BOM para abrir com acentuação correta no Microsoft Excel e LibreOffice
    buffer.write('\uFEFF');
    buffer.writeln('Protocolo;Data e Hora;Cidade;Tipo de Ocorrência;Código COBRADE;Descrição COBRADE;Status;Latitude;Longitude;Agente no Local;Data Chegada;Data Resolução;Agentes Atribuídos;Descrição do Cidadão;Parecer Técnico');

    for (final o in ocorrencias) {
      final tipo = o.tipo;
      final cobradeCod = o.cobrade ?? OcorrenciaTipos.getCobradeCodigo(tipo);
      final cobradeDesc = o.cobradeDescricao ?? OcorrenciaTipos.getCobradeDescricao(tipo);
      final statusStr = o.status.name.toUpperCase();
      final dataStr = DateFormat('dd/MM/yyyy HH:mm').format(o.dataHora);
      final chegadaStr = o.dataChegadaAgente != null ? DateFormat('dd/MM/yyyy HH:mm').format(o.dataChegadaAgente!) : '';
      final resolucaoStr = o.dataResolucao != null ? DateFormat('dd/MM/yyyy HH:mm').format(o.dataResolucao!) : '';

      String escapeCsv(String? val) {
        if (val == null) return '""';
        final clean = val.replaceAll('"', '""').replaceAll('\n', ' ').replaceAll('\r', '');
        return '"$clean"';
      }

      buffer.writeln(
        '${escapeCsv(o.id)};'
        '$dataStr;'
        '${escapeCsv(cidadeNome)};'
        '${escapeCsv(OcorrenciaTipos.getTipoNome(tipo))};'
        '${escapeCsv(cobradeCod)};'
        '${escapeCsv(cobradeDesc)};'
        '${escapeCsv(statusStr)};'
        '${o.latitude};'
        '${o.longitude};'
        '${o.agenteNoLocal ? "SIM" : "NÃO"};'
        '$chegadaStr;'
        '$resolucaoStr;'
        '${escapeCsv(o.agentes)};'
        '${escapeCsv(o.descricao)};'
        '${escapeCsv(o.descricaoSituacao)}'
      );
    }

    final csvContent = buffer.toString();
    final dataUri = 'data:text/csv;charset=utf-8,${Uri.encodeComponent(csvContent)}';
    launchUrl(Uri.parse(dataUri));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Relatório oficial da Defesa Civil (${ocorrencias.length} ocorrências) gerado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UsuarioProvider>();
    final cidadeProv = context.watch<CidadeProvider>();
    final ocorrenciaProv = context.watch<OcorrenciaProvider>();
    final poiProv = context.watch<PontoInteresseProvider>();
    final isAdmin = userProvider.isAdmin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso Negado')),
        body: const Center(child: Text('Área restrita a administradores.')),
      );
    }

    final cidadeCodigo = userProvider.cidadeAtiva;
    final cidadeNome = userProvider.cidadesSuportadas.firstWhere(
      (c) => c['codigo'] == cidadeCodigo,
      orElse: () => {'nome': cidadeCodigo ?? 'Sua Jurisdição'},
    )['nome']!;

    // Regra Governamental: Dashboard Web no navegador é exclusivo do Plano PRO Municipal (ou Trial Ativo)
    if (kIsWeb && !cidadeProv.recursoDashboardWebLiberado && !userProvider.isSuperAdmin) {
      return _buildBloqueioDashboardWeb(context, cidadeNome, cidadeCodigo ?? '');
    }

    final isPendente = (userProvider.usuarioLogado?.isPendente == true) || 
                       (cidadeProv.statusAtual == StatusCidade.pendenteAprovacao);

    final ocorrencias = ocorrenciaProv.ocorrencias;
    final pontosApoio = poiProv.pontos;
    final coordsCidade = ClimaService.obterCoordenadasCidade(cidadeCodigo);
    final centroMapa = LatLng(coordsCidade['lat']!, coordsCidade['lng']!);

    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        title: Text('Dashboard Operacional • $cidadeNome'),
        elevation: 0,
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        actions: [
          if (userProvider.isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.amberAccent),
              tooltip: 'Painel Geral Super Admin',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.gavel_rounded, color: Colors.white),
            tooltip: 'Kit Dispensa Licitação (Lei 14.133/21)',
            onPressed: () => KitDocumentalDialog.show(
              context,
              cidadeNome: cidadeNome,
              cidadeCodigo: cidadeCodigo ?? '',
              isHomologado: !isPendente && (cidadeProv.isTrialAtivo || cidadeProv.recursoDashboardWebLiberado),
            ),
          ),
          IconButton(
            icon: Icon(Icons.download_rounded, color: isPendente ? Colors.white38 : Colors.white),
            tooltip: isPendente ? 'Aguardando Homologação' : 'Exportar Relatório Oficial (CSV / COBRADE)',
            onPressed: isPendente 
              ? () => _mostrarAvisoBloqueioPendente(context)
              : () => _exportarRelatorioOficial(context, ocorrencias, cidadeNome),
          ),
          IconButton(
            icon: Icon(Icons.campaign_rounded, color: isPendente ? Colors.white38 : Colors.amberAccent),
            tooltip: isPendente ? 'Aguardando Homologação' : 'Emitir Alerta de Emergência',
            onPressed: isPendente 
              ? () => _mostrarAvisoBloqueioPendente(context)
              : () => _abrirModalEmitirAlerta(context, cidadeNome),
          ),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 1200,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner de Coordenador Pendente de Homologação
              if (isPendente)
                _buildBannerPendente(context, userProvider.usuarioLogado?.nome ?? 'Coordenador', cidadeNome)
              // Banner com Régua de Contagem Regressiva do Trial PRO (120 dias)
              else if (cidadeProv.isTrialAtivo)
                _buildBannerTrial(context, cidadeProv.diasRestantesTrial, cidadeNome, cidadeCodigo ?? ''),

              const SizedBox(height: 16),

              // 1. Monitoramento Climatológico
              const ClimaWidget(),
              const SizedBox(height: 24),

              // 2. Indicadores de Gestão (KPI Cards)
              _buildKPIs(ocorrencias, pontosApoio),
              const SizedBox(height: 24),

              // 3. Banner de Exportação Oficial de Dados (COBRADE / S2ID)
              _buildCardExportacaoOficial(context, ocorrencias, cidadeNome),
              const SizedBox(height: 24),

              // 4. MAPA DEDICADO DE RISCOS E OCORRÊNCIAS DA CIDADE
              _buildMapaDedicadoRisco(context, centroMapa, ocorrencias, pontosApoio, cidadeNome),
              const SizedBox(height: 24),

              // 5. Gráficos Analíticos
              _buildRow(
                context,
                _buildChartCard('Ocorrências por Tipo', _buildBarChartTipos(ocorrencias)),
                _buildChartCard('Distribuição por Status', _buildPieChartStatus(ocorrencias)),
              ),
              const SizedBox(height: 24),
              _buildChartCard('Evolução do Volume (Últimos 7 Dias)', _buildLineChartEvolucao(ocorrencias), height: 320),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardExportacaoOficial(
    BuildContext context,
    List<Ocorrencia> ocorrencias,
    String cidadeNome,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryTeal.withValues(alpha: 0.08),
            Colors.blue.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.table_chart_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Relatório Oficial de Ocorrências',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Chip(
                      label: Text(
                        'PADRÃO COBRADE / S2ID',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      backgroundColor: AppColors.primaryTeal,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Exportação consolidada com classificação federal para prestação de contas, Defesa Civil Estadual e Ministério da Integração (MDR).',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.file_download_rounded, size: 20),
            label: const Text(
              'Exportar CSV',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _exportarRelatorioOficial(context, ocorrencias, cidadeNome),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaDedicadoRisco(
    BuildContext context,
    LatLng centro,
    List<Ocorrencia> ocorrencias,
    List<PontoInteresse> pontos,
    String cidadeNome,
  ) {
    // Filtragem dinâmica de ocorrências
    final ocorrenciasFiltradas = ocorrencias.where((o) {
      if (_filtroTipoMapa != 'TODOS' && o.tipo != _filtroTipoMapa) return false;
      if (_filtroStatusMapa != 'TODOS' && o.status.name != _filtroStatusMapa) return false;
      if (_filtroAnoMapa != 'TODOS' && o.dataHora.year.toString() != _filtroAnoMapa) return false;
      return true;
    }).toList();

    // Anos disponíveis para o filtro de ano
    final anosSet = <String>{'TODOS'};
    for (final o in ocorrencias) {
      anosSet.add(o.dataHora.year.toString());
    }
    final anosDisponiveis = anosSet.toList()..sort((a, b) => b.compareTo(a));

    final markers = <Marker>[];

    // Alfinetes para Pontos de Apoio / Abrigos
    for (final p in pontos) {
      markers.add(
        Marker(
          width: 32, height: 32,
          point: LatLng(p.latitude, p.longitude),
          child: Container(
            decoration: BoxDecoration(color: Colors.blue.shade700, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 16),
          ),
        ),
      );
    }

    // Alfinetes para Ocorrências Históricas Filtradas
    for (final o in ocorrenciasFiltradas) {
      final color = AppColors.getTipoColor(o.tipo);
      markers.add(
        Marker(
          width: 34, height: 34,
          point: LatLng(o.latitude, o.longitude),
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(OcorrenciaTipos.getTipoNome(o.tipo)),
                  content: Text('${o.descricao}\n\nData: ${o.dataHora.day}/${o.dataHora.month}/${o.dataHora.year}\nStatus: ${o.status.name}'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: Icon(OcorrenciaTipos.getTipoIcone(o.tipo), color: Colors.white, size: 18),
            ),
          ),
        ),
      );
    }

    final temFiltroAtivo = _filtroTipoMapa != 'TODOS' || _filtroAnoMapa != 'TODOS' || _filtroStatusMapa != 'TODOS';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Mapa
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_rounded, color: AppColors.primaryTeal, size: 24),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MAPA DE OCORRÊNCIAS & RISCOS HISTÓRICOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        Text('Jurisdição: $cidadeNome', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('${ocorrenciasFiltradas.length} / ${ocorrencias.length} Exibidos', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                ),
              ],
            ),
          ),

          // BARRA DE FILTROS INTERATIVOS DO MAPA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Filtro 1: Tipo de Ocorrência
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOffWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroTipoMapa,
                      isDense: true,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      items: [
                        const DropdownMenuItem(value: 'TODOS', child: Text('🔥 Todos os Tipos')),
                        ...OcorrenciaTipos.tipos.entries.map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            )),
                      ],
                      onChanged: (v) => setState(() => _filtroTipoMapa = v!),
                    ),
                  ),
                ),

                // Filtro 2: Ano
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOffWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroAnoMapa,
                      isDense: true,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      items: anosDisponiveis.map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a == 'TODOS' ? '📅 Todos os Anos' : '📅 Ano $a'),
                      )).toList(),
                      onChanged: (v) => setState(() => _filtroAnoMapa = v!),
                    ),
                  ),
                ),

                // Filtro 3: Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOffWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroStatusMapa,
                      isDense: true,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      items: const [
                        DropdownMenuItem(value: 'TODOS', child: Text('📌 Todos os Status')),
                        DropdownMenuItem(value: 'resolvida', child: Text('✅ Resolvidas')),
                        DropdownMenuItem(value: 'pendenteAprovacao', child: Text('🟡 Pendentes')),
                        DropdownMenuItem(value: 'aprovada', child: Text('🔵 Aprovadas')),
                        DropdownMenuItem(value: 'trabalhandoAtualmente', child: Text('🚗 Em Andamento')),
                        DropdownMenuItem(value: 'recusada', child: Text('🔴 Recusadas')),
                      ],
                      onChanged: (v) => setState(() => _filtroStatusMapa = v!),
                    ),
                  ),
                ),

                // Botão de Limpar Filtros se algum estiver ativo
                if (temFiltroAtivo)
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                    icon: const Icon(Icons.clear_all_rounded, size: 16, color: Colors.red),
                    label: const Text('Limpar Filtros', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                    onPressed: () => setState(() {
                      _filtroTipoMapa = 'TODOS';
                      _filtroAnoMapa = 'TODOS';
                      _filtroStatusMapa = 'TODOS';
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Canvas do Mapa
          SizedBox(
            height: 380,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: FlutterMap(
                mapController: _dashMapController,
                options: MapOptions(
                  initialCenter: centro,
                  initialZoom: 13,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.defesacivil.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, Widget child1, Widget child2) {
    if (MediaQuery.of(context).size.width > 800) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child1),
          const SizedBox(width: 24),
          Expanded(child: child2),
        ],
      );
    }
    return Column(
      children: [
        child1,
        const SizedBox(height: 24),
        child2,
      ],
    );
  }

  Widget _buildKPIs(List<Ocorrencia> ocorrencias, List<PontoInteresse> pontos) {
    final resolvidas = ocorrencias.where((o) => o.status == OcorrenciaStatus.resolvida).length;
    final pendentes = ocorrencias.where((o) => o.status == OcorrenciaStatus.pendenteAprovacao).length;
    final emAndamento = ocorrencias.where((o) => o.status == OcorrenciaStatus.trabalhandoAtualmente).length;

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      final kpis = [
        _buildKPICard('Total Geral', ocorrencias.length.toString(), Icons.analytics_rounded, AppColors.primaryTeal),
        _buildKPICard('Resolvidas', resolvidas.toString(), Icons.check_circle_rounded, AppColors.statusResolved),
        _buildKPICard('Em Atendimento', emAndamento.toString(), Icons.engineering_rounded, AppColors.statusEnRoute),
        _buildKPICard('Pendentes', pendentes.toString(), Icons.pending_actions_rounded, AppColors.accentAmber),
      ];

      if (isMobile) {
        return Column(
          children: [
            Row(children: [Expanded(child: kpis[0]), const SizedBox(width: 12), Expanded(child: kpis[1])]),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: kpis[2]), const SizedBox(width: 12), Expanded(child: kpis[3])]),
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: kpis[0]), const SizedBox(width: 16),
          Expanded(child: kpis[1]), const SizedBox(width: 16),
          Expanded(child: kpis[2]), const SizedBox(width: 16),
          Expanded(child: kpis[3]),
        ],
      );
    });
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart, {double height = 300}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildBarChartTipos(List<Ocorrencia> ocorrencias) {
    Map<String, int> counts = {};
    for (var o in ocorrencias) {
      counts[o.tipo] = (counts[o.tipo] ?? 0) + 1;
    }

    var sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.length > 5) sorted = sorted.sublist(0, 5);

    if (sorted.isEmpty) {
      return const Center(
        child: Text(
          'Sem dados de ocorrências registrados.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    double maxY = sorted.first.value.toDouble() * 1.2;
    if (maxY == 0) maxY = 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sorted.length) {
                  String label = OcorrenciaTipos.getTipoNome(sorted[value.toInt()].key);
                  if (label.length > 10) label = '${label.substring(0, 8)}..';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sorted.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: sorted[i].value.toDouble(),
                color: OcorrenciaTipos.getTipoColor(sorted[i].key),
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: AppColors.backgroundOffWhite,
                ),
              )
            ],
            showingTooltipIndicators: [0],
          );
        }),
      ),
    );
  }

  Widget _buildPieChartStatus(List<Ocorrencia> ocorrencias) {
    Map<OcorrenciaStatus, int> counts = {};
    for (var o in ocorrencias) {
      counts[o.status] = (counts[o.status] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const Center(
        child: Text(
          'Sem dados de status registrados.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: counts.entries.map((e) {
          Color color;
          String label;
          switch (e.key) {
            case OcorrenciaStatus.resolvida:
              color = AppColors.statusResolved;
              label = 'Resolvida';
              break;
            case OcorrenciaStatus.pendenteAprovacao:
              color = AppColors.accentAmber;
              label = 'Pendente';
              break;
            case OcorrenciaStatus.aprovada:
              color = AppColors.primaryTealLight;
              label = 'Aprovada';
              break;
            case OcorrenciaStatus.trabalhandoAtualmente:
              color = AppColors.statusEnRoute;
              label = 'Em Andamento';
              break;
            case OcorrenciaStatus.recusada:
              color = AppColors.statusActive;
              label = 'Recusada';
              break;
          }
          final percentage = (e.value / ocorrencias.length) * 100;
          return PieChartSectionData(
            color: color,
            value: e.value.toDouble(),
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 40,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            badgeWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: color)),
              child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            ),
            badgePositionPercentageOffset: 1.4,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChartEvolucao(List<Ocorrencia> ocorrencias) {
    Map<String, int> counts = {};
    DateTime today = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      counts[DateFormat('dd/MM').format(d)] = 0;
    }

    for (var o in ocorrencias) {
      final key = DateFormat('dd/MM').format(o.dataHora);
      if (counts.containsKey(key)) {
        counts[key] = counts[key]! + 1;
      }
    }

    final keys = counts.keys.toList();
    final values = counts.values.toList();

    double maxY = values.reduce((a, b) => a > b ? a : b).toDouble() * 1.5;
    if (maxY == 0) maxY = 5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Colors.black12, strokeWidth: 1)),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(keys[value.toInt()], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (keys.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(keys.length, (i) => FlSpot(i.toDouble(), values[i].toDouble())),
            isCurved: true,
            color: AppColors.primaryTeal,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryTeal.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloqueioDashboardWeb(BuildContext context, String cidadeNome, String cidadeCodigo) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      appBar: AppBar(
        title: Text('Painel Web • $cidadeNome'),
        backgroundColor: const Color(0xFF0A192F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF112240),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.computer_rounded, color: Colors.amber, size: 54),
              ),
              const SizedBox(height: 20),
              const Text(
                'Painel Web de Gestão Integrada',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'EXCLUSIVO DO PLANO PRO MUNICIPAL',
                  style: TextStyle(color: Colors.lightBlueAccent, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'O acesso web para telas de gabinete e centros integrados de comando é liberado para cidades com o Plano PRO Municipal ativo (ou durante o período de 120 dias de Avaliação PRO gratuita).\n\n'
                'Você pode acessar todas as funcionalidades básicas pelo aplicativo móvel oficial ou formalizar a adesão PRO do seu município.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => launchUrl(Uri.parse(AppPagamentos.obterUrlEmail(
                      cidadeNome: cidadeNome,
                      assunto: 'Solicitação de Acesso ao Painel Web • Defesa Civil de $cidadeNome',
                      corpo: 'Olá Reinaldo,\n\nSou coordenador da Defesa Civil de $cidadeNome e gostaria de solicitar a homologação e ativação do Plano PRO Municipal para liberação do Painel Web e equipe de campo.\n\nAtenciosamente,',
                    ))),
                    icon: const Icon(Icons.email_rounded),
                    label: const Text('Solicitar Homologação por E-mail', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade300,
                      side: BorderSide(color: Colors.blue.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => launchUrl(Uri.parse(AppPagamentos.stripeLinkPlanoGestao)),
                    icon: const Icon(Icons.credit_card_rounded),
                    label: const Text('Plano Gestão (R\$ 490)'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightBlueAccent,
                      side: const BorderSide(color: Colors.lightBlueAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => launchUrl(Uri.parse(AppPagamentos.stripeLinkPlanoPro)),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('Plano PRO (R\$ 1.490)'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => KitDocumentalDialog.show(
                      context,
                      cidadeNome: cidadeNome,
                      cidadeCodigo: cidadeCodigo,
                      isHomologado: false,
                    ),
                    icon: const Icon(Icons.gavel_rounded),
                    label: const Text('Kit Dispensa Licitação'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerPendente(BuildContext context, String nome, String cidadeNome) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Município em Análise pelo Super Admin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Olá $nome! O cadastro de $cidadeNome foi enviado para homologação. Assim que aprovado pelo Super Admin, seus 120 dias de Avaliação PRO com agentes e alertas serão iniciados automaticamente.',
                  style: TextStyle(fontSize: 12, color: Colors.brown.shade800, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerTrial(BuildContext context, int diasRestantes, String cidadeNome, String cidadeCodigo) {
    final bool urgente = diasRestantes <= 7;
    final Color bgColor = urgente ? (diasRestantes <= 3 ? Colors.red.shade50 : Colors.orange.shade50) : Colors.blue.shade50;
    final Color borderColor = urgente ? (diasRestantes <= 3 ? Colors.red.shade400 : Colors.orange.shade400) : Colors.blue.shade300;
    final Color textColor = urgente ? (diasRestantes <= 3 ? Colors.red.shade900 : Colors.orange.shade900) : Colors.blue.shade900;
    final IconData iconData = urgente ? Icons.warning_amber_rounded : Icons.star_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: textColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  urgente
                      ? '⚠️ Atenção: Restam apenas $diasRestantes dia(s) de Avaliação PRO Gratuita!'
                      : '⭐ Plano PRO Municipal Ativo • $diasRestantes dias restantes de Avaliação Gratuita',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Seu município está operando com todos os recursos liberados (equipe de campo, alertas e relatórios oficiais). Garanta a continuidade contratando via Dispensa de Licitação ou pelo WhatsApp.',
            style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.85), height: 1.3),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => KitDocumentalDialog.show(
                  context,
                  cidadeNome: cidadeNome,
                  cidadeCodigo: cidadeCodigo,
                  isHomologado: true,
                ),
                icon: const Icon(Icons.gavel_rounded, size: 14),
                label: const Text('Baixar Kit Dispensa (Lei 14.133/21)', style: TextStyle(fontSize: 11)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => launchUrl(Uri.parse(AppPagamentos.stripeLinkPlanoGestao)),
                icon: const Icon(Icons.credit_card_rounded, size: 14),
                label: const Text('Plano Gestão (Stripe)', style: TextStyle(fontSize: 11)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => launchUrl(Uri.parse(AppPagamentos.stripeLinkPlanoPro)),
                icon: const Icon(Icons.workspace_premium_rounded, size: 14),
                label: const Text('Plano PRO (Stripe)', style: TextStyle(fontSize: 11)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => launchUrl(Uri.parse(AppPagamentos.obterUrlWhatsApp(
                  cidadeNome: cidadeNome,
                  motivo: 'Olá Reinaldo, sou gestor da Defesa Civil de $cidadeNome. Nosso período de avaliação está em andamento e gostaria de suporte para contratação dos planos Gestão ou PRO.',
                ))),
                icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                label: const Text('Falar com Suporte (WhatsApp)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarAvisoBloqueioPendente(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Recurso em Homologação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Este recurso operacional está bloqueado temporariamente enquanto o cadastro do seu município aguarda aprovação pelo Super Admin.\n\n'
          'Assim que aprovado, seus 120 dias de Avaliação PRO com agentes ilimitados, alertas e exportação oficial serão destravados automaticamente.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
