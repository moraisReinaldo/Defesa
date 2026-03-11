import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../constants/ocorrencia_tipos.dart';
import '../models/ocorrencia.dart';
import '../models/comentario.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  String _filtroSelecionado = 'todas'; // todas, ativas, resolvidas, minhas
  final TextEditingController comentarioController = TextEditingController();

  bool _selectionMode = false; // quando administrador ativar seleção em massa
  final Set<String> _selecionadas = {}; // ids selecionados

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selecionadas.length} selecionada(s)')
            : const Text('Histórico de Ocorrências'),
        elevation: 0,
        actions: [
          if (context.watch<UsuarioProvider>().isAdmin)
            IconButton(
              icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
              tooltip: _selectionMode ? 'Cancelar seleção' : 'Selecionar múltiplas',
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
          // Filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _construirBotaoFiltro('todas', 'Todas'),
                  const SizedBox(width: 8),
                  _construirBotaoFiltro('ativas', 'Ativas'),
                  const SizedBox(width: 8),
                  _construirBotaoFiltro('resolvidas', 'Resolvidas'),
                  const SizedBox(width: 8),
                  if (context.watch<UsuarioProvider>().estaLogado)
                    _construirBotaoFiltro('minhas', 'Minhas'),
                ],
              ),
            ),
          ),
          // Lista de Ocorrências
          Expanded(
            child: Stack(
              children: [
                Consumer<OcorrenciaProvider>(
              builder: (context, provider, _) {
                List<Ocorrencia> ocorrencias = _obterOcorrenciasFiltradas(
                  provider,
                  context.read<UsuarioProvider>(),
                );

                if (ocorrencias.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma ocorrência encontrada',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                // agrupar por dia
                final Map<String, List<Ocorrencia>> agrupado = {};
                for (var o in ocorrencias) {
                  final key = '${o.dataHora.day.toString().padLeft(2, '0')}/${o.dataHora.month.toString().padLeft(2, '0')}/${o.dataHora.year}';
                  agrupado.putIfAbsent(key, () => []).add(o);
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: agrupado.entries.expand((entry) {
                    return [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(entry.key,
                            style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      ...entry.value.map((ocorrencia) => _construirCartaoOcorrencia(context, ocorrencia)).toList(),
                    ];
                  }).toList(),
                );
              },
            ),
                // placeholder for overlay if needed
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectionMode && _selecionadas.isNotEmpty
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _apagarSelecionadas,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Excluir'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _marcarSelecionadasResolvidas(true),
                      child: const Text('Marcar resolvidas'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _marcarSelecionadasResolvidas(false),
                      child: const Text('Marcar ativas'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _construirBotaoFiltro(String valor, String label) {
    return FilterChip(
      label: Text(label),
      selected: _filtroSelecionado == valor,
      onSelected: (selecionado) {
        setState(() {
          _filtroSelecionado = valor;
        });
      },
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

    // Ordenar por data decrescente
    ocorrencias.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return ocorrencias;
  }

  Widget _construirCartaoOcorrencia(
    BuildContext context,
    Ocorrencia ocorrencia,
  ) {
    final selecionado = _selecionadas.contains(ocorrencia.id);
    return Card(
      color: selecionado ? Colors.blue.withOpacity(0.2) : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _selectionMode
            ? Checkbox(
                value: selecionado,
                onChanged: (_) {
                  setState(() {
                    if (selecionado)
                      _selecionadas.remove(ocorrencia.id);
                    else
                      _selecionadas.add(ocorrencia.id);
                  });
                },
              )
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ocorrencia.resolvida ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    OcorrenciaTipos.getTipoIcone(ocorrencia.tipo),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
        title: Text(
          OcorrenciaTipos.getTipoNome(ocorrencia.tipo),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              ocorrencia.descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              _formatarData(ocorrencia.dataHora),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ocorrencia.resolvida
                ? Colors.green
                : (ocorrencia.agentes != null && ocorrencia.agentes!.isNotEmpty)
                    ? Colors.orange
                    : Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            ocorrencia.resolvida
                ? 'Resolvida'
                : (ocorrencia.agentes != null && ocorrencia.agentes!.isNotEmpty)
                    ? 'Em caminho'
                    : 'Ativa',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: _selectionMode
            ? () {
                setState(() {
                  if (selecionado)
                    _selecionadas.remove(ocorrencia.id);
                  else
                    _selecionadas.add(ocorrencia.id);
                });
              }
            : () => _mostrarDetalhesOcorrencia(context, ocorrencia),
      ),
    );
  }

  void _mostrarDetalhesOcorrencia(BuildContext context, Ocorrencia ocorrencia) {
    final agentesController = TextEditingController(text: ocorrencia.agentes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite altura variável
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Máximo 80% da tela
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                OcorrenciaTipos.getTipoNome(ocorrencia.tipo),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                OcorrenciaTipos.getTipoDescricao(ocorrencia.tipo),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Descrição',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                ocorrencia.descricao,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (ocorrencia.caminhoFoto != null && ocorrencia.caminhoFoto!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(ocorrencia.caminhoFoto!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Informações',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Data: ${_formatarData(ocorrencia.dataHora)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Latitude: ${ocorrencia.latitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Longitude: ${ocorrencia.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Status: ${ocorrencia.resolvida ? 'Resolvida' : 'Ativa'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ocorrencia.resolvida ? Colors.green : Colors.red,
                    ),
              ),
              if (ocorrencia.dataResolucao != null)
                Text(
                  'Resolvida em: ${_formatarData(ocorrencia.dataResolucao!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 16),
              // Seção de comentários
              Text(
                'Comentários',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (ocorrencia.comentarios.isEmpty)
                Text(
                  'Nenhum comentário ainda.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                )
              else
                Column(
                  children: ocorrencia.comentarios.map((comentario) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comentario.usuarioNome,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatarData(comentario.dataHora),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comentario.texto,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              // Campo para adicionar comentário (somente admins)
              if (context.watch<UsuarioProvider>().isAdmin)
                TextFormField(
                  controller: comentarioController,
                  decoration: InputDecoration(
                    hintText: 'Adicionar comentário...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _adicionarComentario(context, ocorrencia),
                    ),
                  ),
                  maxLines: 3,
                  onFieldSubmitted: (_) => _adicionarComentario(context, ocorrencia),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Comentários disponíveis apenas para administradores.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 16),
              if (context.watch<UsuarioProvider>().isAdmin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agentes a caminho',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: agentesController,
                      decoration: InputDecoration(
                        hintText: 'Ex: João Silva, Maria Santos',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        // Atualizar a ocorrência com os agentes
                        final atualizada = ocorrencia.copyWith(agentes: value);
                        context.read<OcorrenciaProvider>().atualizarOcorrencia(atualizada);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              // Botões para admin
              if (context.watch<UsuarioProvider>().isAdmin)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _alterarStatusOcorrencia(context, ocorrencia),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ocorrencia.resolvida ? Colors.orange : Colors.green,
                        ),
                        child: Text(
                          ocorrencia.resolvida ? 'Marcar como Ativa' : 'Marcar como Resolvida',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _deletarOcorrencia(context, ocorrencia),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Deletar'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _adicionarComentario(BuildContext context, Ocorrencia ocorrencia) {
    final usuarioProvider = context.read<UsuarioProvider>();
    if (!usuarioProvider.isAdmin) return;

    if (comentarioController.text.trim().isEmpty) return;

    final comentario = Comentario(
      texto: comentarioController.text.trim(),
      usuarioNome: 'Administrador',
      usuarioId: usuarioProvider.usuarioLogado?.id,
    );

    context.read<OcorrenciaProvider>().adicionarComentario(ocorrencia.id, comentario);
    comentarioController.clear();
  }

  void _alterarStatusOcorrencia(BuildContext context, Ocorrencia ocorrencia) {
    if (ocorrencia.resolvida) {
      // Marcar como ativa
      final atualizada = ocorrencia.copyWith(
        resolvida: false,
        dataResolucao: null,
      );
      context.read<OcorrenciaProvider>().atualizarOcorrencia(atualizada);
    } else {
      // Marcar como resolvida
      context.read<OcorrenciaProvider>().resolverOcorrencia(ocorrencia.id);
    }
    Navigator.pop(context);
  }

  void _deletarOcorrencia(BuildContext context, Ocorrencia ocorrencia) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja deletar esta ocorrência?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<OcorrenciaProvider>().deletarOcorrencia(ocorrencia.id);
              Navigator.pop(context); // Fechar dialog
              Navigator.pop(context); // Fechar bottom sheet
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ações de seleção em massa
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
      final o = provider.obterOcorrenciaPorId(id);
      if (o != null) {
        final atualizada = o.copyWith(
          resolvida: resolvidas,
          dataResolucao: resolvidas ? DateTime.now() : null,
        );
        await provider.atualizarOcorrencia(atualizada);
      }
    }
    setState(() {
      _selecionadas.clear();
      _selectionMode = false;
    });
  }

  String _formatarData(DateTime data) {
    return '${data.day}/${data.month}/${data.year} às ${data.hour}:${data.minute.toString().padLeft(2, '0')}';
  }
}

