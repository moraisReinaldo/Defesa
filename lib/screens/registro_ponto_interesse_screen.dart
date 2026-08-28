import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../models/ponto_interesse.dart';
import '../providers/ponto_interesse_provider.dart';
import '../providers/usuario_provider.dart';
import '../services/geocoding_service.dart';

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
  String? _cidadeDetectada;
  bool _buscandoCidade = true;
  final _geocodingService = GeocodingService();
  
  List<Map<String, String>> _cidadesSuportadas = [];
  String? _cidadeSelecionada; // Armazena o CÓDIGO (ex: BP, PIR, JOA)
  bool _carregandoCidades = true;
  bool _salvando = false;

  final List<Map<String, dynamic>> _tipos = [
    {'valor': 'PONTO_COLETA_AGUA', 'label': 'Coleta de Água', 'icon': Icons.water_drop_rounded, 'color': Colors.blue},
    {'valor': 'AREA_RISCO', 'label': 'Área de Risco', 'icon': Icons.warning_rounded, 'color': Colors.orange},
    {'valor': 'ABRIGO', 'label': 'Abrigo / Alojamento', 'icon': Icons.home_rounded, 'color': Colors.green},
    {'valor': 'BASE_DEFESA', 'label': 'Base da Defesa Civil', 'icon': Icons.security_rounded, 'color': Colors.indigo},
    {'valor': 'DESLIZAMENTO', 'label': 'Risco Deslizamento', 'icon': Icons.terrain_rounded, 'color': Colors.brown},
    {'valor': 'OUTRO', 'label': 'Outro Ponto', 'icon': Icons.location_on_rounded, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _detectarCidade();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarCidades());
  }

  void _carregarCidades() {
    if (!mounted) return;
    final prov = context.read<UsuarioProvider>();
    final user = prov.usuarioLogado;
    final isGestor = prov.isAdmin || prov.isAgente;

    // Se não for gestor, não deve acessar esta tela
    if (!isGestor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas administradores e agentes da Defesa Civil podem cadastrar pontos de interesse.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
      Navigator.pop(context);
      return;
    }
    
    setState(() {
      _cidadesSuportadas = List<Map<String, String>>.from(prov.cidadesSuportadas);
      _carregandoCidades = false;
      
      // Fixar na jurisdição do gestor
      if (user?.cidade != null) {
        final correspondente = _cidadesSuportadas.firstWhere(
          (c) => c['nome']?.toLowerCase() == user?.cidade?.toLowerCase() || 
                 c['codigo'] == user?.cidade,
          orElse: () => {},
        );
        _cidadeSelecionada = correspondente.isNotEmpty ? correspondente['codigo'] : user?.cidade;
      }
      
      // Fallback para cidade ativa se o gestor não tiver cidade cadastrada
      _cidadeSelecionada ??= prov.cidadeAtiva ?? 'BP';
    });
  }

  Future<void> _detectarCidade() async {
    try {
      final cidade = await _geocodingService.obterCidade(
        widget.posicao.latitude,
        widget.posicao.longitude,
      );
      if (mounted) {
        setState(() {
          _cidadeDetectada = cidade;
          _buscandoCidade = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _buscandoCidade = false);
      }
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UsuarioProvider>();
    final isGestor = prov.isAdmin || prov.isAgente;

    final nomeCidadeExibicao = _cidadesSuportadas.firstWhere(
      (c) => c['codigo'] == _cidadeSelecionada,
      orElse: () => {'nome': _cidadeSelecionada ?? 'Sua Cidade'},
    )['nome'];

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
              
              // Jurisdição / Cidade
              const Text('Jurisdição / Cidade', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_carregandoCidades)
                const LinearProgressIndicator()
              else if (isGestor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOffWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_city_rounded, color: AppColors.primaryTeal, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Jurisdição: $nomeCidadeExibicao',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      const Icon(Icons.lock_rounded, size: 16, color: AppColors.textLight),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _cidadeSelecionada,
                  hint: const Text('Selecione a cidade'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_city_rounded, color: AppColors.primaryTeal, size: 20),
                    filled: true,
                    fillColor: AppColors.backgroundOffWhite,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  items: _cidadesSuportadas.map((c) => DropdownMenuItem(value: c['codigo'], child: Text(c['nome']!))).toList(),
                  onChanged: (v) => setState(() => _cidadeSelecionada = v),
                  validator: (v) => v == null ? 'Obrigatório' : null,
                ),

              if (_buscandoCidade)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Verificando localização no mapa...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              else if (_cidadeDetectada != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Local detectado: $_cidadeDetectada',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição / Nome do Local',
                  hintText: 'Ex: Base Operacional, Ponto de Coleta, Abrigo Comunitário...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe uma descrição' : null,
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'SALVAR PONTO NO MAPA',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
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
    
    final userProvider = context.read<UsuarioProvider>();
    final user = userProvider.usuarioLogado;
    final isGestor = userProvider.isAdmin || userProvider.isAgente;

    if (!isGestor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas administradores e agentes da Defesa Civil podem cadastrar pontos.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    // Garantir que _cidadeSelecionada seja preenchida
    String? codigoCidade = _cidadeSelecionada;
    if (codigoCidade == null && user?.cidade != null) {
      final correspondente = _cidadesSuportadas.firstWhere(
        (c) => c['nome']?.toLowerCase() == user?.cidade?.toLowerCase() || 
               c['codigo'] == user?.cidade,
        orElse: () => {},
      );
      codigoCidade = correspondente.isNotEmpty ? correspondente['codigo'] : user?.cidade;
    }
    codigoCidade ??= userProvider.cidadeAtiva ?? 'BP';

    final novoPonto = PontoInteresse(
      tipo: _tipoSelecionado,
      descricao: _descricaoController.text.trim(),
      latitude: widget.posicao.latitude,
      longitude: widget.posicao.longitude,
      cidade: codigoCidade,
      criadoPor: user?.id,
    );
    
    try {
      final pontoProv = context.read<PontoInteresseProvider>();
      final sucesso = await pontoProv.adicionarPonto(novoPonto);
      if (mounted) {
        setState(() => _salvando = false);
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ponto de interesse adicionado com sucesso! ✅'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível salvar o ponto. Verifique a conexão.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
