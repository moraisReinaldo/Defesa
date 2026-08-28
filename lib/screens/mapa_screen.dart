// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/ocorrencia_tipos.dart';
import '../models/ocorrencia.dart';
import '../models/ponto_interesse.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../providers/ponto_interesse_provider.dart';
import '../services/localizacao_service.dart';
import '../services/clima_service.dart';
import '../services/geocoding_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/status_badge.dart';
import '../widgets/ocorrencia_card.dart';
import '../widgets/ocorrencia_image.dart';
import '../widgets/aviso_comunitario_dialog.dart';
import '../widgets/responsive_layout.dart';
import 'registro_ocorrencia_screen.dart'; // Contém SelecaoTipoOcorrenciaScreen
import 'historico_screen.dart';
import 'perfil_screen.dart';
import 'registro_ponto_interesse_screen.dart';
import 'dashboard_relatorios_screen.dart';
import 'cadastro_agente_screen.dart';
import 'gerenciar_poi_screen.dart';
import '../widgets/alerta_banner_widget.dart';
import '../widgets/mapa_context_menu_widget.dart';

class MapaScreen extends StatefulWidget {
   const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final GeocodingService _geocodingService = GeocodingService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();

  Position? _posicaoAtual;
  int _indiceAbaAtual = 0;
  String _searchQuery = '';
  bool _showSearchResults = false;
  List<EnderecoSugestao> _enderecoSugestoes = [];
  bool _buscandoEnderecos = false;
  Timer? _searchDebounce;
  LatLng? _marcadorEnderecoSelecionado;
  String? _nomeEnderecoSelecionado;
  
  StreamSubscription<Position>? _positionSubscription;
  bool _mapaCentralizadoInicialmente = false;

  @override
  void initState() {
    super.initState();
    _inicializarMapa();
    _iniciarSeguimentoLocalizacao();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storage = context.read<UsuarioProvider>().storageService;
      AvisoComunitarioDialog.exibirSeNecessario(context, storage);
    });
  }

  void _iniciarSeguimentoLocalizacao() {
    _positionSubscription = _localizacaoService.obterFluxoPosicao().listen((posicao) {
      if (mounted) {
        setState(() {
          _posicaoAtual = posicao;
        });
        
        // Se ainda não centralizamos o mapa, fazemos agora
        if (!_mapaCentralizadoInicialmente) {
          _mapaCentralizadoInicialmente = true;
          _mapController.move(LatLng(posicao.latitude, posicao.longitude), 15);
        }
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  void _aoAlterarBusca(String v) {
    setState(() {
      _searchQuery = v;
      _showSearchResults = v.isNotEmpty;
    });

    _searchDebounce?.cancel();
    if (v.trim().length >= 3) {
      setState(() => _buscandoEnderecos = true);
      _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
        final resultados = await _geocodingService.buscarEnderecos(v);
        if (mounted && _searchQuery == v) {
          setState(() {
            _enderecoSugestoes = resultados;
            _buscandoEnderecos = false;
          });
        }
      });
    } else {
      setState(() {
        _enderecoSugestoes = [];
        _buscandoEnderecos = false;
      });
    }
  }

  Future<void> _inicializarMapa() async {
    final usuarioProv = context.read<UsuarioProvider>();
    final ocorrenciaProv = context.read<OcorrenciaProvider>();
    final pontoProv = context.read<PontoInteresseProvider>();
    final cidadeFiltro = usuarioProv.cidadeAtiva;

    // Centraliza o mapa imediatamente na cidade do Administrador / usuário sem travar
    final coords = ClimaService.obterCoordenadasCidade(cidadeFiltro);
    _mapController.move(LatLng(coords['lat']!, coords['lng']!), 14);

    // Carregamento ultrarrápido em paralelo de ocorrências e pontos
    final carregarOc = ocorrenciaProv.carregarOcorrencias(
      cidade: cidadeFiltro, 
      userId: usuarioProv.usuarioLogado?.id,
      isAdmin: usuarioProv.isAdmin,
    );
    final carregarPoi = pontoProv.carregarPontos(cidade: cidadeFiltro);
    
    await Future.wait([carregarOc, carregarPoi]);

    // Atualiza GPS em segundo plano sem travar o carregamento inicial
    if (cidadeFiltro == null || cidadeFiltro.isEmpty) {
      _centralizarLocalizacao(animar: false);
    }
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
    final ativas = context.read<OcorrenciaProvider>().ocorrenciasAtivas;
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    return ativas.where((o) {
      final tipoNome = OcorrenciaTipos.getTipoNome(o.tipo).toLowerCase();
      final desc = o.descricao.toLowerCase();
      return tipoNome.contains(query) || desc.contains(query);
    }).toList();
  }

  Future<void> _showResponsiveModal(BuildContext context, Widget Function(BuildContext) builder) async {
    if (ResponsiveLayout.isDesktop(context)) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        builder: (dialogCtx) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(dialogCtx).pop(),
          child: GestureDetector(
            onTap: () {}, // Impede que cliques dentro do card fechem o modal
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: builder(dialogCtx),
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: builder,
      );
    }
  }

  void _mostrarDetalhesOcorrencia(Ocorrencia pOcorrencia) {
    Ocorrencia ocorrencia = pOcorrencia;
    final usuarioProvider = context.read<UsuarioProvider>();
    _showResponsiveModal(
      context,
      (context) => Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 600,
          ),
          decoration: const BoxDecoration(
            color: AppColors.backgroundOffWhite,
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
        child: Builder(
          builder: (modalCtx) {
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
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(modalCtx),
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

                    // Designação de agentes — apenas quando aprovada (nunca em pendente)
                    if (usuarioProvider.isAdmin &&
                        (ocorrencia.status == OcorrenciaStatus.aprovada ||
                         ocorrencia.status == OcorrenciaStatus.trabalhandoAtualmente))
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
                                    
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      await context.read<OcorrenciaProvider>().atualizarOcorrencia(ocorrenciaAtualizada);
                                    } catch (e) {
                                      if (mounted) {
                                        messenger.showSnackBar(
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
                              // Auto-atribuição: adiciona o agente à lista se ainda não estiver
                              final nomeAgente = usuarioLogado?.nome.trim() ?? '';
                              if (nomeAgente.isNotEmpty) {
                                final agentesAtuais = ocorrencia.agentes
                                    ?.split(', ')
                                    .where((s) => s.isNotEmpty)
                                    .toList() ?? [];
                                final jaEstaLista = agentesAtuais
                                    .any((s) => s.trim().toLowerCase() == nomeAgente.toLowerCase());
                                if (!jaEstaLista) {
                                  agentesAtuais.add(nomeAgente);
                                  final ocorrenciaAtualizada = ocorrencia.copyWith(
                                    agentes: agentesAtuais.join(', '),
                                  );
                                  await context.read<OcorrenciaProvider>().atualizarOcorrencia(ocorrenciaAtualizada);
                                  // Atualiza referência local para refletir os novos agentes
                                  ocorrencia = ocorrenciaAtualizada;
                                }
                              }

                              ScaffoldMessenger.of(context);
                              final parecer = _comentarioController.text.trim();
                              await context.read<OcorrenciaProvider>().registrarChegadaAgente(ocorrencia.id, parecer: parecer.isNotEmpty ? parecer : null); 
                              _comentarioController.clear();
                              if (mounted) Navigator.pop(context); 
                            } catch (e) {
                              if (mounted) {
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

                    // Botões de Administrador — resolver/reativar (apenas para aprovadas ou trabalhando)
                    if (usuarioProvider.isAdmin &&
                        ocorrencia.status != OcorrenciaStatus.pendenteAprovacao)
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
                            onPressed: () {
                              final messenger = ScaffoldMessenger.of(context);
                              final parecer = _comentarioController.text.trim();
                              
                              context.read<OcorrenciaProvider>()
                                .resolverOcorrencia(ocorrencia.id, parecer: parecer.isNotEmpty ? parecer : null)
                                .catchError((e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Falha na sincronização: ${e.toString().replaceAll('Exception: ', '')}'), 
                                      backgroundColor: Colors.red
                                    ),
                                  );
                                });
                                
                              _comentarioController.clear();
                              Navigator.pop(context);
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
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Não')),
          ElevatedButton(onPressed: () { 
            context.read<OcorrenciaProvider>().deletarOcorrencia(ocorrencia.id); 
            Navigator.pop(ctx); 
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

    final Map<String, IconData> poiIcons = {'PONTO_COLETA_AGUA': Icons.water_drop, 'AREA_RISCO': Icons.warning, 'ABRIGO': Icons.home, 'BASE_DEFESA': Icons.security, 'DESLIZAMENTO': Icons.terrain, 'OUTRO': Icons.location_on};
    final Map<String, Color> poiColors = {'PONTO_COLETA_AGUA': Colors.blue, 'AREA_RISCO': Colors.orange, 'ABRIGO': Colors.green, 'BASE_DEFESA': Colors.indigo, 'DESLIZAMENTO': Colors.brown, 'OUTRO': Colors.grey};

    for (final p in poiProvider.pontos) {
      final color = poiColors[p.tipo] ?? Colors.grey;
      markers.add(Marker(
        width: 36,
        height: 36,
        point: LatLng(p.latitude, p.longitude), 
        child: GestureDetector(
          onTap: () => _mostrarDetalhesPOI(p), 
          child: Container(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), 
            child: Icon(poiIcons[p.tipo] ?? Icons.place, color: Colors.white, size: 20)
          )
        )
      ));
    }

    for (final o in ocorrenciaProvider.ocorrenciasAtivas) {
      final color = AppColors.getTipoColor(o.tipo);
      markers.add(Marker(
        width: 36,
        height: 36,
        point: LatLng(o.latitude, o.longitude), 
        child: GestureDetector(
          onTap: () => _mostrarDetalhesOcorrencia(o), 
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), 
                child: Center(child: Icon(OcorrenciaTipos.getTipoIcone(o.tipo), color: Colors.white, size: 18))
              ),
              if (o.isLocal)
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.cloud_off_rounded, color: AppColors.accentAmber, size: 10),
                  ),
                ),
            ],
          )
        )
      ));
    }

    final bodyContent = IndexedStack(
      index: _indiceAbaAtual,
      children: [
        _construirTelaMapa(nomeUsuario, markers, usuarioProvider),
        const HistoricoScreen(),
        const PerfilScreen(),
      ],
    );
    final fabContent = _indiceAbaAtual == 0
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (usuarioProvider.isAdmin) ...[
                FloatingActionButton.extended(
                  heroTag: 'fab_poi',
                  onPressed: _onNovoPontoInteressePressed,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('Ponto de Interesse'),
                  backgroundColor: Colors.orange,
                ),
                const SizedBox(height: 12),
              ],
              FloatingActionButton.extended(
                heroTag: 'fab_ocorrencia',
                onPressed: () => _onNovaOcorrenciaPressed(usuarioProvider),
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
        : null;

    return ResponsiveLayout(
      mobile: Scaffold(
        body: bodyContent,
        floatingActionButton: fabContent,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _indiceAbaAtual,
          onTap: (i) {
            if (i == 0) _inicializarMapa();
            setState(() => _indiceAbaAtual = i);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Mapa'), 
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Histórico'), 
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil')
          ],
        ),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            _buildModernSidebar(usuarioProvider),
            Expanded(
              child: Scaffold(
                body: bodyContent,
                // O FAB flutuante no desktop agora é o botão da sidebar
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _executarAcaoContextMenu(MapaAction acao, LatLng latlng, UsuarioProvider userProv) {
    switch (acao) {
      case MapaAction.novoPontoInteresse:
        _confirmarNovoPontoInteresse(latlng);
        break;
      case MapaAction.novaOcorrencia:
        _onNovaOcorrenciaPressed(userProv, latlng: latlng);
        break;
      case MapaAction.emitirAlerta:
        final cidadeCod = userProv.cidadeAtiva;
        final cidadeNome = userProv.cidadesSuportadas.firstWhere(
          (c) => c['codigo'] == cidadeCod,
          orElse: () => {'nome': cidadeCod ?? 'Sua Jurisdição'},
        )['nome']!;
        AlertaBannerWidget.exibirModalEmitirAlerta(context, cidadeNome);
        break;
    }
  }

  Widget _buildModernSidebar(UsuarioProvider usuarioProvider) {
    final cidadeCodigo = usuarioProvider.cidadeAtiva;
    final cidadeNome = usuarioProvider.cidadesSuportadas.firstWhere(
      (c) => c['codigo'] == cidadeCodigo,
      orElse: () => {'nome': cidadeCodigo ?? 'Jurisdição Geral'},
    )['nome']!;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          right: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(4, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com Logo, Título e Jurisdição da Cidade
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_rounded, color: AppColors.primaryTeal, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Defesa em Foco',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (usuarioProvider.isAdmin) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_city_rounded, size: 14, color: AppColors.primaryTeal),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Jurisdição: $cidadeNome',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Itens Principais de Navegação
          _buildSidebarItem(0, Icons.map_rounded, 'Mapa Operacional', Icons.map_outlined),
          _buildSidebarItem(1, Icons.history_rounded, 'Histórico', Icons.history_outlined),
          _buildSidebarItem(2, Icons.person_rounded, 'Meu Perfil', Icons.person_outline_rounded),

          // Módulos Exclusivos do Administrador no Web
          if (usuarioProvider.isAdmin) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'PAINEL DO ADMINISTRADOR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _buildCustomSidebarAction(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard & Clima',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardRelatoriosScreen())),
            ),
            _buildCustomSidebarAction(
              icon: Icons.badge_rounded,
              label: 'Agentes da Cidade',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CadastroAgenteScreen())),
            ),
            _buildCustomSidebarAction(
              icon: Icons.roofing_rounded,
              label: 'Pontos de Apoio / Abrigos',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GerenciarPOIScreen())),
            ),
            _buildCustomSidebarAction(
              icon: Icons.campaign_rounded,
              label: 'Emitir Alerta Geral',
              onTap: () => AlertaBannerWidget.exibirModalEmitirAlerta(context, cidadeNome),
            ),
          ],

          const Spacer(),

          // Ações Rápidas de Cadastro
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (usuarioProvider.isAdmin) ...[
                  ElevatedButton.icon(
                    onPressed: _onNovoPontoInteressePressed,
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text('Ponto Interesse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                ElevatedButton.icon(
                  onPressed: () => _onNovaOcorrenciaPressed(usuarioProvider),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nova Ocorrência'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSidebarAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primaryTeal.withValues(alpha: 0.05),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData iconSelected, String label, IconData iconUnselected) {
    final isSelected = _indiceAbaAtual == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (index == 0) _inicializarMapa();
          setState(() => _indiceAbaAtual = index);
        },
        hoverColor: AppColors.primaryTeal.withValues(alpha: 0.05),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryTeal.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(isSelected ? iconSelected : iconUnselected, 
                  size: 24, 
                  color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _onNovaOcorrenciaPressed(UsuarioProvider usuarioProvider, {LatLng? latlng}) async {
    if (kIsWeb) {
      if (!usuarioProvider.isAdmin) {
        // Exibe modal de download do aplicativo para cidadãos na web
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.app_shortcut_rounded, size: 64, color: AppColors.primaryTeal),
                  const SizedBox(height: 16),
                  const Text('Aplicativo Necessário', 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  const Text('Para registrar ocorrências em tempo real com precisão de GPS e envio de mídia, utilize nosso aplicativo para Android ou iOS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=defesa.civil.foco&hl=pt_BR'));
                      },
                      icon: const Icon(Icons.android, color: Colors.white),
                      label: const Text('Baixar no Google Play'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3DDC84),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        launchUrl(Uri.parse('https://apps.apple.com/br/app/defesa-em-foco/id6782083182'));
                      },
                      icon: const Icon(Icons.apple, color: Colors.white),
                      label: const Text('Baixar na App Store'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Entendi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      // Web + Administrador: Abre Dialog de cadastro com as coordenadas do ponto clicado no mapa
      final res = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 850),
            decoration: BoxDecoration(color: AppColors.backgroundOffWhite, borderRadius: BorderRadius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => SelecaoTipoOcorrenciaScreen(posicaoInicial: latlng),
              ),
            ),
          ),
        ),
      );
      if (res == true && mounted) _inicializarMapa();
      return;
    } else {
      // Mobile (Android / iOS)
      final res = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => SelecaoTipoOcorrenciaScreen(posicaoInicial: latlng),
        ),
      );
      if (res == true && mounted) _inicializarMapa();
    }
  }


  Widget _construirTelaMapa(String nomeUsuario, List<Marker> markers, UsuarioProvider userProv) {
    final searchResults = _getFilteredOcorrencias();
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              ClimaService.obterCoordenadasCidade(userProv.cidadeAtiva)['lat']!,
              ClimaService.obterCoordenadasCidade(userProv.cidadeAtiva)['lng']!,
            ),
            initialZoom: 14,
            minZoom: 5,
            maxZoom: 18,
            onTap: (_, __) => setState(() => _showSearchResults = false),
            onSecondaryTap: (_, latlng) async {
              final isGestor = userProv.isAdmin || userProv.isAgente;
              final acao = await MapaContextMenuWidget.exibir(context, latlng, isGestor: isGestor);
              if (acao != null && mounted) {
                _executarAcaoContextMenu(acao, latlng, userProv);
              }
            },
            onLongPress: (_, latlng) async {
              final isGestor = userProv.isAdmin || userProv.isAgente;
              final acao = await MapaContextMenuWidget.exibir(context, latlng, isGestor: isGestor);
              if (acao != null && mounted) {
                _executarAcaoContextMenu(acao, latlng, userProv);
              }
            },
            cameraConstraint: CameraConstraint.containCenter(
              bounds: LatLngBounds(
                const LatLng(-33.0, -73.0),
                const LatLng(5.0, -34.0),
              ),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.defesacivil.app',
            ),
            MarkerLayer(markers: [
              ...markers,
              if (_marcadorEnderecoSelecionado != null)
                Marker(
                  point: _marcadorEnderecoSelecionado!,
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_nomeEnderecoSelecionado ?? 'Local pesquisado'),
                          action: SnackBarAction(
                            label: 'REMOVER',
                            onPressed: () => setState(() {
                              _marcadorEnderecoSelecionado = null;
                              _nomeEnderecoSelecionado = null;
                            }),
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 40),
                  ),
                ),
            ]),
            if (_posicaoAtual != null) MarkerLayer(markers: [Marker(point: LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude), child: const Icon(Icons.my_location, color: Colors.blue, size: 20))]),
          ],
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: ResponsiveContainer(
            maxWidth: 800,
            centerContent: false, 
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Olá, $nomeUsuario!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _inicializarMapa),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SearchBarWidget(
                          controller: _searchController,
                          hintText: 'Buscar ocorrência ou endereço...',
                          onChanged: _aoAlterarBusca,
                          onClear: () => setState(() {
                            _searchQuery = '';
                            _enderecoSugestoes = [];
                            _showSearchResults = false;
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const AlertaBannerWidget(),
              ],
            ),
          ),
        ),
        if (_showSearchResults) _buildSearchResultsOverlay(searchResults),
      ],
    );
  }

  Widget _buildSearchResultsOverlay(List<Ocorrencia> searchResults) {
    final temOcorrencias = searchResults.isNotEmpty;
    final temEnderecos = _enderecoSugestoes.isNotEmpty;
    final nenhumResultado = !temOcorrencias && !temEnderecos && !_buscandoEnderecos;

    return Positioned(
      top: 175,
      left: 16,
      right: 16,
      bottom: 90,
      child: ResponsiveContainer(
        maxWidth: 600,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              children: [
                if (_buscandoEnderecos)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
                          ),
                          SizedBox(width: 8),
                          Text('Buscando endereços...', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                  ),
                if (temEnderecos) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primaryTeal),
                        const SizedBox(width: 6),
                        Text(
                          'ENDEREÇOS E LOCAIS (${_enderecoSugestoes.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._enderecoSugestoes.map((end) => ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.place_rounded, color: AppColors.primaryTeal, size: 18),
                    ),
                    title: Text(
                      end.displayNome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      setState(() {
                        _showSearchResults = false;
                        _searchController.text = end.displayNome.split(',').first;
                        _searchQuery = '';
                        _marcadorEnderecoSelecionado = LatLng(end.lat, end.lng);
                        _nomeEnderecoSelecionado = end.displayNome;
                      });
                      _mapController.move(LatLng(end.lat, end.lng), 16);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('📍 Localizado: ${end.displayNome.split(',').take(2).join(',')}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  )),
                  if (temOcorrencias) const Divider(height: 20),
                ],
                if (temOcorrencias) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.deepOrange),
                        const SizedBox(width: 6),
                        Text(
                          'OCORRÊNCIAS (${searchResults.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...searchResults.map((oc) => OcorrenciaCard(
                    ocorrencia: oc,
                    onTap: () {
                      setState(() {
                        _showSearchResults = false;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                      _mapController.move(LatLng(oc.latitude, oc.longitude), 16);
                      _mostrarDetalhesOcorrencia(oc);
                    },
                  )),
                ],
                if (nenhumResultado)
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Nenhum resultado para "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // _buildOcorrenciaImage removido pois agora usamos o widget OcorrenciaImage

  // _buildOcorrenciaImage removido pois agora usamos o widget OcorrenciaImage

  void _onNovoPontoInteressePressed() async {
    LatLng? coordenadas;
    if (_posicaoAtual != null) {
      coordenadas = LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude);
    } else {
      final pos = await _localizacaoService.obterPosicaoAtual();
      if (pos != null) {
        if (mounted) setState(() => _posicaoAtual = pos);
        coordenadas = LatLng(pos.latitude, pos.longitude);
      } else {
        coordenadas = _mapController.camera.center;
      }
    }
    if (mounted) {
      _confirmarNovoPontoInteresse(coordenadas);
    }
  }

  void _confirmarNovoPontoInteresse(LatLng latlng) async {
    final res = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => RegistroPontoInteresseScreen(posicao: latlng)));
    if (res == true && mounted) {
      _inicializarMapa();
    }
  }

  void _mostrarDetalhesPOI(PontoInteresse p) {
    _showResponsiveModal(
      context,
      (context) => Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
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
      ),
    );
  }
}