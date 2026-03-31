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
      final user = context.read<UsuarioProvider>().usuarioLogado;
      context.read<PontoInteresseProvider>().carregarPontos(cidade: user?.cidade);
    });
  }

  @override
  Widget build(BuildContext context) {
    final poiProvider = context.watch<PontoInteresseProvider>();
    final isAdmin = context.read<UsuarioProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Pontos de Apoio'),
      ),
      body: poiProvider.pontos.isEmpty
          ?  const Center(
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
                    trailing: isAdmin
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmarExclusao(poi),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
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
      case 'DESLIZAMENTO': return Icons.terrain;
      default: return Icons.location_on;
    }
  }

  Color _getPOIPriorityColor(String tipo) {
    switch (tipo) {
      case 'AREA_RISCO':
      case 'DESLIZAMENTO': return Colors.orange;
      case 'ABRIGO': return Colors.green;
      case 'PONTO_COLETA_AGUA': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getPOILabel(String tipo) {
    switch (tipo) {
      case 'PONTO_COLETA_AGUA': return 'Água';
      case 'AREA_RISCO': return 'Risco';
      case 'ABRIGO': return 'Abrigo';
      case 'DESLIZAMENTO': return 'Deslizamento';
      default: return 'Ponto';
    }
  }
}
