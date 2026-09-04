import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clima_provider.dart';
import '../providers/usuario_provider.dart';
import '../constants/app_colors.dart';

class ClimaWidget extends StatefulWidget {
  const ClimaWidget({super.key});

  @override
  State<ClimaWidget> createState() => _ClimaWidgetState();
}

class _ClimaWidgetState extends State<ClimaWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cidade = context.read<UsuarioProvider>().cidadeAtiva;
      context.read<ClimaProvider>().carregarClima(cidade);
    });
  }

  @override
  Widget build(BuildContext context) {
    final climaProv = context.watch<ClimaProvider>();
    final userProv = context.watch<UsuarioProvider>();
    final dados = climaProv.dados;

    final cidadeNome = userProv.cidadesSuportadas.firstWhere(
      (c) => c['codigo'] == climaProv.cidadeAtual,
      orElse: () => {'nome': climaProv.cidadeAtual ?? 'Sua Cidade'},
    )['nome']!;

    if (climaProv.carregando) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal)),
                SizedBox(width: 12),
                Text('Obtendo dados meteorológicos...', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    if (dados == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.textLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sem conexão meteorológica no momento para $cidadeNome.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryTeal),
              onPressed: () => climaProv.atualizar(),
            )
          ],
        ),
      );
    }

    final eCritico303030 = dados.regra303030Ativa;
    final eChuvaCritica = climaProv.alertaChuvaAcumuladaCritica;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, 4))],
        border: Border.all(
          color: eCritico303030
              ? Colors.red
              : (eChuvaCritica ? Colors.orange : AppColors.borderLight),
          width: eCritico303030 || eChuvaCritica ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com cidade e refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.thermostat_rounded, color: AppColors.primaryTeal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MONITORAMENTO METEOROLÓGICO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        cidadeNome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textLight, size: 20),
                onPressed: () => climaProv.atualizar(),
                tooltip: 'Atualizar Clima',
              )
            ],
          ),

          const SizedBox(height: 16),

          // ALERTA REGRA 30-30-30 (Se ativa)
          if (eCritico303030) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Colors.red.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚨 REGRA 30-30-30 ATIVA (Risco Crítico de Incêndios)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Temp (${dados.temperatura}°C) >= 30 | Umid (${dados.umidade}%) <= 30 | Vento (${dados.velocidadeVento}km/h) >= 30',
                          style: TextStyle(fontSize: 11, color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ALERTA CHUVA DIÁRIA
          if (climaProv.alertaChuvaDiariaCritica) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ ALERTA DE CHUVA DIÁRIA CRÍTICA (Risco de Alagamentos)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chuva Hoje (24h): ${dados.chuvaHoje.toStringAsFixed(1)} mm (Limite de atenção: 50 mm/dia)',
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ALERTA CHUVA ACUMULADA 72H
          if (climaProv.alertaChuva72hCritica) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.flood_rounded, color: Colors.red.shade800, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚨 ALERTA DE CHUVA ACUMULADA 72H (Risco Severo de Deslizamentos)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Acumulado 72h: ${dados.chuvaAcumulada72h.toStringAsFixed(1)} mm (Limite de atenção: 80 mm/72h)',
                          style: TextStyle(fontSize: 11, color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Grid de Métricas Climáticas
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;
            final items = [
              _buildMetricCard('Temperatura', '${dados.temperatura.toStringAsFixed(1)}°C', Icons.thermostat, Colors.deepOrange),
              _buildMetricCard('Umidade Ar', '${dados.umidade.toStringAsFixed(0)}%', Icons.water_drop_outlined, Colors.blue),
              _buildMetricCard('Vento', '${dados.velocidadeVento.toStringAsFixed(1)} km/h', Icons.air, Colors.teal),
              _buildMetricCard('Chuva Hoje', '${dados.chuvaHoje.toStringAsFixed(1)} mm', Icons.umbrella_rounded, Colors.indigo),
              _buildMetricCard('Chuva 72h', '${dados.chuvaAcumulada72h.toStringAsFixed(1)} mm', Icons.cloud_done_rounded, Colors.purple),
            ];

            if (isNarrow) {
              return Column(
                children: [
                  Row(children: [Expanded(child: items[0]), const SizedBox(width: 8), Expanded(child: items[1])]),
                  const SizedBox(height: 8),
                  Row(children: [Expanded(child: items[2]), const SizedBox(width: 8), Expanded(child: items[3])]),
                  const SizedBox(height: 8),
                  items[4],
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: items[0]), const SizedBox(width: 8),
                Expanded(child: items[1]), const SizedBox(width: 8),
                Expanded(child: items[2]), const SizedBox(width: 8),
                Expanded(child: items[3]), const SizedBox(width: 8),
                Expanded(child: items[4]),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundOffWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
