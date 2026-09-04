import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ponto_interesse.dart';
import '../providers/ponto_interesse_provider.dart';
import '../providers/usuario_provider.dart';

class GerenciarPOIScreen extends StatefulWidget {
  const GerenciarPOIScreen({super.key});

  @override
  State<GerenciarPOIScreen> createState() => _GerenciarPOIScreenState();
}

class _GerenciarPOIScreenState extends State<GerenciarPOIScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userProv = context.read<UsuarioProvider>();
      final cidade = userProv.usuarioLogado?.cidade ?? userProv.cidadeAtiva;
      context.read<PontoInteresseProvider>().carregarPontos(cidade: cidade);
    });
  }

  @override
  Widget build(BuildContext context) {
    final poiProvider = context.watch<PontoInteresseProvider>();
    final userProvider = context.read<UsuarioProvider>();
    final isAdmin = userProvider.isAdmin;
    final isAgente = userProvider.isAgente;
    final podeEditar = isAdmin || isAgente;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Pontos de Apoio'),
      ),
      body: poiProvider.pontos.isEmpty
          ? const Center(
              child: Text('Nenhum ponto encontrado para sua cidade.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: poiProvider.pontos.length,
              itemBuilder: (context, index) {
                final poi = poiProvider.pontos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: _getPOIPriorityColor(poi.tipo).withValues(alpha: 0.1),
                      child: Icon(_getPOIIcon(poi.tipo), color: _getPOIPriorityColor(poi.tipo)),
                    ),
                    title: Text(
                      _getPOILabel(poi.tipo),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(poi.descricao),
                    trailing: podeEditar
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botão de editar (PUT) — CR2 Seção B
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                tooltip: 'Editar ponto',
                                onPressed: () => _abrirDialogEditar(poi),
                              ),
                              if (isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Remover ponto',
                                  onPressed: () => _confirmarExclusao(poi),
                                ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  /// Dialog de edição para atualizar tipo e descrição de um POI (operação PUT).
  void _abrirDialogEditar(PontoInteresse poi) {
    final tipoController = TextEditingController(text: poi.tipo);
    final descController = TextEditingController(text: poi.descricao);
    String tipoSelecionado = poi.tipo;

    final tipos = [
      'PONTO_COLETA_AGUA',
      'AREA_RISCO',
      'ABRIGO',
      'BASE_DEFESA',
      'DESLIZAMENTO',
      'OUTRO',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Ponto de Apoio'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tipoSelecionado,
                          isExpanded: true,
                          items: tipos.map((t) {
                            return DropdownMenuItem(value: t, child: Text(_getPOILabel(t)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => tipoSelecionado = val);
                              tipoController.text = val;
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Descreva o ponto de apoio...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar'),
                  onPressed: () async {
                    if (descController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('A descrição não pode estar vazia.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    await _salvarEdicao(poi, tipoSelecionado, descController.text.trim());
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _salvarEdicao(PontoInteresse poi, String novoTipo, String novaDescricao) async {
    final poiAtualizado = poi.copyWith(tipo: novoTipo, descricao: novaDescricao);
    try {
      final sucesso = await context.read<PontoInteresseProvider>().atualizarPonto(poiAtualizado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sucesso ? 'Ponto atualizado com sucesso!' : 'Não foi possível atualizar.'),
            backgroundColor: sucesso ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmarExclusao(PontoInteresse poi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Ponto?'),
        content: Text('Deseja realmente remover o ponto "${poi.descricao}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<PontoInteresseProvider>().deletarPonto(poi.id);
              Navigator.pop(context);
            },
            child: const Text('REMOVER'),
          ),
        ],
      ),
    );
  }

  IconData _getPOIIcon(String tipo) {
    switch (tipo) {
      case 'PONTO_COLETA_AGUA': return Icons.water_drop;
      case 'AREA_RISCO': return Icons.warning;
      case 'ABRIGO': return Icons.home;
      case 'BASE_DEFESA': return Icons.security;
      case 'DESLIZAMENTO': return Icons.terrain;
      default: return Icons.location_on;
    }
  }

  Color _getPOIPriorityColor(String tipo) {
    switch (tipo) {
      case 'AREA_RISCO':
      case 'DESLIZAMENTO': return Colors.orange;
      case 'ABRIGO': return Colors.green;
      case 'BASE_DEFESA': return Colors.indigo;
      case 'PONTO_COLETA_AGUA': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getPOILabel(String tipo) {
    switch (tipo) {
      case 'PONTO_COLETA_AGUA': return 'Água';
      case 'AREA_RISCO': return 'Risco';
      case 'ABRIGO': return 'Abrigo';
      case 'BASE_DEFESA': return 'Base Defesa Civil';
      case 'DESLIZAMENTO': return 'Deslizamento';
      default: return 'Ponto';
    }
  }
}
