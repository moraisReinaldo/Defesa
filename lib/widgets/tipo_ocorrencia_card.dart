import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/ocorrencia_tipos.dart';

class TipoOcorrenciaCard extends StatelessWidget {
  final String tipo;
  final bool selected;
  final VoidCallback onTap;

  const TipoOcorrenciaCard({
    super.key,
    required this.tipo,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tipoColor = AppColors.getTipoColor(tipo);
    final tipoColorLight = AppColors.getTipoColorLight(tipo);
    final nome = OcorrenciaTipos.getTipoNome(tipo);
    final icone = OcorrenciaTipos.getTipoIcone(tipo);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected ? tipoColorLight : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? tipoColor : AppColors.borderLight,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: tipoColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Conteúdo
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected
                          ? tipoColor.withOpacity(0.15)
                          : tipoColorLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icone,
                      color: tipoColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Nome
                  Text(
                    nome,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? tipoColor : AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Check de seleção
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: tipoColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
