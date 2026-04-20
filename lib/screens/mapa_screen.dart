import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/ocorrencia_tipos.dart';
import '../models/ocorrencia.dart';
import '../models/ponto_interesse.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../providers/ponto_interesse_provider.dart';
import '../services/localizacao_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/status_badge.dart';
import '../widgets/ocorrencia_card.dart';
import '../widgets/ocorrencia_image.dart';
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
    final usuarioProv = context.read<UsuarioProvider>();
    final ocorrenciaProv = context.read<OcorrenciaProvider>();
    
    // Prioridade: Cidade Ativa (Logado ou GPS Detectado)
    final cidadeFiltro = usuarioProv.cidadeAtiva;
    
    // Só carregamos se soubermos a cidade (Isolamento Geográfico Estrito)
    if (cidadeFiltro != null && cidadeFiltro.isNotEmpty) {
      await ocorrenciaProv.carregarOcorrencias(cidade: cidadeFiltro, userId: usuarioProv.usuarioLogado?.id);
      if (!mounted) return;
      await context.read<PontoInteresseProvider>().carregarPontos(cidade: cidadeFiltro);
    } else {
      debugPrint('⚠️ Mapa inicializado sem cidade de contexto. Nada será exibido.');
    }
    
    // Na inicialização, centralizamos sem animação brusca se possível
    await _centralizarLocalizacao(animar: true);
  }

  Future<void> _centralizarLocalizacao({bool animar = true}) async {
    final posicao = await _localizacaoService.obterPosicaoAtual();
    if (posicao != null && mounted) {
      setState(() {
        _posicaoAtual = posicao;
      });
      
      if (animar) {
        _mapController.move(
          LatLng(posicao.latitude, posicao.longitude),
          15,
        );
      }
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
        decoration:  const BoxDecoration(
          color: AppColors.backgroundOffWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Builder(
          builder: (context) {
            final usuarioLogado = usuarioProvider.usuarioLogado;
            final meuNome = usuarioLogado?.nome.trim().toLowerCase() ?? '';
            final listaAgentes = ocorrencia.agentes?.split(',').map((s) => s.trim().toLowerCase()).toList() ?? [];
            final isDesignado = meuNome.isNotEmpty && listaAgentes.contains(meuNome);
            final podeAgir = usuarioProvider.isAdmin || isDesignado;
            
            return Column(
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
                    AppColors.getTipoColor(ocorrencia.tipo).withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
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
                          status: ocorrencia.status,
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
                          child: OcorrenciaImage(caminho: ocorrencia.caminhoFoto!),
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

                    if (usuarioProvider.isAdmin && ocorrencia.status != OcorrenciaStatus.resolvida)
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

                    const SizedBox(height: 12),

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
                                  onSelected: (selected) async {
                                    final agentesAtuais = o.agentes?.isEmpty == false 
                                        ? o.agentes!.split(', ').toList() 
                                        : <String>[];
                                    if (selected) {
                                      agentesAtuais.add(agente.nome);
                                    } else {
                                      agentesAtuais.remove(agente.nome);
                                    }
                                    
                                    final novoTexto = agentesAtuais.join(', ');
                                    final ocorrenciaAtualizada = o.copyWith(agentes: novoTexto, status: OcorrenciaStatus.aprovada);
                                    
                                    try {
                                      await context.read<OcorrenciaProvider>().atualizarOcorrencia(ocorrenciaAtualizada);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erro ao salvar atribuição: ${e.toString()}'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                  selectedColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                                  checkmarkColor: AppColors.primaryTeal,
                                );
                              }).toList(),
                            );
                          }
                        ),
                      ),

                    const SizedBox(height: 12),
                    
                    if (usuarioProvider.isAdmin && ocorrencia.status == OcorrenciaStatus.pendenteAprovacao)
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

                    // Botão de Chegada no Local (Apenas para Agentes Designados ou Admins)
                    if (podeAgir && 
                        ocorrencia.status == OcorrenciaStatus.aprovada && 
                        !ocorrencia.agenteNoLocal)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                          onPressed: () async { 
                            try {
                              final parecer = _comentarioController.text.trim();
                              await context.read<OcorrenciaProvider>().registrarChegadaAgente(ocorrencia.id, parecer: parecer.isNotEmpty ? parecer : null); 
                              _comentarioController.clear();
                              if (context.mounted) Navigator.pop(context); 
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Falha na sincronização: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          }, 
                            icon: const Icon(Icons.location_on_rounded), 
                            label: const Text('ESTOU NO LOCAL'), 
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                          ),
                        ),
                      ),

                    // Botões de Administrador
                    if (usuarioProvider.isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _alterarStatusOcorrencia(ocorrencia), 
                                icon: Icon(ocorrencia.status == OcorrenciaStatus.resolvida ? Icons.refresh_rounded : Icons.check_circle_rounded, size: 18), 
                                label: Text(ocorrencia.status == OcorrenciaStatus.resolvida ? 'Reativar' : 'Resolver'), 
                                style: ElevatedButton.styleFrom(backgroundColor: ocorrencia.status == OcorrenciaStatus.resolvida ? AppColors.statusEnRoute : AppColors.statusResolved),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: ElevatedButton.icon(onPressed: () => _deletarOcorrencia(ocorrencia), icon: const Icon(Icons.delete_rounded, size: 18), label: const Text('Excluir'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusActive))),
                          ],
                        ),
                      )
                    // Botão de Resolver para Agentes Designados
                    else if ((ocorrencia.status == OcorrenciaStatus.aprovada || ocorrencia.status == OcorrenciaStatus.trabalhandoAtualmente) && 
                             ocorrencia.status != OcorrenciaStatus.resolvida && 
                             podeAgir)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: SizedBox(
                          width: double.infinity, 
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final parecer = _comentarioController.text.trim();
                                await context.read<OcorrenciaProvider>().resolverOcorrencia(ocorrencia.id, parecer: parecer.isNotEmpty ? parecer : null);
                                _comentarioController.clear();
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Falha na sincronização: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }, 
                            icon: const Icon(Icons.check_circle_rounded, size: 18), 
                            label: const Text('Marcar como Resolvida'), 
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusResolved),
                          ),
                        ),
                      ),
                       SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
                    ],
                  ),
              ),
            ),
            ],
            );
          }
        ),
      ),
    ).then((_) {
      // Ao fechar o painel de detalhes, recarregar para refletir mudanças de status
      if (mounted) _inicializarMapa();
    });
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


  void _alterarStatusOcorrencia(Ocorrencia ocorrencia) {
    if (ocorrencia.status == OcorrenciaStatus.resolvida) {
      context.read<OcorrenciaProvider>().atualizarOcorrencia(ocorrencia.copyWith(status: OcorrenciaStatus.aprovada, dataResolucao: null));
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
    final foto = await _imagePicker.pickImage(
      source: escolha,
      imageQuality: 50,
      maxWidth: 1024,
      maxHeight: 1024,
    );
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
          : _indiceAbaAtual == 1 ?  const HistoricoScreen() :  const PerfilScreen(),
      floatingActionButton: _indiceAbaAtual == 0 
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (usuarioProvider.isAdmin) ...[
                  FloatingActionButton.extended(
                    heroTag: 'fab_poi',
                    onPressed: () => _confirmarNovoPontoInteresse(_mapController.center),
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text('Ponto de Interesse'),
                    backgroundColor: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton.extended(
                  heroTag: 'fab_ocorrencia',
                  onPressed: () async {
                    final res = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) =>  const SelecaoTipoOcorrenciaScreen()));
                    if (res == true && mounted) {
                      _inicializarMapa();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nova Ocorrência'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'fab_gps',
                  onPressed: () => _centralizarLocalizacao(),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryTeal,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            )
          : null,
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
            center: _posicaoAtual != null ? LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude) :  const LatLng(-22.9292, -46.2753),
            zoom: 14,
            minZoom: 5,
            maxZoom: 18,
            onTap: (_, __) => setState(() => _showSearchResults = false),
            onLongPress: (_, latlng) { if (userProv.isAdmin) _confirmarNovoPontoInteresse(latlng); },
            maxBounds: LatLngBounds(
              const LatLng(-33.0, -73.0),
              const LatLng(5.0, -34.0),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.defesacivil.app',
            ),
            MarkerLayer(markers: markers),
            if (_posicaoAtual != null) MarkerLayer(markers: [Marker(point: LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude), builder: (_) => const Icon(Icons.my_location, color: Colors.blue, size: 20))]),
          ],
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration:  const BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
            child: SafeArea(child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Olá, $nomeUsuario!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _inicializarMapa)]), const SizedBox(height: 16), SearchBarWidget(controller: _searchController, hintText: 'Buscar...', onChanged: (v) => setState(() { _searchQuery = v; _showSearchResults = v.isNotEmpty; }))])),
          ),
        ),
        if (_showSearchResults && searchResults.isNotEmpty) Positioned(top: 180, left: 16, right: 16, bottom: 100, child: Container(color: Colors.white, child: ListView.builder(itemCount: searchResults.length, itemBuilder: (_, i) => OcorrenciaCard(ocorrencia: searchResults[i], onTap: () { setState(() { _showSearchResults = false; _searchController.clear(); _searchQuery = ''; }); _mapController.move(LatLng(searchResults[i].latitude, searchResults[i].longitude), 16); _mostrarDetalhesOcorrencia(searchResults[i]); })))),
      ],
    );
  }

  // _buildOcorrenciaImage removido pois agora usamos o widget OcorrenciaImage

  // _buildOcorrenciaImage removido pois agora usamos o widget OcorrenciaImage

  void _confirmarNovoPontoInteresse(LatLng latlng) async {
    final res = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => RegistroPontoInteresseScreen(posicao: latlng)));
    if (res == true && mounted) {
      _inicializarMapa();
    }
  }

  void _mostrarDetalhesPOI(PontoInteresse p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(p.tipo.replaceAll('_', ' '), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Text(p.descricao, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4)),
            if (context.read<UsuarioProvider>().isAdmin) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () { 
                    context.read<PontoInteresseProvider>().deletarPonto(p.id); 
                    Navigator.pop(context); 
                  }, 
                  icon: const Icon(Icons.delete_rounded),
                  label: const Text('Remover Ponto de Interesse'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusActive, foregroundColor: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}