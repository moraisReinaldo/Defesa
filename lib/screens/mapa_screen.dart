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
import '../models/ponto_interesse.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../providers/ponto_interesse_provider.dart';
import '../services/localizacao_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/status_badge.dart';
import '../widgets/ocorrencia_card.dart';
import 'registro_ocorrencia_screen.dart'; // Contém SelecaoTipoOcorrenciaScreen
import 'historico_screen.dart';
import 'perfil_screen.dart';
import 'registro_ponto_interesse_screen.dart';

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
  int _indiceAbaAtual = 0;
  String _searchQuery = '';
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _inicializarMapa();
  }

  Future<void> _inicializarMapa() async {
    if (!mounted) return;
    await context.read<OcorrenciaProvider>().carregarOcorrencias();
    if (!mounted) return;
    await context.read<PontoInteresseProvider>().carregarPontos(
      cidade: context.read<UsuarioProvider>().usuarioLogado?.cidade
    );
    _posicaoAtual = await _localizacaoService.obterPosicaoAtual();

    if (_posicaoAtual != null && mounted) {
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

  void _mostrarDetalhesOcorrencia(Ocorrencia pOcorrencia) {
    Ocorrencia ocorrencia = pOcorrencia;
    final usuarioProvider = context.read<UsuarioProvider>();
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
              width: 40, height: 4,
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
                    width: 56, height: 56,
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

                    if (ocorrencia.caminhoFoto != null && ocorrencia.caminhoFoto!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, 3))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(ocorrencia.caminhoFoto!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 200,
                              color: AppColors.shimmer,
                              child: const Center(child: Icon(Icons.image_not_supported_rounded, color: AppColors.textLight, size: 40)),
                            ),
                          ),
                        ),
                      ),

                    _buildSectionCard(
                      icon: Icons.info_rounded,
                      title: 'Informações',
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.calendar_today_rounded, 'Data', _formatarData(ocorrencia.dataHora)),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.location_on_rounded, 'Coordenadas', '${ocorrencia.latitude.toStringAsFixed(4)}, ${ocorrencia.longitude.toStringAsFixed(4)}'),
                        ],
                      ),
                    ),

                    if (usuarioProvider.isAdmin && !ocorrencia.resolvida)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(child: _buildActionChip(icon: Icons.edit_location_alt_rounded, label: 'Coordenadas', onTap: () => _editarCoordenadas(ocorrencia))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildActionChip(icon: Icons.photo_camera_rounded, label: 'Trocar foto', onTap: () => _editarFoto(ocorrencia))),
                          ],
                        ),
                      ),

                    _buildSectionCard(
                      icon: Icons.chat_bubble_rounded,
                      title: 'Comentários',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ocorrencia.comentarios.isEmpty)
                            const Text('Nenhum comentário ainda.', style: TextStyle(color: AppColors.textLight, fontSize: 13, fontStyle: FontStyle.italic))
                          else
                            ...ocorrencia.comentarios.map((c) => _buildComentarioItem(c)),

                          if (usuarioProvider.isAdmin) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _comentarioController,
                              decoration: InputDecoration(
                                hintText: 'Adicionar comentário...',
                                filled: true,
                                fillColor: AppColors.backgroundOffWhite,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                suffixIcon: IconButton(icon: const Icon(Icons.send_rounded, color: AppColors.primaryTeal), onPressed: () => _adicionarComentario(ocorrencia)),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (usuarioProvider.isAdmin)
                      _buildSectionCard(
                        icon: Icons.groups_rounded,
                        title: 'Agentes a caminho',
                        child: StatefulBuilder(
                          builder: (context, setSheetState) {
                            final agentesGerais = context.watch<UsuarioProvider>().todosAgentes;
                            final o = context.watch<OcorrenciaProvider>().ocorrencias.firstWhere((x) => x.id == ocorrencia.id, orElse: () => ocorrencia);
                            final agentesAtuais = o.agentes?.split(', ').where((s) => s.isNotEmpty).toList() ?? [];

                            return Wrap(
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
                                    
                                    if (selected) {
                                      final comentario = Comentario(texto: 'Agente ${agente.nome} associado', usuarioNome: 'Sistema');
                                      context.read<OcorrenciaProvider>().adicionarComentario(ocorrencia.id, comentario);
                                    }
                                  },
                                  selectedColor: AppColors.primaryTeal.withOpacity(0.2),
                                  checkmarkColor: AppColors.primaryTeal,
                                );
                              }).toList(),
                            );
                          }
                        ),
                      ),

                    const SizedBox(height: 12),
                    
                    if (usuarioProvider.isAdmin && ocorrencia.status == OcorrenciaStatus.PENDENTE_APROVACAO)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(child: ElevatedButton.icon(onPressed: () async { await context.read<OcorrenciaProvider>().aprovarOcorrencia(ocorrencia.id); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.check_circle_rounded), label: const Text('APROVAR'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))),
                            const SizedBox(width: 8),
                            Expanded(child: ElevatedButton.icon(onPressed: () async { await context.read<OcorrenciaProvider>().deletarOcorrencia(ocorrencia.id); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.cancel_rounded), label: const Text('RECUSAR'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red))),
                          ],
                        ),
                      ),

                    if (usuarioProvider.usuarioLogado?.isAgente == true && !usuarioProvider.isAdmin && ocorrencia.status == OcorrenciaStatus.APROVADA && !ocorrencia.agenteNoLocal)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(onPressed: () async { await context.read<OcorrenciaProvider>().registrarChegadaAgente(ocorrencia.id); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.location_on_rounded), label: const Text('ESTOU NO LOCAL'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal)),
                        ),
                      ),

                    if (usuarioProvider.isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          children: [
                            Expanded(child: ElevatedButton.icon(onPressed: () => _alterarStatusOcorrencia(ocorrencia), icon: Icon(ocorrencia.resolvida ? Icons.refresh_rounded : Icons.check_circle_rounded, size: 18), label: Text(ocorrencia.resolvida ? 'Reativar' : 'Resolver'), style: ElevatedButton.styleFrom(backgroundColor: ocorrencia.resolvida ? AppColors.statusEnRoute : AppColors.statusResolved))),
                            const SizedBox(width: 8),
                            Expanded(child: ElevatedButton.icon(onPressed: () => _deletarOcorrencia(ocorrencia), icon: const Icon(Icons.delete_rounded, size: 18), label: const Text('Excluir'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusActive))),
                          ],
                        ),
                      )
                    else if (ocorrencia.status == OcorrenciaStatus.APROVADA && !ocorrencia.resolvida && (usuarioProvider.usuarioLogado?.isAgente == true))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _alterarStatusOcorrencia(ocorrencia), icon: const Icon(Icons.check_circle_rounded, size: 18), label: const Text('Marcar como Resolvida'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusResolved))),
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

  Widget _buildSectionCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: AppColors.primaryTeal), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, size: 15, color: AppColors.textLight), const SizedBox(width: 8), Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Expanded(child: Text(value, style: const TextStyle(fontSize: 13)))]);
  }

  Widget _buildComentarioItem(Comentario comentario) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.backgroundOffWhite, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, child: Text(comentario.usuarioNome.isNotEmpty ? comentario.usuarioNome[0].toUpperCase() : '?')),
              const SizedBox(width: 8),
              Expanded(child: Text(comentario.usuarioNome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Text(_formatarData(comentario.dataHora), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 6),
          Text(comentario.texto, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(color: AppColors.primaryTeal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: AppColors.primaryTeal), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal))]),
      ),
    );
  }

  void _adicionarComentario(Ocorrencia ocorrencia) {
    final user = context.read<UsuarioProvider>().usuarioLogado;
    if (_comentarioController.text.trim().isEmpty) return;
    context.read<OcorrenciaProvider>().adicionarComentario(ocorrencia.id, Comentario(texto: _comentarioController.text.trim(), usuarioNome: user?.nome ?? 'Admin', usuarioId: user?.id));
    _comentarioController.clear();
    Navigator.pop(context);
  }

  void _alterarStatusOcorrencia(Ocorrencia ocorrencia) {
    if (ocorrencia.resolvida) {
      context.read<OcorrenciaProvider>().atualizarOcorrencia(ocorrencia.copyWith(resolvida: false, dataResolucao: null));
    } else {
      context.read<OcorrenciaProvider>().resolverOcorrencia(ocorrencia.id);
    }
    Navigator.pop(context);
  }

  void _deletarOcorrencia(Ocorrencia ocorrencia) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Não')),
          ElevatedButton(onPressed: () { 
            context.read<OcorrenciaProvider>().deletarOcorrencia(ocorrencia.id); 
            Navigator.pop(context); 
            Navigator.pop(context); 
          }, child: const Text('Sim')),
        ],
      ),
    );
  }

  Future<void> _editarFoto(Ocorrencia ocorrencia) async {
    final escolha = await showModalBottomSheet<ImageSource?>(context: context, builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.camera), title: const Text('Câmera'), onTap: () => Navigator.pop(context, ImageSource.camera)), ListTile(leading: const Icon(Icons.image), title: const Text('Galeria'), onTap: () => Navigator.pop(context, ImageSource.gallery))]));
    if (escolha == null) return;
    final foto = await _imagePicker.pickImage(source: escolha);
    if (foto != null && mounted) {
      await context.read<OcorrenciaProvider>().atualizarOcorrencia(ocorrencia.copyWith(caminhoFoto: foto.path));
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _editarCoordenadas(Ocorrencia ocorrencia) async {
    final latC = TextEditingController(text: ocorrencia.latitude.toString());
    final lngC = TextEditingController(text: ocorrencia.longitude.toString());
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Coordenadas'), 
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: latC), TextField(controller: lngC)]), 
      actions: [ElevatedButton(onPressed: () { 
        final lat = double.tryParse(latC.text);
        final lng = double.tryParse(lngC.text);
        if (lat != null && lng != null) {
          context.read<OcorrenciaProvider>().atualizarOcorrencia(ocorrencia.copyWith(latitude: lat, longitude: lng));
        }
        Navigator.pop(ctx); 
        Navigator.pop(context); 
      }, child: const Text('Salvar'))]
    ));
  }

  String _formatarData(DateTime data) => '${data.day}/${data.month}/${data.year} ${data.hour}:${data.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = context.watch<UsuarioProvider>();
    final ocorrenciaProvider = context.watch<OcorrenciaProvider>();
    final poiProvider = context.watch<PontoInteresseProvider>();

    final nomeUsuario = usuarioProvider.usuarioLogado?.nome.split(' ').first ?? 'Cidadão';
    final markers = <Marker>[];

    for (final o in ocorrenciaProvider.ocorrenciasAtivas) {
      final color = AppColors.getTipoColor(o.tipo);
      markers.add(Marker(
        point: LatLng(o.latitude, o.longitude), 
        builder: (ctx) => GestureDetector(
          onTap: () => _mostrarDetalhesOcorrencia(o), 
          child: Container(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), 
            child: Icon(OcorrenciaTipos.getTipoIcone(o.tipo), color: Colors.white, size: 18)
          )
        )
      ));
    }

    final Map<String, IconData> poiIcons = {'PONTO_COLETA_AGUA': Icons.water_drop, 'AREA_RISCO': Icons.warning, 'ABRIGO': Icons.home, 'DESLIZAMENTO': Icons.terrain, 'OUTRO': Icons.location_on};
    final Map<String, Color> poiColors = {'PONTO_COLETA_AGUA': Colors.blue, 'AREA_RISCO': Colors.orange, 'ABRIGO': Colors.green, 'DESLIZAMENTO': Colors.brown, 'OUTRO': Colors.grey};

    for (final p in poiProvider.pontos) {
      final color = poiColors[p.tipo] ?? Colors.grey;
      markers.add(Marker(
        point: LatLng(p.latitude, p.longitude), 
        builder: (ctx) => GestureDetector(
          onTap: () => _mostrarDetalhesPOI(p), 
          child: Container(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), 
            child: Icon(poiIcons[p.tipo] ?? Icons.place, color: Colors.white, size: 20)
          )
        )
      ));
    }

    return Scaffold(
      body: _indiceAbaAtual == 0
          ? _construirTelaMapa(nomeUsuario, markers, usuarioProvider)
          : _indiceAbaAtual == 1 ? const HistoricoScreen() : const PerfilScreen(),
      floatingActionButton: _indiceAbaAtual == 0 ? FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SelecaoTipoOcorrenciaScreen())), icon: const Icon(Icons.add), label: const Text('Nova Ocorrência')) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAbaAtual,
        onTap: (i) => setState(() => _indiceAbaAtual = i),
        items: const [BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'), BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil')],
      ),
    );
  }

  Widget _construirTelaMapa(String nomeUsuario, List<Marker> markers, UsuarioProvider userProv) {
    final searchResults = _getFilteredOcorrencias();
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _posicaoAtual != null ? LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude) : const LatLng(-22.9292, -46.2753),
            zoom: 14,
            onTap: (_, __) => setState(() => _showSearchResults = false),
            onLongPress: (_, latlng) { if (userProv.isAdmin) _confirmarNovoPontoInteresse(latlng); },
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(markers: markers),
            if (_posicaoAtual != null) MarkerLayer(markers: [Marker(point: LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude), builder: (_) => const Icon(Icons.my_location, color: Colors.blue, size: 20))]),
          ],
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
            child: SafeArea(child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Olá, $nomeUsuario!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _inicializarMapa)]), const SizedBox(height: 16), SearchBarWidget(controller: _searchController, hintText: 'Buscar...', onChanged: (v) => setState(() { _searchQuery = v; _showSearchResults = v.isNotEmpty; }))])),
          ),
        ),
        if (_showSearchResults && searchResults.isNotEmpty) Positioned(top: 180, left: 16, right: 16, bottom: 100, child: Container(color: Colors.white, child: ListView.builder(itemCount: searchResults.length, itemBuilder: (_, i) => OcorrenciaCard(ocorrencia: searchResults[i], onTap: () { setState(() { _showSearchResults = false; _searchController.clear(); _searchQuery = ''; }); _mapController.move(LatLng(searchResults[i].latitude, searchResults[i].longitude), 16); _mostrarDetalhesOcorrencia(searchResults[i]); })))),
      ],
    );
  }

  void _confirmarNovoPontoInteresse(LatLng latlng) async {
    final res = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => RegistroPontoInteresseScreen(posicao: latlng)));
    if (res == true && mounted) {
      _inicializarMapa();
    }
  }

  void _mostrarDetalhesPOI(PontoInteresse p) {
    showModalBottomSheet(context: context, builder: (_) => Container(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(p.tipo), Text(p.descricao), if (context.read<UsuarioProvider>().isAdmin) ElevatedButton(onPressed: () { context.read<PontoInteresseProvider>().deletarPonto(p.id); Navigator.pop(context); }, child: const Text('Remover'))])));
  }
}