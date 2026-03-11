import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/ocorrencia_tipos.dart';
import '../models/ocorrencia.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../services/localizacao_service.dart';

class RegistroOcorrenciaScreen extends StatefulWidget {
  const RegistroOcorrenciaScreen({super.key});

  @override
  State<RegistroOcorrenciaScreen> createState() =>
      _RegistroOcorrenciaScreenState();
}

class _RegistroOcorrenciaScreenState extends State<RegistroOcorrenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final LocalizacaoService _localizacaoService = LocalizacaoService();

  String? _tipoSelecionado;
  File? _fotoSelecionada;
  Position? _posicaoAtual;

  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
  }

  Future<void> _obterLocalizacao() async {
    try {
      final posicao = await _localizacaoService.obterPosicaoAtual();

      if (posicao != null && mounted) {
        setState(() {
          _posicaoAtual = posicao;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao obter localização: $e")),
        );
      }
    }
  }

  Future<void> _selecionarFoto() async {
    // permite escolher entre câmera ou galeria
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
      final foto = await _imagePicker.pickImage(
        source: escolha,
        imageQuality: 80,
        maxWidth: 1280,
      );

      if (foto != null) {
        setState(() {
          _fotoSelecionada = File(foto.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao obter foto: $e")),
      );
    }
  }

  Future<void> _enviarOcorrencia() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione o tipo de ocorrência")),
      );
      return;
    }

    if (_posicaoAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Localização não encontrada")),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final usuarioLogado = context.read<UsuarioProvider>().usuarioLogado;

      final ocorrencia = Ocorrencia(
        tipo: _tipoSelecionado!,
        descricao: _descricaoController.text,
        latitude: _posicaoAtual!.latitude,
        longitude: _posicaoAtual!.longitude,
        caminhoFoto: _fotoSelecionada?.path,
        usuarioId: usuarioLogado?.id,
      );

      await context.read<OcorrenciaProvider>().adicionarOcorrencia(ocorrencia);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ocorrência registrada com sucesso"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao registrar ocorrência: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Widget _buildFoto() {
    if (_fotoSelecionada != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _fotoSelecionada!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.red,
              onPressed: () {
                setState(() {
                  _fotoSelecionada = null;
                });
              },
              child: const Icon(Icons.close),
            ),
          )
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text("Nenhuma foto selecionada")
          ],
        ),
      ),
    );
  }

  Widget _buildLocalizacao() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_posicaoAtual != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "Latitude: ${_posicaoAtual!.latitude.toStringAsFixed(6)}"),
                Text(
                    "Longitude: ${_posicaoAtual!.longitude.toStringAsFixed(6)}"),
                Text(
                    "Precisão: ${_posicaoAtual!.accuracy.toStringAsFixed(2)} m"),
              ],
            )
          else
            const Text("Obtendo localização..."),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _obterLocalizacao,
            icon: const Icon(Icons.location_on),
            label: const Text("Atualizar localização"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipos = OcorrenciaTipos.getTiposLista();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Ocorrência"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Tipo de Ocorrência",
                  style: Theme.of(context).textTheme.titleMedium),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _tipoSelecionado,
                items: tipos.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(OcorrenciaTipos.getTipoIcone(tipo), size: 20),
                        const SizedBox(width: 8),
                        Flexible(child: Text(OcorrenciaTipos.getTipoNome(tipo))),
                      ],
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (context) {
                  // mostra ícone e texto também no valor selecionado
                  return tipos.map((tipo) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(OcorrenciaTipos.getTipoIcone(tipo), size: 20),
                        const SizedBox(width: 8),
                        Flexible(child: Text(OcorrenciaTipos.getTipoNome(tipo))),
                      ],
                    );
                  }).toList();
                },
                onChanged: (valor) {
                  setState(() {
                    _tipoSelecionado = valor;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Selecione o tipo",
                ),
                validator: (valor) =>
                    valor == null ? "Selecione um tipo" : null,
              ),

              const SizedBox(height: 16),

              Text("Descrição",
                  style: Theme.of(context).textTheme.titleMedium),

              const SizedBox(height: 8),

              TextFormField(
                controller: _descricaoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Descreva a ocorrência",
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return "Digite uma descrição";
                  }
                  if (valor.length < 10) {
                    return "Mínimo 10 caracteres";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Text("Foto", style: Theme.of(context).textTheme.titleMedium),

              const SizedBox(height: 8),

              _buildFoto(),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _selecionarFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Adicionar Foto"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

              const SizedBox(height: 16),

              Text("Localização",
                  style: Theme.of(context).textTheme.titleMedium),

              const SizedBox(height: 8),

              _buildLocalizacao(),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _enviarOcorrencia,
                  child: _carregando
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        )
                      : const Text("Registrar Ocorrência"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }
}