import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_colors.dart';
import '../constants/ocorrencia_tipos.dart';
import '../models/ocorrencia.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../services/localizacao_service.dart';

class DetalhesOcorrenciaScreen extends StatefulWidget {
  final String tipoOcorrencia;

  const DetalhesOcorrenciaScreen({super.key, required this.tipoOcorrencia});

  @override
  State<DetalhesOcorrenciaScreen> createState() =>
      _DetalhesOcorrenciaScreenState();
}

class _DetalhesOcorrenciaScreenState extends State<DetalhesOcorrenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final LocalizacaoService _localizacaoService = LocalizacaoService();

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
    final usuarioProvider = context.read<UsuarioProvider>();
    final usuarioLogado = usuarioProvider.estaLogado || usuarioProvider.isAdmin;

    if (!usuarioLogado) {
      // Usuário sem cadastro: somente câmera
      try {
        final foto = await _imagePicker.pickImage(
          source: ImageSource.camera,
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
          SnackBar(content: Text("Erro ao tirar foto: $e")),
        );
      }
      return;
    }

    // Usuário logado ou Admin: opção câmera + galeria
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
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Adicionar foto',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.primaryTeal),
                  ),
                  title: const Text('Tirar foto',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Usar a câmera do dispositivo',
                      style: TextStyle(fontSize: 12)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded,
                        color: AppColors.accentAmber),
                  ),
                  title: const Text('Escolher da galeria',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Selecionar uma foto existente',
                      style: TextStyle(fontSize: 12)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 16),
              ],
            ),
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

    if (_posicaoAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Localização não encontrada"),
          backgroundColor: AppColors.statusActive,
        ),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final usuarioLogado = context.read<UsuarioProvider>().usuarioLogado;

      final ocorrencia = Ocorrencia(
        tipo: widget.tipoOcorrencia,
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
            content: Text("Ocorrência registrada com sucesso! ✅"),
            backgroundColor: AppColors.statusResolved,
          ),
        );
        Navigator.pop(context, true); // Retorna true para a tela 1
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

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = context.watch<UsuarioProvider>();
    final usuarioOuAdminLogado =
        usuarioProvider.estaLogado || usuarioProvider.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        title: const Text("Detalhes da Ocorrência"),
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mostrar Card do tipo selecionado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(OcorrenciaTipos.getTipoIcone(widget.tipoOcorrencia), color: AppColors.primaryTeal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        OcorrenciaTipos.getTipoNome(widget.tipoOcorrencia),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === DESCRIÇÃO ===
              _buildSectionHeader(
                icon: Icons.description_rounded,
                title: 'Passo 2: Descrição',
                subtitle: 'Descreva o que está acontecendo',
              ),
              const SizedBox(height: 14),
              Container(
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
                child: TextFormField(
                  controller: _descricaoController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Descreva a ocorrência com detalhes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
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
              ),

              const SizedBox(height: 24),

              // === FOTO ===
              _buildSectionHeader(
                icon: Icons.photo_camera_rounded,
                title: 'Foto',
                subtitle: usuarioOuAdminLogado
                    ? 'Tire uma foto ou escolha da galeria'
                    : 'Tire uma foto para registrar',
              ),
              const SizedBox(height: 14),

              _buildFotoSection(),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selecionarFoto,
                  icon: Icon(
                    usuarioOuAdminLogado
                        ? Icons.add_photo_alternate_rounded
                        : Icons.camera_alt_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _fotoSelecionada != null
                        ? 'Trocar foto'
                        : usuarioOuAdminLogado
                            ? 'Adicionar Foto'
                            : 'Tirar Foto 📸',
                  ),
                ),
              ),

              if (!usuarioOuAdminLogado) ...[
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.accentAmber),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Faça login para acessar a galeria de fotos',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accentAmber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // === LOCALIZAÇÃO ===
              _buildSectionHeader(
                icon: Icons.location_on_rounded,
                title: 'Localização',
                subtitle: 'Posição atual do dispositivo',
              ),
              const SizedBox(height: 14),
              _buildLocalizacaoCard(),

              const SizedBox(height: 32),

              // === BOTÃO ENVIAR ===
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _enviarOcorrencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentAmber,
                    foregroundColor: AppColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.accentAmber.withOpacity(0.4),
                  ),
                  child: _carregando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.textOnAccent,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Registrar Ocorrência',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryTeal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFotoSection() {
    if (_fotoSelecionada != null) {
      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                _fotoSelecionada!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _fotoSelecionada = null;
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.statusActive,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                size: 28,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nenhuma foto selecionada',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalizacaoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
          if (_posicaoAtual != null) ...[
            _buildLocationRow(
              Icons.my_location_rounded,
              'Latitude',
              _posicaoAtual!.latitude.toStringAsFixed(6),
            ),
            const SizedBox(height: 8),
            _buildLocationRow(
              Icons.explore_rounded,
              'Longitude',
              _posicaoAtual!.longitude.toStringAsFixed(6),
            ),
            const SizedBox(height: 8),
            _buildLocationRow(
              Icons.gps_fixed_rounded,
              'Precisão',
              '${_posicaoAtual!.accuracy.toStringAsFixed(2)} m',
            ),
          ] else ...[
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryTeal,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Obtendo localização...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _obterLocalizacao,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Atualizar localização'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryTeal),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }
}
