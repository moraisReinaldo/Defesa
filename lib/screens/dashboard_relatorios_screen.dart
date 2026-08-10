import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/ocorrencia.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../widgets/responsive_layout.dart';
import '../constants/ocorrencia_tipos.dart';

class DashboardRelatoriosScreen extends StatefulWidget {
  const DashboardRelatoriosScreen({super.key});

  @override
  State<DashboardRelatoriosScreen> createState() => _DashboardRelatoriosScreenState();
}

class _DashboardRelatoriosScreenState extends State<DashboardRelatoriosScreen> {
  @override
  Widget build(BuildContext context) {
    final ocorrencias = context.watch<OcorrenciaProvider>().ocorrencias;
    final isAdmin = context.watch<UsuarioProvider>().isAdmin;
    
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso Negado')),
        body: const Center(child: Text('Área restrita a administradores.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        title: const Text('Dashboard de Relatórios'),
        elevation: 0,
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: ResponsiveContainer(
        maxWidth: 1000,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ocorrencias.isEmpty 
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Nenhuma ocorrência encontrada para gerar relatórios.', style: TextStyle(fontSize: 16)),
                ))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKPIs(ocorrencias),
                    const SizedBox(height: 24),
                    _buildRow(
                      context,
                      _buildChartCard('Ocorrências por Tipo', _buildBarChartTipos(ocorrencias)),
                      _buildChartCard('Distribuição por Status', _buildPieChartStatus(ocorrencias)),
                    ),
                    const SizedBox(height: 24),
                    _buildChartCard('Volume de Ocorrências (Últimos 7 Dias)', _buildLineChartEvolucao(ocorrencias), height: 350),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
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

  Widget _buildKPIs(List<Ocorrencia> ocorrencias) {
    final resolvidas = ocorrencias.where((o) => o.status == OcorrenciaStatus.resolvida).length;
    final pendentes = ocorrencias.where((o) => o.status == OcorrenciaStatus.pendenteAprovacao).length;
    
    if (ocorrencias.isEmpty) return const SizedBox.shrink();
    
    DateTime minDate = ocorrencias.first.dataHora;
    for (var o in ocorrencias) {
      if (o.dataHora.isBefore(minDate)) minDate = o.dataHora;
    }
    final days = DateTime.now().difference(minDate).inDays;
    final avg = days > 0 ? (ocorrencias.length / days) : ocorrencias.length.toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final kpis = [
          _buildKPICard('Total Geral', ocorrencias.length.toString(), Icons.analytics_rounded, AppColors.primaryTeal),
          _buildKPICard('Resolvidas', resolvidas.toString(), Icons.check_circle_rounded, AppColors.statusResolved),
          _buildKPICard('Pendentes', pendentes.toString(), Icons.pending_actions_rounded, AppColors.accentAmber),
          _buildKPICard('Média/Dia', avg.toStringAsFixed(1), Icons.show_chart_rounded, Colors.purple),
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
      }
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
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

    if (sorted.isEmpty) return const SizedBox.shrink();

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
                )
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

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: counts.entries.map((e) {
          Color color;
          String label;
          switch (e.key) {
            case OcorrenciaStatus.resolvida: color = AppColors.statusResolved; label = 'Resolvida'; break;
            case OcorrenciaStatus.pendenteAprovacao: color = AppColors.accentAmber; label = 'Pendente'; break;
            case OcorrenciaStatus.aprovada: color = AppColors.primaryTealLight; label = 'Aprovada'; break;
            case OcorrenciaStatus.trabalhandoAtualmente: color = AppColors.statusEnRoute; label = 'Em Andamento'; break;
            case OcorrenciaStatus.recusada: color = AppColors.statusActive; label = 'Recusada'; break;
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
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.black12, strokeWidth: 1)),
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
}
