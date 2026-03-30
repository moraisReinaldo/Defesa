import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../models/ponto_interesse.dart';
import '../providers/ponto_interesse_provider.dart';
import '../providers/usuario_provider.dart';

class RegistroPontoInteresseScreen extends StatefulWidget {
  final LatLng posicao;

  const RegistroPontoInteresseScreen({super.key, required this.posicao});

  @override
  State<RegistroPontoInteresseScreen> createState() => _RegistroPontoInteresseScreenState();
}

class _RegistroPontoInteresseScreenState extends State<RegistroPontoInteresseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  String _tipoSelecionado = 'PONTO_COLETA_AGUA';

  final List<Map<String, dynamic>> _tipos = [
    {'valor': 'PONTO_COLETA_AGUA', 'label': 'Coleta de Água', 'icon': Icons.water_drop_rounded, 'color': Colors.blue},
    {'valor': 'AREA_RISCO', 'label': 'Área de Risco', 'icon': Icons.warning_rounded, 'color': Colors.orange},
    {'valor': 'ABRIGO', 'label': 'Abrigo / Alojamento', 'icon': Icons.home_rounded, 'color': Colors.green},
    {'valor': 'DESLIZAMENTO', 'label': 'Risco Deslizamento', 'icon': Icons.terrain_rounded, 'color': Colors.brown},
    {'valor': 'OUTRO', 'label': 'Outro Ponto', 'icon': Icons.location_on_rounded, 'color': Colors.grey},
  ];

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Ponto de Interesse'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Defina os detalhes do local selecionado no mapa.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              
              // Tipo
              const Text('Tipo de Ponto', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tipos.map((t) {
                  final selecionado = _tipoSelecionado == t['valor'];
                  return ChoiceChip(
                    label: Text(t['label']),
                    avatar: Icon(t['icon'], size: 16, color: selecionado ? Colors.white : t['color']),
                    selected: selecionado,
                    onSelected: (val) => setState(() => _tipoSelecionado = t['valor']),
                    selectedColor: t['color'],
                    labelStyle: TextStyle(color: selecionado ? Colors.white : AppColors.textPrimary),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição / Nome do Local',
                  hintText: 'Ex: Caixa d\'água comunitária, Encosta instável...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text('SALVAR PONTO NO MAPA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = context.read<UsuarioProvider>().usuarioLogado;
    
    final novoPonto = PontoInteresse(
      tipo: _tipoSelecionado,
      descricao: _descricaoController.text.trim(),
      latitude: widget.posicao.latitude,
      longitude: widget.posicao.longitude,
      cidade: user?.cidade,
      criadoPor: user?.id,
    );
    
    await context.read<PontoInteresseProvider>().adicionarPonto(novoPonto);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponto de interesse adicionado com sucesso!')),
      );
      Navigator.pop(context, true);
    }
  }
}
