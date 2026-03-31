import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/ocorrencia_tipos.dart';
import '../models/ocorrencia.dart';
import '../models/comentario.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/ocorrencia_card.dart';
import '../widgets/ocorrencia_image.dart';
import '../widgets/status_badge.dart';

class HistoricoScreen extends StatefulWidget {
   const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  String _filtroSelecionado = 'todas';
  String? _filtroAgenteNome;
  final TextEditingController _comentarioController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _selectionMode = false;
  final Set<String> _selecionadas = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selecionadas.length} selecionada(s)')
            : const Text('Histórico'),
        elevation: 0,
        actions: [
          if (context.watch<UsuarioProvider>().isAdmin)
            IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _selectionMode ? Icons.close_rounded : Icons.checklist_rounded,
                  size: 20,
                ),
              ),
              tooltip:
                  _selectionMode ? 'Cancelar seleção' : 'Selecionar múltiplas',
              onPressed: () {
                setState(() {
                  _selectionMode = !_selectionMode;
                  if (!_selectionMode) _selecionadas.clear();
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBarWidget(
              controller: _searchController,
              hintText: 'Pesquisar no histórico...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _construirBotaoFiltro('todas', 'Todas', Icons.list_rounded),
                      const SizedBox(width: 8),
                      _construirBotaoFiltro(
                          'ativas', 'Ativas', Icons.error_rounded),
                      const SizedBox(width: 8),
                      _construirBotaoFiltro(
                          'em_andamento', 'A Caminho', Icons.directions_run_rounded),
                      const SizedBox(width: 8),
                      _construirBotaoFiltro(
                          'resolvidas', 'Resolvidas', Icons.check_circle_rounded),
                      const SizedBox(width: 8),
                      if (context.watch<UsuarioProvider>().estaLogado)
                        _construirBotaoFiltro(
                            'minhas', 'Minhas', Icons.person_rounded),
                    ],
                  ),
                ),
                if (context.watch<UsuarioProvider>().isAdmin) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Por Agente: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        ...context.watch<UsuarioProvider>().todosAgentes.map((agente) {
                          final selected = _filtroAgenteNome == agente.nome;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text(agente.nome, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary)),
                              selected: selected,
                              onSelected: (val) {
                                setState(() {
                                  _filtroAgenteNome = val ? agente.nome : null;
                                });
                              },
                              selectedColor: AppColors.primaryTeal,
                              backgroundColor: AppColors.surfaceCard,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista
          Expanded(
            child: Consumer<OcorrenciaProvider>(
              builder: (context, provider, _) {
                List<Ocorrencia> ocorrencias = _obterOcorrenciasFiltradas(
                  provider,
                  context.read<UsuarioProvider>(),
                );

                // Filtrar por busca
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  ocorrencias = ocorrencias.where((o) {
                    return OcorrenciaTipos.getTipoNome(o.tipo)
                            .toLowerCase()
                            .contains(query) ||
                        o.descricao.toLowerCase().contains(query);
                  }).toList();
                }

                if (ocorrencias.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.inbox_rounded,
                            size: 40,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma ocorrência encontrada',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tente alterar os filtros de busca',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Agrupar por dia
                final Map<String, List<Ocorrencia>> agrupado = {};
                for (var o in ocorrencias) {
                  final key =
                      '${o.dataHora.day.toString().padLeft(2, '0')}/${o.dataHora.month.toString().padLeft(2, '0')}/${o.dataHora.year}';
                  agrupado.putIfAbsent(key, () => []).add(o);
                }

                return RefreshIndicator(
                  onRefresh: () => provider.carregarOcorrencias(
                    cidade: context.read<UsuarioProvider>().usuarioLogado?.cidade,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: agrupado.entries.expand((entry) {
                      return [
                        // Data header
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 14, color: AppColors.primaryTeal),
                                    const SizedBox(width: 6),
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.borderLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Cards
                        ...entry.value
                            .map((ocorrencia) => OcorrenciaCard(
                                  ocorrencia: ocorrencia,
                                  selectable: _selectionMode,
                                  selected:
                                      _selecionadas.contains(ocorrencia.id),
                                  onSelectToggle: () {
                                    setState(() {
                                      if (_selecionadas.contains(ocorrencia.id)) {
                                        _selecionadas.remove(ocorrencia.id);
                                      } else {
                                        _selecionadas.add(ocorrencia.id);
                                      }
                                    });
                                  },
                                  onTap: () => _mostrarDetalhesOcorrencia(
                                      context, ocorrencia),
                                ))
                            ,
                      ];
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _selectionMode && _selecionadas.isNotEmpty
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset:  const Offset(0, -4),
                      ),
                    ],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _apagarSelecionadas,
                            icon: const Icon(Icons.delete_rounded, size: 18),
                            label: const Text('Excluir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusActive,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _marcarSelecionadasResolvidas(true),
                            icon: const Icon(Icons.check_circle_rounded,
                                size: 18),
                            label: const Text('Resolver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusResolved,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _marcarSelecionadasResolvidas(false),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reativar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusEnRoute,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
    );
  }

  Widget _construirBotaoFiltro(String valor, String label, IconData icon) {
    final selected = _filtroSelecionado == valor;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroSelecionado = valor;
        });
      },
      child: AnimatedContainer(
        duration:  const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTeal : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryTeal : AppColors.borderLight,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset:  const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Ocorrencia> _obterOcorrenciasFiltradas(
    OcorrenciaProvider provider,
    UsuarioProvider usuarioProvider,
  ) {
    List<Ocorrencia> ocorrencias = [];

    switch (_filtroSelecionado) {
      case 'ativas':
        ocorrencias = provider.ocorrenciasAtivas;
        break;
      case 'em_andamento':
        ocorrencias = provider.ocorrencias.where((o) => o.status != OcorrenciaStatus.resolvida && o.agentes != null && o.agentes!.isNotEmpty).toList();
        break;
      case 'resolvidas':
        ocorrencias = provider.ocorrenciasResolvidas;
        break;
      case 'minhas':
        if (usuarioProvider.estaLogado) {
          ocorrencias = provider.obterOcorrenciasDoUsuario(
            usuarioProvider.usuarioLogado!.id,
          );
        }
        break;
      default:
        ocorrencias = provider.ocorrencias;
    }

    // Filtragem por cidade para Admin e Agentes (Segurança e Foco)
    if (usuarioProvider.estaLogado && usuarioProvider.usuarioLogado!.isAgente) {
      final cidadeAdmin = usuarioProvider.usuarioLogado?.cidade;
      if (cidadeAdmin != null && cidadeAdmin.isNotEmpty) {
        ocorrencias = ocorrencias.where((o) => o.cidade == cidadeAdmin).toList();
      }
    }

    if (_filtroAgenteNome != null) {
      ocorrencias = ocorrencias.where((o) => o.agentes?.contains(_filtroAgenteNome!) == true).toList();
    }

    ocorrencias.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return ocorrencias;
  }

  void _mostrarDetalhesOcorrencia(
      BuildContext context, Ocorrencia pOcorrencia) {
    Ocorrencia ocorrencia = pOcorrencia;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
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
                    width: 56,
                    height: 56,
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
                        const SizedBox(height: 6),
                        Text(
                          OcorrenciaTipos.getTipoDescricao(ocorrencia.tipo),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descrição
                    _buildSection('Descrição', Icons.description_rounded,
                        child: Text(
                          ocorrencia.descricao,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        )),

                    // Foto
                    if (ocorrencia.caminhoFoto != null &&
                        ocorrencia.caminhoFoto!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: OcorrenciaImage(
                            caminho: ocorrencia.caminhoFoto!,
                            height: 220,
                          ),
                        ),
                      ),

                    // Info
                    _buildSection('Informações', Icons.info_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('Data', _formatarData(ocorrencia.dataHora)),
                            const SizedBox(height: 6),
                            _infoRow('Lat/Lng',
                                '${ocorrencia.latitude.toStringAsFixed(6)}, ${ocorrencia.longitude.toStringAsFixed(6)}'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text('Status: ',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary)),
                                StatusBadge(
                                  status: ocorrencia.status,
                                  agentes: ocorrencia.agentes,
                                ),
                              ],
                            ),
                            if (ocorrencia.dataResolucao != null) ...[
                              const SizedBox(height: 6),
                              _infoRow('Resolvida em',
                                  _formatarData(ocorrencia.dataResolucao!)),
                            ],
                          ],
                        )),

                    // Comentários
                    _buildSection('Comentários', Icons.chat_bubble_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ocorrencia.comentarios.isEmpty)
                              const Text('Nenhum comentário.',
                                  style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic))
                            else
                              ...ocorrencia.comentarios.map((c) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundOffWhite,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(c.usuarioNome,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13)),
                                             const Spacer(),
                                            Text(
                                                _formatarData(c.dataHora),
                                                style: const TextStyle(
                                                    color: AppColors.textLight,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(c.texto,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppColors.textSecondary)),
                                      ],
                                    ),
                                  )),
                            if (context.watch<UsuarioProvider>().isAdmin) ...[
                              const SizedBox(height: 10),
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
                                        _adicionarComentario(context, ocorrencia),
                                  ),
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ],
                        )),

                    // Admin: Agentes
                    if (context.watch<UsuarioProvider>().isAdmin)
                      _buildSection('Agentes', Icons.groups_rounded,
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
                                        ocorrencia = ocorrencia.copyWith(agentes: novoTexto, status: OcorrenciaStatus.aprovada);
                                        context.read<OcorrenciaProvider>().atualizarOcorrencia(ocorrencia);
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(selected ? 'Agente ${agente.nome} alocado! Status: A Caminho.' : 'Agente removido.'),
                                            backgroundColor: AppColors.statusResolved,
                                            duration:  const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      selectedColor: AppColors.primaryTeal.withValues(alpha: 0.2),
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
                        ocorrencia.status == OcorrenciaStatus.pendenteAprovacao)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await context.read<OcorrenciaProvider>().aprovarOcorrencia(ocorrencia.id);
                                  if (context.mounted) Navigator.pop(context);
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

                    // 2. Registro de Chegada (Somente Agente e se Aprovada, NÃO MOSTRAR PARA ADMIN)
                    if (context.watch<UsuarioProvider>().usuarioLogado?.isAgente == true && 
                        !context.watch<UsuarioProvider>().isAdmin &&
                        ocorrencia.status == OcorrenciaStatus.aprovada &&
                        !ocorrencia.agenteNoLocal)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await context.read<OcorrenciaProvider>().registrarChegadaAgente(ocorrencia.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.location_on_rounded),
                            label: const Text('ESTOU NO LOCAL'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                          ),
                        ),
                      ),

                    // Botões admin antigos
                    if (context.watch<UsuarioProvider>().isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _alterarStatusOcorrencia(
                                    context, ocorrencia),
                                icon: Icon(
                                    ocorrencia.status == OcorrenciaStatus.resolvida
                                        ? Icons.refresh_rounded
                                        : Icons.check_circle_rounded,
                                    size: 18),
                                label: Text(ocorrencia.status == OcorrenciaStatus.resolvida
                                    ? 'Reativar'
                                    : 'Resolver'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ocorrencia.status == OcorrenciaStatus.resolvida
                                      ? AppColors.statusEnRoute
                                      : AppColors.statusResolved,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _deletarOcorrencia(context, ocorrencia),
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

  Widget _buildSection(String title, IconData icon, {required Widget child}) {
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
          Row(children: [
            Icon(icon, size: 18, color: AppColors.primaryTeal),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary))),
      ],
    );
  }

  void _adicionarComentario(BuildContext context, Ocorrencia ocorrencia) {
    final usuarioProvider = context.read<UsuarioProvider>();
    if (!usuarioProvider.isAdmin) return;
    if (_comentarioController.text.trim().isEmpty) return;

    final comentario = Comentario(
      texto: _comentarioController.text.trim(),
      usuarioNome: 'Administrador',
      usuarioId: usuarioProvider.usuarioLogado?.id,
    );

    context
        .read<OcorrenciaProvider>()
        .adicionarComentario(ocorrencia.id, comentario);
    _comentarioController.clear();
  }

  void _alterarStatusOcorrencia(BuildContext context, Ocorrencia ocorrencia) {
    () async {
      if (ocorrencia.status == OcorrenciaStatus.resolvida) {
        await context.read<OcorrenciaProvider>().reativarOcorrencia(ocorrencia.id);
      } else {
        await context.read<OcorrenciaProvider>().resolverOcorrencia(ocorrencia.id);
      }
      if (context.mounted) Navigator.pop(context);
    }();
  }

  void _deletarOcorrencia(BuildContext context, Ocorrencia ocorrencia) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja deletar esta ocorrência?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<OcorrenciaProvider>()
                  .deletarOcorrencia(ocorrencia.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
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

  Future<void> _apagarSelecionadas() async {
    final provider = context.read<OcorrenciaProvider>();
    for (var id in _selecionadas.toList()) {
      await provider.deletarOcorrencia(id);
    }
    setState(() {
      _selecionadas.clear();
      _selectionMode = false;
    });
  }

  Future<void> _marcarSelecionadasResolvidas(bool resolvidas) async {
    final provider = context.read<OcorrenciaProvider>();
    for (var id in _selecionadas.toList()) {
      if (resolvidas) {
        await provider.resolverOcorrencia(id);
      } else {
        await provider.reativarOcorrencia(id);
      }
    }
    setState(() {
      _selecionadas.clear();
      _selectionMode = false;
    });
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour}:${data.minute.toString().padLeft(2, '0')}';
  }
}
