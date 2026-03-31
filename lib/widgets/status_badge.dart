import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/ocorrencia.dart';

class StatusBadge extends StatelessWidget {
  final OcorrenciaStatus status;
  final String? agentes;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.agentes,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color bgColor;
    Color textColor;
    IconData icon;

    // Lógica prioritária: Resolução
    if (status == OcorrenciaStatus.resolvida) {
      label = 'Resolvida';
      bgColor = AppColors.statusResolved.withValues(alpha: 0.15);
      textColor = AppColors.statusResolved;
      icon = Icons.check_circle_rounded;
    } 
    // Novo status solicitado: Trabalhando no local (Lime color)
    else if (status == OcorrenciaStatus.trabalhandoAtualmente) {
      label = 'Em ação';
      const limeColor = Color(0xFF8BC34A); 
      bgColor = limeColor.withValues(alpha: 0.15);
      textColor = limeColor;
      icon = Icons.engineering_rounded;
    }
    // "Em caminho" se houver agentes associados e ainda estiver "Aprovada"
    else if (status == OcorrenciaStatus.aprovada && agentes != null && agentes!.isNotEmpty) {
      label = 'Em caminho';
      bgColor = AppColors.statusEnRoute.withValues(alpha: 0.15);
      textColor = AppColors.statusEnRoute;
      icon = Icons.directions_run_rounded;
    }
    // Padrão para aprovada: "Ativa"
    else if (status == OcorrenciaStatus.aprovada) {
      label = 'Ativa';
      bgColor = AppColors.statusActive.withValues(alpha: 0.15);
      textColor = AppColors.statusActive;
      icon = Icons.error_rounded;
    }
    // Outros status
    else if (status == OcorrenciaStatus.pendenteAprovacao) {
      label = 'Pendente';
      bgColor = Colors.grey.withValues(alpha: 0.15);
      textColor = Colors.grey;
      icon = Icons.hourglass_empty_rounded;
    }
    else {
      label = status.name;
      bgColor = Colors.grey.withValues(alpha: 0.15);
      textColor = Colors.grey;
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 3, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
