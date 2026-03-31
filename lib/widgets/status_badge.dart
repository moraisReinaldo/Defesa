import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final bool resolvida;
  final String? agentes;
  final double fontSize;

   const StatusBadge({
    super.key,
    required this.resolvida,
    this.agentes,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bgColor;
    final Color textColor;
    final IconData icon;

    if (resolvida) {
      label = 'Resolvida';
      bgColor = AppColors.statusResolved.withValues(alpha: 0.15);
      textColor = AppColors.statusResolved;
      icon = Icons.check_circle_rounded;
    } else if (agentes != null && agentes!.isNotEmpty) {
      label = 'Em caminho';
      bgColor = AppColors.statusEnRoute.withValues(alpha: 0.15);
      textColor = AppColors.statusEnRoute;
      icon = Icons.directions_run_rounded;
    } else {
      label = 'Ativa';
      bgColor = AppColors.statusActive.withValues(alpha: 0.15);
      textColor = AppColors.statusActive;
      icon = Icons.error_rounded;
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
