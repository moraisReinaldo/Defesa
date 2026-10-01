import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/rota_emergencia.dart';
import '../providers/rota_emergencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../providers/cidade_provider.dart';
import '../services/clima_service.dart';
import '../services/offline_map_service.dart';

class GerenciarRotasScreen extends StatefulWidget {
  const GerenciarRotasScreen({super.key});

  @override
  State<GerenciarRotasScreen> createState() => _GerenciarRotasScreenState();
}

class _GerenciarRotasScreenState extends State<GerenciarRotasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProv = context.read<UsuarioProvider>();
      context.read<RotaEmergenciaProvider>().carregarRotas(cidade: userProv.cidadeAtiva);
    });
  }

  void _abrirCriadorRota([RotaEmergencia? rotaExistente]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CriadorRotaScreen(rotaParaEditar: rotaExistente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UsuarioProvider>();
    final rotaProv = context.watch<RotaEmergenciaProvider>();
    final cidadeProv = context.watch<CidadeProvider>();
    final cidadeNome = userProv.cidadeAtiva ?? 'Sua Cidade';

    // Verificar se o plano da cidade permite rotas (GESTAO ou PRO)
    final permiteRotas = userProv.isAdmin && (userProv.isSuperAdmin || cidadeProv.recursoRotasLiberado);

    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        title: const Text('Rotas de Emergência'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => rotaProv.carregarRotas(cidade: userProv.cidadeAtiva),
          ),
        ],
      ),
      floatingActionButton: permiteRotas
          ? FloatingActionButton.extended(
              onPressed: () => _abrirCriadorRota(),
              backgroundColor: const Color(0xFFFF5722),
              icon: const Icon(Icons.add_road_rounded, color: Colors.white),
              label: const Text('Nova Rota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          // Banner de Plano / Recurso
          if (!permiteRotas && !userProv.isSuperAdmin)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recurso do Plano Gestão Municipal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A criação de rotas de evacuação interativas e offline está disponível a partir do Plano Gestão Municipal.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rotas em $cidadeNome (${rotaProv.rotas.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${rotaProv.rotasAtivas.length} ativas',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF5722),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: rotaProv.carregando
                ? const Center(child: CircularProgressIndicator())
                : rotaProv.rotas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.alt_route_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Nenhuma rota cadastrada ainda.',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Crie rotas de evacuação para abrigos e pontos seguros.',
                              style: TextStyle(fontSize: 12, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: rotaProv.rotas.length,
                        itemBuilder: (context, index) {
                          final rota = rotaProv.rotas[index];
                          return _buildCardRota(rota, rotaProv);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRota(RotaEmergencia rota, RotaEmergenciaProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: rota.ativa
                        ? const Color(0xFFFF5722).withValues(alpha: 0.15)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    color: rota.ativa ? const Color(0xFFFF5722) : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rota.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (rota.descricao != null && rota.descricao!.isNotEmpty)
                        Text(
                          rota.descricao!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: rota.ativa,
                  activeThumbColor: const Color(0xFFFF5722),
                  onChanged: (val) async {
                    try {
                      await provider.alternarStatus(rota.id, val);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      '${rota.pontos.length} pontos de trajeto',
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _abrirCriadorRota(rota),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Editar', style: TextStyle(fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () => _confirmarExclusao(rota, provider),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(RotaEmergencia rota, RotaEmergenciaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Rota?'),
        content: Text('Tem certeza que deseja excluir a rota "${rota.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deletarRota(rota.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Tela interativa de desenho e criação de rotas de evacuação no mapa
class CriadorRotaScreen extends StatefulWidget {
  final RotaEmergencia? rotaParaEditar;

  const CriadorRotaScreen({super.key, this.rotaParaEditar});

  @override
  State<CriadorRotaScreen> createState() => _CriadorRotaScreenState();
}

class _CriadorRotaScreenState extends State<CriadorRotaScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List<LatLng> _pontosTrajeto = [];
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.rotaParaEditar != null) {
      _nomeController.text = widget.rotaParaEditar!.nome;
      _descController.text = widget.rotaParaEditar!.descricao ?? '';
      _pontosTrajeto = List.from(widget.rotaParaEditar!.pontos);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _salvarRota() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da rota.')),
      );
      return;
    }

    if (_pontosTrajeto.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toque no mapa para adicionar pelo menos 2 pontos ao trajeto.')),
      );
      return;
    }

    setState(() => _salvando = true);
    final userProv = context.read<UsuarioProvider>();
    final rotaProv = context.read<RotaEmergenciaProvider>();

    try {
      final rota = RotaEmergencia(
        id: widget.rotaParaEditar?.id,
        nome: nome,
        descricao: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        cidade: userProv.cidadeAtiva ?? 'BPA',
        pontos: _pontosTrajeto,
        ativa: widget.rotaParaEditar?.ativa ?? true,
      );

      if (widget.rotaParaEditar != null) {
        await rotaProv.atualizarRota(rota);
      } else {
        await rotaProv.criarRota(rota);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rota salva com sucesso! ✅'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar rota: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UsuarioProvider>();
    final coords = ClimaService.obterCoordenadasCidade(userProv.cidadeAtiva);
    final center = _pontosTrajeto.isNotEmpty
        ? _pontosTrajeto.first
        : LatLng(coords['lat']!, coords['lng']!);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rotaParaEditar != null ? 'Editar Rota' : 'Criar Rota de Emergência'),
        actions: [
          if (_salvando)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white)))
          else
            TextButton.icon(
              onPressed: _salvarRota,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('SALVAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Campos de Nome e Descrição
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Rota (ex: Evacuação para Ginásio Municipal)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Instruções para o Cidadão (ex: Seguir pela Av. Principal)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          // Instruções e botões de controle de trajeto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFF5722).withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, color: Color(0xFFFF5722), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toque no mapa para marcar o trajeto (${_pontosTrajeto.length} pontos)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF5722)),
                  ),
                ),
                if (_pontosTrajeto.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    tooltip: 'Desfazer último ponto',
                    onPressed: () => setState(() => _pontosTrajeto.removeLast()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.red),
                    tooltip: 'Limpar todos',
                    onPressed: () => setState(() => _pontosTrajeto.clear()),
                  ),
                ],
              ],
            ),
          ),

          // Mapa com desenho da Polyline
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14.5,
                onTap: (_, latlng) {
                  setState(() {
                    _pontosTrajeto.add(latlng);
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.defesacivil.app',
                  tileProvider: OfflineMapService().getTileProvider(),
                ),
                // Linha de Trajeto da Rota
                if (_pontosTrajeto.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _pontosTrajeto,
                        strokeWidth: 5.0,
                        color: const Color(0xFFFF5722),
                      ),
                    ],
                  ),
                // Marcadores nos waypoints
                MarkerLayer(
                  markers: [
                    ..._pontosTrajeto.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      final isInicio = i == 0;
                      final isFim = i == _pontosTrajeto.length - 1;

                      return Marker(
                        point: p,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isInicio
                                ? Colors.blue
                                : isFim
                                    ? Colors.green
                                    : const Color(0xFFFF5722),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: isInicio
                                ? const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16)
                                : isFim
                                    ? const Icon(Icons.flag_rounded, color: Colors.white, size: 16)
                                    : Text(
                                        '${i + 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
