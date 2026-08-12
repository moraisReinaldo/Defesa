import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';

enum MapaAction {
  novoPontoInteresse,
  novaOcorrencia,
  emitirAlerta,
}

class MapaContextMenuWidget extends StatelessWidget {
  final LatLng position;
  final ValueChanged<MapaAction> onActionSelected;

  const MapaContextMenuWidget({
    super.key,
    required this.position,
    required this.onActionSelected,
  });

  static Future<MapaAction?> exibir(BuildContext context, LatLng latlng) {
    return showDialog<MapaAction>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com Coordenadas
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.my_location_rounded,
                        color: AppColors.primaryTeal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ponto Selecionado',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${latlng.latitude.toStringAsFixed(4)}, ${latlng.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 12),

              // Ação 1: Novo Ponto de Apoio / Risco
              _buildMenuItem(
                ctx,
                icon: Icons.add_location_alt_rounded,
                color: Colors.orange,
                title: 'Novo Ponto de Apoio / Risco',
                subtitle: 'Abrigo, zona de risco ou apoio',
                action: MapaAction.novoPontoInteresse,
              ),

              const SizedBox(height: 8),

              // Ação 2: Nova Ocorrência
              _buildMenuItem(
                ctx,
                icon: Icons.add_alert_rounded,
                color: AppColors.primaryTeal,
                title: 'Registrar Ocorrência',
                subtitle: 'Alagamento, deslizamento, etc.',
                action: MapaAction.novaOcorrencia,
              ),

              const SizedBox(height: 8),

              // Ação 3: Emitir Alerta nesta Região
              _buildMenuItem(
                ctx,
                icon: Icons.campaign_rounded,
                color: Colors.red,
                title: 'Emitir Alerta nesta Região',
                subtitle: 'Aviso da Defesa Civil',
                action: MapaAction.emitirAlerta,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required MapaAction action,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(context, action),
        hoverColor: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(10),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
