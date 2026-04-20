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
  String? _cidadeSelecionada; // Armazena o CÓDIGO
  bool _carregandoCidades = true;

  final List<Map<String, dynamic>> _tipos = [
    {'valor': 'PONTO_COLETA_AGUA', 'label': 'Coleta de Água', 'icon': Icons.water_drop_rounded, 'color': Colors.blue},
    {'valor': 'AREA_RISCO', 'label': 'Área de Risco', 'icon': Icons.warning_rounded, 'color': Colors.orange},
    {'valor': 'ABRIGO', 'label': 'Abrigo / Alojamento', 'icon': Icons.home_rounded, 'color': Colors.green},
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
    
    setState(() {
      _cidadesSuportadas = List<Map<String, String>>.from(prov.cidadesSuportadas);
      _carregandoCidades = false;
      
      // Se for Admin, travar na cidade dele
      if (prov.isAdmin && user?.cidade != null) {
        // Encontrar o código da cidade se o usuário tiver apenas o nome
        final correspondente = _cidadesSuportadas.firstWhere(
          (c) => c['nome']?.toLowerCase() == user?.cidade?.toLowerCase() || 
                 c['codigo'] == user?.cidade,
          orElse: () => {},
        );
        _cidadeSelecionada = correspondente.isNotEmpty ? correspondente['codigo'] : user?.cidade;
      }
    });
  }

  Future<void> _detectarCidade() async {
    final prov = context.read<UsuarioProvider>();
    final cidade = await _geocodingService.obterCidade(
      widget.posicao.latitude,
      widget.posicao.longitude,
    );
    if (mounted) {
      // Tentar mapear para nosso código usando a lista do provider
      String? codigoCorrespondente;
      if (cidade != null) {
        for (var c in prov.cidadesSuportadas) {
          String nome = c['nome'] ?? '';
          if (cidade.toLowerCase().contains(nome.toLowerCase()) || 
              nome.toLowerCase().contains(cidade.toLowerCase())) {
            codigoCorrespondente = c['codigo'];
            break;
          }
        }
      }

      setState(() {
        _cidadeDetectada = cidade;
        _cidadeSelecionada = codigoCorrespondente;
        _buscandoCidade = false;
      });
    }
  }

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
              
              // Cidade Detectada
               if (_carregandoCidades)
                  const LinearProgressIndicator()
               else if (context.read<UsuarioProvider>().isAdmin)
                 // Para Admin: Apenas exibe a cidade travada
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                   decoration: BoxDecoration(color: AppColors.backgroundOffWhite, borderRadius: BorderRadius.circular(12)),
                   child: Row(
                     children: [
                       const Icon(Icons.location_city_rounded, color: AppColors.primaryTeal, size: 20),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           'Jurisdição: ${_cidadesSuportadas.firstWhere((c) => c['codigo'] == _cidadeSelecionada, orElse: () => {'nome': _cidadeSelecionada ?? 'Sua Cidade'})['nome']}',
                           style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                         ),
                       ),
                       const Icon(Icons.lock_rounded, size: 16, color: AppColors.textLight),
                     ],
                   ),
                 )
               else
                 // Para Cidadão: Dropdown liberado
                 DropdownButtonFormField<String>(
                   value: _cidadeSelecionada,
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
                  child: Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('GPS: Localizando...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))]),
                )
              else if (_cidadeDetectada != null && _cidadeSelecionada == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('GPS detectou "$_cidadeDetectada", mas não está na nossa lista. Selecione manualmente.', style: const TextStyle(fontSize: 12, color: Colors.orange)),
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
    
    final userProvider = context.read<UsuarioProvider>();
    final user = userProvider.usuarioLogado;
    
    // Verificação de Cidade
    if (_cidadeSelecionada == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Localização Não Atendida'),
          content: Text('A cidade detectada "${_cidadeDetectada ?? 'Desconhecida'}" não está na lista de áreas atendidas.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        )
      );
      return;
    }

    // A cidade já foi travada na inicialização para Admins ou detectada para Cidadãos
    
    final novoPonto = PontoInteresse(
      tipo: _tipoSelecionado,
      descricao: _descricaoController.text.trim(),
      latitude: widget.posicao.latitude,
      longitude: widget.posicao.longitude,
      cidade: _cidadeSelecionada,
      criadoPor: user?.id,
    );
    
    try {
      final sucesso = await context.read<PontoInteresseProvider>().adicionarPonto(novoPonto);
      if (mounted) {
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ponto de interesse adicionado com sucesso!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível salvar o ponto. Verifique os dados.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
