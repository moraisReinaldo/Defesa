import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';

class AvisoComunitarioDialog extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback? onAceito;

  const AvisoComunitarioDialog({
    super.key,
    required this.storageService,
    this.onAceito,
  });

  static Future<void> exibirSeNecessario(
    BuildContext context,
    StorageService storageService,
  ) async {
    if (!storageService.obterAvisoComunitarioAceito()) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AvisoComunitarioDialog(
          storageService: storageService,
        ),
      );
    }
  }

  @override
  State<AvisoComunitarioDialog> createState() => _AvisoComunitarioDialogState();
}

class _AvisoComunitarioDialogState extends State<AvisoComunitarioDialog> {
  Future<void> _confirmar() async {
    await widget.storageService.salvarAvisoComunitarioAceito(true);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onAceito?.call();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        backgroundColor: AppColors.surfaceCard,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com Ícone e Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.accentAmber,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'AVISO IMPORTANTE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 18),

                // Conteúdo do Texto de Aviso
                const Text(
                  'Este aplicativo não possui qualquer vínculo com órgãos governamentais, entidades de Defesa Civil ou serviços de emergência estatais. O Defesa Em Foco é uma plataforma independente baseada exclusivamente em colaboração comunitária.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Este NÃO é um canal de emergência oficial. Os dados são de inteira responsabilidade dos usuários que os publicam.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryTeal.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EM CASO DE EMERGÊNCIA REAL, NÃO USE ESTE APP.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Ligue imediatamente para os órgãos competentes:',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _BadgeEmergencia(numero: '190', nome: 'Polícia'),
                          _BadgeEmergencia(numero: '193', nome: 'Bombeiros'),
                          _BadgeEmergencia(numero: '199', nome: 'Defesa Civil'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botão de Confirmação
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _confirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Entendi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeEmergencia extends StatelessWidget {
  final String numero;
  final String nome;

  const _BadgeEmergencia({
    required this.numero,
    required this.nome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            numero,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($nome)',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
