import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alerta_provider.dart';
import '../providers/usuario_provider.dart';
import '../services/alerta_service.dart';
import '../constants/app_colors.dart';

class AlertaBannerWidget extends StatefulWidget {
  const AlertaBannerWidget({super.key});

  static void exibirModalEmitirAlerta(BuildContext context, String cidade) {
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
                  'Emitir Alerta Geral • $cidade',
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
              label: const Text('EMITIR ALERTA GERAL'),
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
                      content: Text(ok ? 'Alerta geral emitido para toda a população da cidade!' : 'Erro ao emitir alerta.'),
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

  @override
  State<AlertaBannerWidget> createState() => _AlertaBannerWidgetState();
}

class _AlertaBannerWidgetState extends State<AlertaBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cidade = context.read<UsuarioProvider>().cidadeAtiva;
      context.read<AlertaProvider>().carregarAlertas(cidade: cidade);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getNivelColor(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'CRITICO':
        return Colors.red.shade700;
      case 'ATENCAO':
        return Colors.orange.shade800;
      case 'INFORMATIVO':
      default:
        return AppColors.primaryTeal;
    }
  }

  IconData _getNivelIcon(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'CRITICO':
        return Icons.warning_amber_rounded;
      case 'ATENCAO':
        return Icons.report_problem_rounded;
      case 'INFORMATIVO':
      default:
        return Icons.info_outline_rounded;
    }
  }

  void _exibirDetalhesAlerta(BuildContext context, AlertaEmergencia alerta) {
    final color = _getNivelColor(alerta.nivel);
    final isAdmin = context.read<UsuarioProvider>().isAdmin;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(_getNivelIcon(alerta.nivel), color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                alerta.titulo,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alerta.mensagem,
              style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: color, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Siga rigorosamente as orientações da Defesa Civil.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isAdmin)
            TextButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              label: const Text('ENCERRAR ALERTA', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(ctx);
                await context.read<AlertaProvider>().cancelarAlerta(alerta.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alerta encerrado com sucesso!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertaProvider>();
    final isAdmin = context.watch<UsuarioProvider>().isAdmin;

    if (!provider.temAlertaAtivo) {
      return const SizedBox.shrink();
    }

    final alerta = provider.alertasAtivos.first;
    final color = _getNivelColor(alerta.nivel);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4 * _pulseAnimation.value),
                blurRadius: 10 * _pulseAnimation.value,
                spreadRadius: 2,
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _exibirDetalhesAlerta(context, alerta),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(_getNivelIcon(alerta.nivel), color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ALERTA DEFESA CIVIL • ${alerta.cidade}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alerta.titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        tooltip: 'Encerrar Alerta',
                        onPressed: () async {
                          await context.read<AlertaProvider>().cancelarAlerta(alerta.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Alerta encerrado pelo Administrador.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      )
                    else
                      const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
