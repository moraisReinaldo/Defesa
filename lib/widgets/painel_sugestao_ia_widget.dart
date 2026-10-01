import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/ocorrencia.dart';
import '../providers/ocorrencia_provider.dart';
import '../services/offline_map_service.dart';

class PainelSugestaoIaWidget extends StatefulWidget {
  final Ocorrencia ocorrencia;
  final VoidCallback onAprovada;

  const PainelSugestaoIaWidget({
    super.key,
    required this.ocorrencia,
    required this.onAprovada,
  });

  @override
  State<PainelSugestaoIaWidget> createState() => _PainelSugestaoIaWidgetState();
}

class _PainelSugestaoIaWidgetState extends State<PainelSugestaoIaWidget> {
  bool _carregando = false;
  Map<String, dynamic>? _sugestao;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscarSugestao();
  }

  Future<void> _buscarSugestao() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final res = await context
          .read<OcorrenciaProvider>()
          .obterSugestaoIa(widget.ocorrencia.id);
      if (mounted) {
        setState(() {
          _sugestao = res;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível obter sugestão no momento.';
          _carregando = false;
        });
      }
    }
  }

  Future<void> _aprovarComCoordenadas(double lat, double lng) async {
    setState(() => _carregando = true);
    try {
      await context.read<OcorrenciaProvider>().aprovarOcorrencia(
            widget.ocorrencia.id,
            latitude: lat,
            longitude: lng,
          );
      if (mounted) {
        widget.onAprovada();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao aprovar: $e'), backgroundColor: Colors.red),
        );
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pontoOriginal = LatLng(widget.ocorrencia.latitude, widget.ocorrencia.longitude);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.ocorrencia.origemSuspeita
              ? Colors.red.withValues(alpha: 0.4)
              : AppColors.primaryTeal.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho de Alerta de Origem Suspeita (se houver)
          if (widget.ocorrencia.origemSuspeita) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Origem Suspeita: Cidadão enviou a mais de 2 km do local marcado!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Cabeçalho do Card IA
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Validação Comunitária & IA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Análise de cluster geográfico e modelo multimodal',
                      style: TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              if (_carregando)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: AppColors.textLight),
                  onPressed: _buscarSugestao,
                  tooltip: 'Recalcular sugestão',
                ),
            ],
          ),

          const SizedBox(height: 12),

          if (_carregando && _sugestao == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                    SizedBox(height: 10),
                    Text('Calculando melhor posicionamento...', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
            )
          else if (_erro != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_erro!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            )
          else if (_sugestao != null) ...[
            _buildDetalhesSugestao(pontoOriginal),
          ],
        ],
      ),
    );
  }

  Widget _buildDetalhesSugestao(LatLng pontoOriginal) {
    final latSug = (_sugestao!['lat'] as num?)?.toDouble() ?? pontoOriginal.latitude;
    final lngSug = (_sugestao!['lng'] as num?)?.toDouble() ?? pontoOriginal.longitude;
    final pontoSugerido = LatLng(latSug, lngSug);
    final confianca = ((_sugestao!['confianca'] as num?)?.toDouble() ?? 0.5) * 100;
    final justificativa = _sugestao!['justificativa'] as String? ?? 'Posicionamento sugerido';
    final totalRelatos = _sugestao!['totalRelatosCluster'] as int? ?? 1;

    final bool temDiferenca = (pontoOriginal.latitude - latSug).abs() > 0.0001 ||
        (pontoOriginal.longitude - lngSug).abs() > 0.0001;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges: Cluster comunitário e confiança da IA
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (totalRelatos >= 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Confirmado pela comunidade ($totalRelatos relatos)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Confiança: ${confianca.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Justificativa da IA
        Text(
          justificativa,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
        ),

        const SizedBox(height: 12),

        // Mini preview no mapa com pin original vs pin IA
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 120,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: pontoSugerido,
                initialZoom: 16.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.defesacivil.app',
                  tileProvider: OfflineMapService().getTileProvider(),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pontoOriginal,
                      width: 28,
                      height: 28,
                      child: const Icon(Icons.location_on, color: Colors.blue, size: 28),
                    ),
                    if (temDiferenca)
                      Marker(
                        point: pontoSugerido,
                        width: 32,
                        height: 32,
                        child: const Icon(Icons.auto_awesome_motion, color: Color(0xFF6366F1), size: 32),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue, size: 14),
                SizedBox(width: 4),
                Text('Original', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
            if (temDiferenca)
              const Row(
                children: [
                  Icon(Icons.auto_awesome_motion, color: Color(0xFF6366F1), size: 14),
                  SizedBox(width: 4),
                  Text('Sugerido pela IA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                ],
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Botões de Ação
        Row(
          children: [
            if (temDiferenca) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _carregando
                      ? null
                      : () => _aprovarComCoordenadas(latSug, lngSug),
                  icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                  label: const Text(
                    'APROVAR NO PONTO IA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _carregando
                    ? null
                    : () => _aprovarComCoordenadas(pontoOriginal.latitude, pontoOriginal.longitude),
                icon: const Icon(Icons.check, size: 16, color: Colors.green),
                label: Text(
                  temDiferenca ? 'MANTER ORIGINAL' : 'APROVAR',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
