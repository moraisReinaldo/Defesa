import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/ocorrencia_tipos.dart';
import '../models/ocorrencia.dart';
import 'status_badge.dart';
import 'ocorrencia_image.dart';

class OcorrenciaCard extends StatelessWidget {
  final Ocorrencia ocorrencia;
  final VoidCallback? onTap;
  final bool selectable;
  final bool selected;
  final VoidCallback? onSelectToggle;

   const OcorrenciaCard({
    super.key,
    required this.ocorrencia,
    this.onTap,
    this.selectable = false,
    this.selected = false,
    this.onSelectToggle,
  });

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tipoColor = AppColors.getTipoColor(ocorrencia.tipo);
    final tipoColorLight = AppColors.getTipoColorLight(ocorrencia.tipo);

    return GestureDetector(
      onTap: selectable ? onSelectToggle : onTap,
      child: AnimatedContainer(
        duration:  const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryTeal.withValues(alpha: 0.08)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: AppColors.primaryTeal, width: 2)
              : Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (selectable)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryTeal
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryTeal
                            : AppColors.borderLight,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),

              // Ícone do tipo
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tipoColorLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  OcorrenciaTipos.getTipoIcone(ocorrencia.tipo),
                  color: tipoColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      OcorrenciaTipos.getTipoNome(ocorrencia.tipo),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ocorrencia.descricao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatarData(ocorrencia.dataHora),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Thumbnail + Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (ocorrencia.caminhoFoto != null &&
                      ocorrencia.caminhoFoto!.isNotEmpty)
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.shimmer,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: OcorrenciaImage(
                          caminho: ocorrencia.caminhoFoto!,
                          height: 44,
                          width: 44,
                        ),
                      ),
                    ),
                  StatusBadge(
                    resolvida: ocorrencia.resolvida,
                    agentes: ocorrencia.agentes,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
