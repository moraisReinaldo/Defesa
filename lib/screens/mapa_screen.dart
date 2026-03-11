import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../constants/ocorrencia_tipos.dart';
import '../models/ocorrencia.dart';
import '../models/comentario.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../services/localizacao_service.dart';
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
  Position? _posicaoAtual;
  final List<Marker> _markers = [];
  int _indiceAbaAtual = 0;
  final TextEditingController comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicializarMapa();
    // ouvir mudanças para atualizar marcadores automaticamente
    context.read<OcorrenciaProvider>().addListener(_atualizarMarcadores);
  }

  Future<void> _inicializarMapa() async {
    // Carregar ocorrências
    await context.read<OcorrenciaProvider>().carregarOcorrencias();
    
    // Obter localização atual
    _posicaoAtual = await _localizacaoService.obterPosicaoAtual();
    
    if (_posicaoAtual != null && mounted) {
      _atualizarMarcadores();
      _mapController.move(
        LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude),
        14,
      );
    }
  }

  void _atualizarMarcadores() {
    final ocorrencias = context.read<OcorrenciaProvider>().ocorrenciasAtivas;
    
    _markers.clear();
    
    for (final ocorrencia in ocorrencias) {
      Color cor;
      if (ocorrencia.resolvida) {
        cor = Colors.green;
      } else if (ocorrencia.agentes != null && ocorrencia.agentes!.isNotEmpty) {
        // em caminho
        cor = Colors.orange;
      } else {
        cor = Colors.red;
      }

      _markers.add(
        Marker(
          point: LatLng(ocorrencia.latitude, ocorrencia.longitude),
          builder: (context) => GestureDetector(
            onTap: () => _mostrarDetalhesOcorrencia(ocorrencia),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emergency,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      );
    }

    setState(() {});
  }

  void _mostrarDetalhesOcorrencia(Ocorrencia ocorrencia) {
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
                'Data: ${_formatarData(ocorrencia.dataHora)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Coordenadas: ${ocorrencia.latitude.toStringAsFixed(4)}, ${ocorrencia.longitude.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (context.watch<UsuarioProvider>().isAdmin && !ocorrencia.resolvida)
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _editarCoordenadas(ocorrencia),
                      icon: const Icon(Icons.edit_location, size: 18),
                      label: const Text('Alterar coordenadas'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _editarFoto(ocorrencia),
                      icon: const Icon(Icons.photo_camera, size: 18),
                      label: const Text('Trocar foto'),
                    ),
                  ],
                ),
              Text(
                'Status: ${ocorrencia.resolvida ? 'Resolvida' : 'Ativa'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ocorrencia.resolvida ? Colors.green : Colors.red,
                    ),
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
                          if (comentario.agentes != null && comentario.agentes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Agentes: ${comentario.agentes}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              // Campo para adicionar comentário - somente admins
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
                      onPressed: () => _adicionarComentario(ocorrencia),
                    ),
                  ),
                  maxLines: 3,
                  onFieldSubmitted: (_) => _adicionarComentario(ocorrencia),
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
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            final texto = agentesController.text.trim();
                            if (texto.isEmpty) return;
                            final atualizada = ocorrencia.copyWith(agentes: texto);
                            context
                                .read<OcorrenciaProvider>()
                                .atualizarOcorrencia(atualizada);

                            // criar comentário de envio de agentes
                            final comentario = Comentario(
                              texto: 'Agentes a caminho',
                              agentes: texto,
                              usuarioNome: 'Administrador',
                            );
                            context
                                .read<OcorrenciaProvider>()
                                .adicionarComentario(ocorrencia.id, comentario);

                            _atualizarMarcadores();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final texto = agentesController.text.trim();
                          if (texto.isEmpty) return;
                          final atualizada = ocorrencia.copyWith(agentes: texto);
                          context
                              .read<OcorrenciaProvider>()
                              .atualizarOcorrencia(atualizada);

                          // criar comentário de envio de agentes
                          final comentario = Comentario(
                            texto: 'Agentes a caminho',
                            agentes: texto,
                            usuarioNome: 'Administrador',
                          );
                          context
                              .read<OcorrenciaProvider>()
                              .adicionarComentario(ocorrencia.id, comentario);

                          agentesController.clear();
                          agentesController.clear();
                          _atualizarMarcadores();
                        },
                        child: const Text('Enviar agentes'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              // Botões
              if (context.watch<UsuarioProvider>().isAdmin)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _alterarStatusOcorrencia(ocorrencia),
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
                        onPressed: () => _deletarOcorrencia(ocorrencia),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Deletar'),
                      ),
                    ),
                  ],
                )
              else if (!ocorrencia.resolvida)
                ElevatedButton(
                  onPressed: () => _alterarStatusOcorrencia(ocorrencia),
                  child: const Text('Marcar como Resolvida'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _adicionarComentario(Ocorrencia ocorrencia) {
    final usuarioProvider = context.read<UsuarioProvider>();
    if (!usuarioProvider.isAdmin) return; // somente admins podem comentar

    if (comentarioController.text.trim().isEmpty) return;

    final comentario = Comentario(
      texto: comentarioController.text.trim(),
      usuarioNome: 'Administrador',
      usuarioId: usuarioProvider.usuarioLogado?.id,
    );

    context.read<OcorrenciaProvider>().adicionarComentario(ocorrencia.id, comentario);
    comentarioController.clear();
    Navigator.pop(context); // Fechar o bottom sheet
    _atualizarMarcadores(); // Atualizar marcadores se necessário
  }

  void _alterarStatusOcorrencia(Ocorrencia ocorrencia) {
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
    _atualizarMarcadores();
  }

  void _deletarOcorrencia(Ocorrencia ocorrencia) {
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
              _atualizarMarcadores();
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _editarFoto(Ocorrencia ocorrencia) async {
    // menu para camera/galeria
    final escolha = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
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
        await context.read<OcorrenciaProvider>().atualizarOcorrencia(atualizada);
        _atualizarMarcadores();
        // fechar sheet e reabrir para atualizar
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
    final latController = TextEditingController(text: ocorrencia.latitude.toString());
    final lngController = TextEditingController(text: ocorrencia.longitude.toString());
    // salvar contexto do estado pai para fechar o bottom sheet
    final sheetCtx = context;

    await showDialog(
      context: context,
      builder: (dlgCtx) {
        return AlertDialog(
          title: const Text('Editar Coordenadas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              TextField(
                controller: lngController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final lat = double.tryParse(latController.text);
                final lng = double.tryParse(lngController.text);
                if (lat != null && lng != null) {
                  final atualizada = ocorrencia.copyWith(latitude: lat, longitude: lng);
                  context.read<OcorrenciaProvider>().atualizarOcorrencia(atualizada);
                  _atualizarMarcadores();
                  Navigator.pop(dlgCtx); // fecha dialog
                  Navigator.pop(sheetCtx); // fecha sheet
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
    return '${data.day}/${data.month}/${data.year} às ${data.hour}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Defesa Civil Municipal'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _inicializarMapa();
            },
          ),
        ],
      ),
      body: _indiceAbaAtual == 0
          ? _construirTelaMapa()
          : _indiceAbaAtual == 1
              ? const HistoricoScreen()
              : const PerfilScreen(),
      floatingActionButton: _indiceAbaAtual == 0
          ? FloatingActionButton(
              onPressed: () async {
                final resultado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistroOcorrenciaScreen(),
                  ),
                );
                if (resultado == true) {
                  _inicializarMapa();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAbaAtual,
        onTap: (indice) {
          setState(() {
            _indiceAbaAtual = indice;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _construirTelaMapa() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _posicaoAtual != null
                ? LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude)
                : const LatLng(-22.9292618, -46.2753862), // Joanópolis, SP como padrão
            zoom: 14,
            minZoom: 5,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.defensacivil.app',
              retinaMode: true,
            ),
            MarkerLayer(
              markers: _markers,
            ),
            if (_posicaoAtual != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude),
                    builder: (context) => Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<OcorrenciaProvider>(
              builder: (context, provider, _) {
                return Text(
                  'Ocorrências Ativas: ${provider.ocorrenciasAtivas.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}