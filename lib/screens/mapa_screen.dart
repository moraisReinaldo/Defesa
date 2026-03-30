import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/ocorrencia_tipos.dart';
import '../models/ocorrencia.dart';
import '../models/comentario.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../services/localizacao_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/status_badge.dart';
import '../widgets/ocorrencia_card.dart';
import 'registro_ocorrencia_screen.dart';
import 'historico_screen.dart';
import 'perfil_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();

  Position? _posicaoAtual;
  final List<Marker> _markers = [];
  int _indiceAbaAtual = 0;
  String _searchQuery = '';
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _inicializarMapa();
    context.read<OcorrenciaProvider>().addListener(_atualizarMarcadores);
  }

  Future<void> _inicializarMapa() async {
    await context.read<OcorrenciaProvider>().carregarOcorrencias();
    _posicaoAtual = await _localizacaoService.obterPosicaoAtual();

    if (_posicaoAtual != null && mounted) {
      _atualizarMarcadores();
      _mapController.move(
        LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude),
        14,
      );
    }
  }

  List<Ocorrencia> _getFilteredOcorrencias() {
    final todas = context.read<OcorrenciaProvider>().ocorrencias;
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    return todas.where((o) {
      final tipoNome = OcorrenciaTipos.getTipoNome(o.tipo).toLowerCase();
      final desc = o.descricao.toLowerCase();
      return tipoNome.contains(query) || desc.contains(query);
    }).toList();
  }

  void _atualizarMarcadores() {
    final ocorrencias = context.read<OcorrenciaProvider>().ocorrenciasAtivas;

    _markers.clear();

    for (final ocorrencia in ocorrencias) {
      final tipoColor = AppColors.getTipoColor(ocorrencia.tipo);

      _markers.add(
        Marker(
          point: LatLng(ocorrencia.latitude, ocorrencia.longitude),
          builder: (context) => GestureDetector(
            onTap: () => _mostrarDetalhesOcorrencia(ocorrencia),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tipoColor, tipoColor.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: tipoColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                OcorrenciaTipos.getTipoIcone(ocorrencia.tipo),
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    setState(() {});
  }

  void _mostrarDetalhesOcorrencia(Ocorrencia pOcorrencia) {
    Ocorrencia ocorrencia = pOcorrencia;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.backgroundOffWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header com gradiente
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.getTipoColor(ocorrencia.tipo),
                    AppColors.getTipoColor(ocorrencia.tipo).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      OcorrenciaTipos.getTipoIcone(ocorrencia.tipo),
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          OcorrenciaTipos.getTipoNome(ocorrencia.tipo),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(
                          resolvida: ocorrencia.resolvida,
                          agentes: ocorrencia.agentes,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo scrollável
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descrição
                    _buildSectionCard(
                      icon: Icons.description_rounded,
                      title: 'Descrição',
                      child: Text(
                        ocorrencia.descricao,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Foto
                    if (ocorrencia.caminhoFoto != null &&
                        ocorrencia.caminhoFoto!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowColor,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(ocorrencia.caminhoFoto!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: AppColors.shimmer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image_not_supported_rounded,
                                      color: AppColors.textLight, size: 40),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // Informações
                    _buildSectionCard(
                      icon: Icons.info_rounded,
                      title: 'Informações',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.calendar_today_rounded,
                              'Data', _formatarData(ocorrencia.dataHora)),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.location_on_rounded,
                              'Coordenadas',
                              '${ocorrencia.latitude.toStringAsFixed(4)}, ${ocorrencia.longitude.toStringAsFixed(4)}'),
                        ],
                      ),
                    ),

                    // Admin: editar coordenadas/foto
                    if (context.watch<UsuarioProvider>().isAdmin &&
                        !ocorrencia.resolvida)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionChip(
                                icon: Icons.edit_location_alt_rounded,
                                label: 'Coordenadas',
                                onTap: () => _editarCoordenadas(ocorrencia),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionChip(
                                icon: Icons.photo_camera_rounded,
                                label: 'Trocar foto',
                                onTap: () => _editarFoto(ocorrencia),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Comentários
                    _buildSectionCard(
                      icon: Icons.chat_bubble_rounded,
                      title: 'Comentários',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ocorrencia.comentarios.isEmpty)
                            const Text(
                              'Nenhum comentário ainda.',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            ...ocorrencia.comentarios.map((c) =>
                                _buildComentarioItem(c)),

                          // Admin: adicionar comentário
                          if (context.watch<UsuarioProvider>().isAdmin) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _comentarioController,
                              decoration: InputDecoration(
                                hintText: 'Adicionar comentário...',
                                filled: true,
                                fillColor: AppColors.backgroundOffWhite,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.send_rounded,
                                      color: AppColors.primaryTeal),
                                  onPressed: () =>
                                      _adicionarComentario(ocorrencia),
                                ),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (context.watch<UsuarioProvider>().isAdmin)
                      _buildSectionCard(
                        icon: Icons.groups_rounded,
                        title: 'Agentes a caminho',
                        child: StatefulBuilder(
                          builder: (context, setSheetState) {
                            final agentesGerais = context.watch<UsuarioProvider>().todosAgentes;
                            final o = context.watch<OcorrenciaProvider>().ocorrencias.firstWhere((x) => x.id == ocorrencia.id, orElse: () => ocorrencia);
                            final agentesAtuais = o.agentes?.split(', ').where((s) => s.isNotEmpty).toList() ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (agentesGerais.isEmpty)
                                  const Text('Nenhum agente cadastrado.', style: TextStyle(color: AppColors.textSecondary)),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: agentesGerais.map((agente) {
                                    final isSelected = agentesAtuais.contains(agente.nome);
                                    return FilterChip(
                                      label: Text(agente.nome, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.primaryTeal : AppColors.textPrimary)),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          agentesAtuais.add(agente.nome);
                                        } else {
                                          agentesAtuais.remove(agente.nome);
                                        }
                                        final novoTexto = agentesAtuais.join(', ');
                                        ocorrencia = ocorrencia.copyWith(agentes: novoTexto, resolvida: false);
                                        context.read<OcorrenciaProvider>().atualizarOcorrencia(ocorrencia);
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(selected ? 'Agente ${agente.nome} alocado! Status: A Caminho.' : 'Agente removido.'),
                                            backgroundColor: AppColors.statusResolved,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );

                                        if (selected) {
                                          final comentario = Comentario(
                                            texto: 'Agente ${agente.nome} associado à ocorrência',
                                            usuarioNome: 'Sistema',
                                          );
                                          context.read<OcorrenciaProvider>().adicionarComentario(ocorrencia.id, comentario);
                                          _atualizarMarcadores();
                                        }
                                      },
                                      selectedColor: AppColors.primaryTeal.withOpacity(0.2),
                                      checkmarkColor: AppColors.primaryTeal,
                                    );
                                  }).toList(),
                                ),
                              ],
                            );
                          }
                        ),
                      ),

                    // === BOTÕES DE AÇÃO (GOVERNANÇA) ===
                    const SizedBox(height: 12),
                    
                    // 1. Aprovação (Somente Admin e se Pendente)
                    if (context.watch<UsuarioProvider>().isAdmin && 
                        ocorrencia.status == OcorrenciaStatus.PENDENTE_APROVACAO)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await context.read<OcorrenciaProvider>().aprovarOcorrencia(ocorrencia.id);
                                  if (mounted) Navigator.pop(context);
                                },
                                icon: const Icon(Icons.check_circle_rounded),
                                label: const Text('APROVAR'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Lógica de recusar (pode ser deletar ou mudar status)
                                  context.read<OcorrenciaProvider>().deletarOcorrencia(ocorrencia.id);
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.cancel_rounded),
                                label: const Text('RECUSAR'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 2. Registro de Chegada (Somente Agente e se Aprovada)
                    if (context.watch<UsuarioProvider>().usuarioLogado?.isAgente == true && 
                        ocorrencia.status == OcorrenciaStatus.APROVADA &&
                        !ocorrencia.agenteNoLocal)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await context.read<OcorrenciaProvider>().registrarChegadaAgente(ocorrencia.id);
                              if (mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.location_on_rounded),
                            label: const Text('ESTOU NO LOCAL'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                          ),
                        ),
                      ),

                    // Botões de ação antigos (Resolver/Excluir)
                    if (context.watch<UsuarioProvider>().isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _alterarStatusOcorrencia(ocorrencia),
                                icon: Icon(
                                  ocorrencia.resolvida
                                      ? Icons.refresh_rounded
                                      : Icons.check_circle_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  ocorrencia.resolvida
                                      ? 'Reativar'
                                      : 'Resolver',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ocorrencia.resolvida
                                      ? AppColors.statusEnRoute
                                      : AppColors.statusResolved,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _deletarOcorrencia(ocorrencia),
                                icon: const Icon(Icons.delete_rounded,
                                    size: 18),
                                label: const Text('Excluir'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusActive,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!ocorrencia.resolvida)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _alterarStatusOcorrencia(ocorrencia),
                            icon: const Icon(Icons.check_circle_rounded,
                                size: 18),
                            label: const Text('Marcar como Resolvida'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusResolved,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComentarioItem(Comentario comentario) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundOffWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    comentario.usuarioNome.isNotEmpty
                        ? comentario.usuarioNome[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comentario.usuarioNome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _formatarData(comentario.dataHora),
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comentario.texto,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (comentario.agentes != null && comentario.agentes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.groups_rounded,
                      size: 14, color: AppColors.accentAmber),
                  const SizedBox(width: 4),
                  Text(
                    'Agentes: ${comentario.agentes}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accentAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryTeal.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryTeal),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarComentario(Ocorrencia ocorrencia) {
    final usuarioProvider = context.read<UsuarioProvider>();
    if (!usuarioProvider.isAdmin) return;
    if (_comentarioController.text.trim().isEmpty) return;

    final comentario = Comentario(
      texto: _comentarioController.text.trim(),
      usuarioNome: 'Administrador',
      usuarioId: usuarioProvider.usuarioLogado?.id,
    );

    context.read<OcorrenciaProvider>().adicionarComentario(
        ocorrencia.id, comentario);
    _comentarioController.clear();
    Navigator.pop(context);
    _atualizarMarcadores();
  }

  void _alterarStatusOcorrencia(Ocorrencia ocorrencia) {
    if (ocorrencia.resolvida) {
      final atualizada = ocorrencia.copyWith(
        resolvida: false,
        dataResolucao: null,
      );
      context.read<OcorrenciaProvider>().atualizarOcorrencia(atualizada);
    } else {
      context.read<OcorrenciaProvider>().resolverOcorrencia(ocorrencia.id);
    }
    Navigator.pop(context);
    _atualizarMarcadores();
  }

  void _deletarOcorrencia(Ocorrencia ocorrencia) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Confirmar exclusão'),
        content:
            const Text('Tem certeza que deseja deletar esta ocorrência?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<OcorrenciaProvider>().deletarOcorrencia(
                  ocorrencia.id);
              Navigator.pop(context);
              Navigator.pop(context);
              _atualizarMarcadores();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusActive,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _editarFoto(Ocorrencia ocorrencia) async {
    final escolha = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.primaryTeal),
                  ),
                  title: const Text('Tirar foto',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded,
                        color: AppColors.accentAmber),
                  ),
                  title: const Text('Escolher da galeria',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (escolha == null) return;

    try {
      final sheetCtx = context;
      final foto = await _imagePicker.pickImage(
        source: escolha,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (foto != null) {
        final atualizada = ocorrencia.copyWith(caminhoFoto: foto.path);
        await context
            .read<OcorrenciaProvider>()
            .atualizarOcorrencia(atualizada);
        _atualizarMarcadores();
        Navigator.pop(sheetCtx);
        await Future.delayed(const Duration(milliseconds: 100));
        _mostrarDetalhesOcorrencia(atualizada);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter foto: $e')),
      );
    }
  }

  Future<void> _editarCoordenadas(Ocorrencia ocorrencia) async {
    final latController =
        TextEditingController(text: ocorrencia.latitude.toString());
    final lngController =
        TextEditingController(text: ocorrencia.longitude.toString());
    final sheetCtx = context;

    await showDialog(
      context: context,
      builder: (dlgCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Editar Coordenadas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final lat = double.tryParse(latController.text);
                final lng = double.tryParse(lngController.text);
                if (lat != null && lng != null) {
                  final atualizada =
                      ocorrencia.copyWith(latitude: lat, longitude: lng);
                  context
                      .read<OcorrenciaProvider>()
                      .atualizarOcorrencia(atualizada);
                  _atualizarMarcadores();
                  Navigator.pop(dlgCtx);
                  Navigator.pop(sheetCtx);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _mostrarDetalhesOcorrencia(atualizada);
                  });
                  return;
                }
                Navigator.pop(dlgCtx);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = context.watch<UsuarioProvider>();
    final nomeUsuario = usuarioProvider.estaLogado
        ? usuarioProvider.usuarioLogado!.nome.split(' ').first
        : 'Cidadão';

    return Scaffold(
      body: _indiceAbaAtual == 0
          ? _construirTelaMapa(nomeUsuario)
          : _indiceAbaAtual == 1
              ? const HistoricoScreen()
              : const PerfilScreen(),
      floatingActionButton: _indiceAbaAtual == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final resultado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const SelecaoTipoOcorrenciaScreen(),
                  ),
                );
                if (resultado == true) {
                  _inicializarMapa();
                }
              },
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text('Nova Ocorrência'),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceAbaAtual,
          onTap: (indice) {
            setState(() {
              _indiceAbaAtual = indice;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Histórico',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTelaMapa(String nomeUsuario) {
    final searchResults = _getFilteredOcorrencias();

    return Stack(
      children: [
        // Mapa
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _posicaoAtual != null
                ? LatLng(
                    _posicaoAtual!.latitude, _posicaoAtual!.longitude)
                : const LatLng(-22.9292618, -46.2753862),
            zoom: 14,
            minZoom: 5,
            maxZoom: 18,
            onTap: (_, __) {
              setState(() {
                _showSearchResults = false;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.defensacivil.app',
              retinaMode: true,
            ),
            MarkerLayer(markers: _markers),
            if (_posicaoAtual != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_posicaoAtual!.latitude,
                        _posicaoAtual!.longitude),
                    builder: (context) => Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryTeal.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Header com gradiente
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saudação
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, $nomeUsuario! 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Defesa em Foco',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Refresh
                            GestureDetector(
                              onTap: _inicializarMapa,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search bar
                    SearchBarWidget(
                      controller: _searchController,
                      hintText: 'Buscar ocorrências...',
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _showSearchResults = value.isNotEmpty;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Resultados da pesquisa
        if (_showSearchResults && searchResults.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 140,
            left: 16,
            right: 16,
            bottom: 100,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundOffWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final ocorrencia = searchResults[index];
                    return OcorrenciaCard(
                      ocorrencia: ocorrencia,
                      onTap: () {
                        setState(() {
                          _showSearchResults = false;
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        _mapController.move(
                          LatLng(ocorrencia.latitude,
                              ocorrencia.longitude),
                          16,
                        );
                        Future.delayed(
                            const Duration(milliseconds: 300),
                            () =>
                                _mostrarDetalhesOcorrencia(ocorrencia));
                      },
                    );
                  },
                ),
              ),
            ),
          ),

        // Contador
        if (!_showSearchResults)
          Positioned(
            top: MediaQuery.of(context).padding.top + 150,
            left: 16,
            child: Consumer<OcorrenciaProvider>(
              builder: (context, provider, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.statusActive,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${provider.ocorrenciasAtivas.length} ocorrências ativas',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}