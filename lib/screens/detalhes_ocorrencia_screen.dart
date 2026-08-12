import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../services/geocoding_service.dart';

import '../constants/app_colors.dart';
import '../constants/ocorrencia_tipos.dart';
import '../models/ocorrencia.dart';
import '../models/usuario.dart';
import '../providers/ocorrencia_provider.dart';
import '../providers/usuario_provider.dart';
import '../services/ad_service.dart';
import '../services/localizacao_service.dart';

class DetalhesOcorrenciaScreen extends StatefulWidget {
  final String tipoOcorrencia;

  const DetalhesOcorrenciaScreen({super.key, required this.tipoOcorrencia});

  @override
  State<DetalhesOcorrenciaScreen> createState() =>
      _DetalhesOcorrenciaScreenState();
}

class _DetalhesOcorrenciaScreenState extends State<DetalhesOcorrenciaScreen>
    with RestorationMixin {
  final _formKey = GlobalKey<FormState>();

  // Restorável: sobrevive ao Android matar a Activity (ex: câmera em background)
  final _descricaoController = RestorableTextEditingController();
  final _fotoPath = RestorableStringN(null);

  bool _visaoDistancia = false;
  final _distanciaController = RestorableTextEditingController();
  final _direcaoController = RestorableTextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final GeocodingService _geocodingService = GeocodingService();

  Position? _posicaoAtual;
  String? _cidadeDetectada;
  bool _carregando = false;
  String? _codigoCidadeDetectada;
  DateTime? _dataCustomizada;

  // Usamos _fotoPath.value diretamente para evitar File() no Web

  @override
  String? get restorationId => 'detalhes_ocorrencia_screen';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_descricaoController, 'descricao_controller');
    registerForRestoration(_fotoPath, 'foto_path');
    registerForRestoration(_distanciaController, 'distancia_controller');
    registerForRestoration(_direcaoController, 'direcao_controller');
  }

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
  }

  Future<void> _obterLocalizacao() async {
    if (!mounted) return;
    setState(() => _carregando = true);
    try {
      final prov = context.read<UsuarioProvider>();
      final posicao = await _localizacaoService.obterPosicaoAtual();
      if (!mounted) return;
      
      if (posicao != null) {
        setState(() {
          _posicaoAtual = posicao;
        });
        
        try {
          final cidade = await _geocodingService.obterCidade(
            posicao.latitude, 
            posicao.longitude
          );
          if (!mounted) return;
          
          if (cidade != null) {
            setState(() {
              _cidadeDetectada = cidade;
              for (var c in prov.cidadesSuportadas) {
                String nome = c['nome'] ?? '';
                if (cidade.toLowerCase().contains(nome.toLowerCase()) || 
                    nome.toLowerCase().contains(cidade.toLowerCase())) {
                  _codigoCidadeDetectada = c['codigo'];
                  break;
                }
              }
            });
          }
        } catch (e) {
          debugPrint("Erro ao obter cidade: $e");
        }
      }

      // Fallback seguro se o GPS estiver desativado ou bloqueado
      if (_posicaoAtual == null) {
        final cidadeCod = prov.cidadeAtiva ?? 'PIR';
        final coordsFallback = ClimaService.obterCoordenadasCidade(cidadeCod);
        setState(() {
          _posicaoAtual = Position(
            latitude: coordsFallback['lat']!,
            longitude: coordsFallback['lng']!,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          _codigoCidadeDetectada ??= cidadeCod;
        });
      }
    } catch (e) {
      if (mounted) {
        final prov = context.read<UsuarioProvider>();
        final cidadeCod = prov.cidadeAtiva ?? 'PIR';
        final coordsFallback = ClimaService.obterCoordenadasCidade(cidadeCod);
        setState(() {
          _posicaoAtual = Position(
            latitude: coordsFallback['lat']!,
            longitude: coordsFallback['lng']!,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          _codigoCidadeDetectada ??= cidadeCod;
        });
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _obterLocalizacaoSemAlterarCarregando() async {
    try {
      final prov = context.read<UsuarioProvider>();
      final posicao = await _localizacaoService.obterPosicaoAtual();
      if (!mounted) return;
      if (posicao != null) {
        setState(() => _posicaoAtual = posicao);
        try {
          final cidade = await _geocodingService.obterCidade(posicao.latitude, posicao.longitude);
          if (!mounted) return;
          if (cidade != null) {
            setState(() {
              _cidadeDetectada = cidade;
              for (var c in prov.cidadesSuportadas) {
                String nome = c['nome'] ?? '';
                if (cidade.toLowerCase().contains(nome.toLowerCase()) ||
                    nome.toLowerCase().contains(cidade.toLowerCase())) {
                  _codigoCidadeDetectada = c['codigo'];
                  break;
                }
              }
            });
          }
        } catch (e) {
          debugPrint("Erro ao obter cidade: $e");
        }
      }
    } catch (e) {
      // silencioso — o chamador vai verificar _codigoCidadeDetectada
    }
  }

  Future<void> _selecionarFoto() async {
    final usuarioProvider = context.read<UsuarioProvider>();
    final usuarioLogado = usuarioProvider.estaLogado || usuarioProvider.isAdmin;

    if (!usuarioLogado) {
      // Usuário sem cadastro: câmera no mobile, galeria no PC
      try {
        final foto = await _imagePicker.pickImage(
          source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
          imageQuality: 50,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (!mounted) return;
        if (foto != null) {
          setState(() {
            _fotoPath.value = foto.path;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao tirar foto: $e")),
          );
        }
      }
      return;
    }

    // Usuário logado ou Admin: opção câmera + galeria
    final escolha = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          color: AppColors.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                if (!kIsWeb)
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
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
                      color: AppColors.accentAmber.withValues(alpha: 0.1),
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
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (!mounted) return;
      if (foto != null) {
        setState(() {
          _fotoPath.value = foto.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao obter foto: $e")),
        );
      }
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

    // Verificação de Cidade para TODOS os usuários
    if (_codigoCidadeDetectada == null) {
      // Chamar lógica de localização SEM alterar _carregando
      await _obterLocalizacaoSemAlterarCarregando();
      if (!mounted) return;
    }
    
    if (_codigoCidadeDetectada == null) {
      setState(() => _carregando = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Localização Não Atendida'),
            content: Text('A cidade detectada "${_cidadeDetectada ?? 'Desconhecida'}" não faz parte das áreas atendidas pela Defesa Civil neste aplicativo.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          )
        );
      }
      return;
    }

    // Verificação de Jurisdição para Admins
    final userProvider = context.read<UsuarioProvider>();
    final user = userProvider.usuarioLogado;
    if (userProvider.isAdmin) {
      String? cidadeUsuario = user?.cidade; // Pode ser CÓDIGO ou NOME
      
      // Mapear nome para código se necessário
      final correspondente = userProvider.cidadesSuportadas.firstWhere(
        (c) => c['nome']?.toLowerCase() == cidadeUsuario?.toLowerCase() || 
               c['codigo'] == cidadeUsuario,
        orElse: () => {},
      );
      final codigoAdmin = correspondente.isNotEmpty ? correspondente['codigo'] : cidadeUsuario;

      if (codigoAdmin != null && codigoAdmin != _codigoCidadeDetectada) {
        String nomeCidadeAdmin = correspondente.isNotEmpty ? correspondente['nome']! : (cidadeUsuario ?? 'Sua Cidade');
        
        // Avisar que a ocorrência será vinculada à cidade do administrador
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aviso: Ocorrência vinculada à sua base ($nomeCidadeAdmin), mesmo detectada em outra região.'),
              backgroundColor: AppColors.primaryTeal,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        // Forçar a cidade a ser a do admin
        _codigoCidadeDetectada = codigoAdmin;
      }
    }

    try {
      final usuarioProvider = context.read<UsuarioProvider>();
      final usuarioLogado = usuarioProvider.usuarioLogado;
      final isAgenteOuAdmin = usuarioProvider.isAdmin || (usuarioLogado?.role == Role.agente);

      if (kIsWeb && usuarioProvider.isAdmin && _dataCustomizada == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Administradores no Web devem obrigatoriamente informar uma Data e Hora no passado.'),
              backgroundColor: AppColors.statusActive,
            ),
          );
          setState(() => _carregando = false);
        }
        return;
      }

      String descricaoFinal = _descricaoController.value.text;
      if (_visaoDistancia) {
        final dist = _distanciaController.value.text.trim();
        final dir = _direcaoController.value.text.trim();
        if (dist.isNotEmpty || dir.isNotEmpty) {
          descricaoFinal = "[Observado à distância: ${dist.isNotEmpty ? dist : '?'} - Direção: ${dir.isNotEmpty ? dir : '?'}]\n\n$descricaoFinal";
        }
      }

      final ocorrencia = Ocorrencia(
        tipo: widget.tipoOcorrencia,
        descricao: descricaoFinal,
        latitude: _posicaoAtual!.latitude,
        longitude: _posicaoAtual!.longitude,
        cidade: _codigoCidadeDetectada, // Sempre usa o CÓDIGO
        caminhoFoto: _fotoPath.value,
        usuarioId: usuarioLogado?.id,
        // Se for agente/admin, ele já é parte da ocorrência e ela é marcada como 'criada por agente'
        agentes: isAgenteOuAdmin ? usuarioLogado?.nome : null,
        criadoPorAgente: isAgenteOuAdmin,
        dataHora: _dataCustomizada,
      );

      await context.read<OcorrenciaProvider>().adicionarOcorrencia(ocorrencia);
      if (!mounted) return;

      // Se o usuário não estiver logado, mostramos o aviso solicitado
      if (!usuarioProvider.estaLogado) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.accentAmber),
                SizedBox(width: 10),
                Text('Aviso Importante'),
              ],
            ),
            content: const Text(
              'Sua ocorrência foi registrada com sucesso!\n\n'
              'Como você não está logado, esta ocorrência não aparecerá no seu histórico enquanto estiver pendente de aprovação. '
              'Ela ficará visível para todos no mapa assim que for aprovada pela Defesa Civil.'
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                child: const Text('Entendido', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ocorrência registrada com sucesso! ✅"),
            backgroundColor: AppColors.statusResolved,
          ),
        );
      }

      if (mounted) {
        // Interstitial Ad após registro bem-sucedido (Regra Mestra)
        if (!usuarioProvider.estaLogado) {
          try {
            context.read<AdService>().mostrarInterstitial();
          } catch (_) {}
        }
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

  Future<void> _mostrarDialogLocalizacaoManual(UsuarioProvider usuarioProvider) async {
    ll.LatLng center = const ll.LatLng(-23.55052, -46.63330);
    if (_posicaoAtual != null) {
      center = ll.LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude);
    }
    
    ll.LatLng? selectedLocation = center;
    final latController = TextEditingController(text: center.latitude.toString());
    final lngController = TextEditingController(text: center.longitude.toString());
    
    final mapController = MapController();
    bool buscando = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Localização Manual'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Clique no mapa ou digite as coordenadas exatas.'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: 13,
                            onTap: (tapPosition, point) {
                              setStateDialog(() {
                                selectedLocation = point;
                                latController.text = point.latitude.toString();
                                lngController.text = point.longitude.toString();
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.defesacivil.app',
                            ),
                            if (selectedLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: selectedLocation!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latController,
                            decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            onChanged: (val) {
                              final lat = double.tryParse(val);
                              if (lat != null && selectedLocation != null) {
                                setStateDialog(() {
                                  selectedLocation = ll.LatLng(lat, selectedLocation!.longitude);
                                  mapController.move(selectedLocation!, mapController.camera.zoom);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lngController,
                            decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            onChanged: (val) {
                              final lng = double.tryParse(val);
                              if (lng != null && selectedLocation != null) {
                                setStateDialog(() {
                                  selectedLocation = ll.LatLng(selectedLocation!.latitude, lng);
                                  mapController.move(selectedLocation!, mapController.camera.zoom);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (buscando) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ]
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: buscando ? null : () async {
                  if (selectedLocation == null) return;
                  
                  setStateDialog(() => buscando = true);
                  
                  final lat = selectedLocation!.latitude;
                  final lng = selectedLocation!.longitude;
                  final cidade = await _geocodingService.obterCidade(lat, lng);
                  
                  if (mounted) {
                    setStateDialog(() => buscando = false);
                    setState(() {
                      _posicaoAtual = Position(
                        latitude: lat,
                        longitude: lng,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        heading: 0,
                        speed: 0,
                        speedAccuracy: 0,
                        altitudeAccuracy: 0,
                        headingAccuracy: 0,
                      );
                      _cidadeDetectada = cidade;
                      
                      _codigoCidadeDetectada = null;
                      if (cidade != null) {
                        for (var c in usuarioProvider.cidadesSuportadas) {
                          String nome = c['nome'] ?? '';
                          if (cidade.toLowerCase().contains(nome.toLowerCase()) || 
                              nome.toLowerCase().contains(cidade.toLowerCase())) {
                            _codigoCidadeDetectada = c['codigo'];
                            break;
                          }
                        }
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Localização definida: ${cidade ?? "Desconhecida"}')),
                    );
                  }
                },
                child: const Text('Confirmar Local'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = context.watch<UsuarioProvider>();
    final usuarioOuAdminLogado =
        usuarioProvider.estaLogado || usuarioProvider.isAdmin;

    return Scaffold(
      restorationId: 'detalhes_ocorrencia_scaffold',
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        title: const Text("Detalhes da Ocorrência"),
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
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
              // Banner Fixo de Aviso Comunitário (Requisito Apple 2.1)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.accentAmber, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Isso NÃO é canal oficial. Emergência real: 190 (Polícia) / 193 (Bombeiros) / 199 (Defesa Civil)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              if (kIsWeb && usuarioOuAdminLogado && usuarioProvider.isAdmin) ...[
                _buildSectionHeader(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Ferramentas de Administrador',
                  subtitle: 'Opções avançadas exclusivas para web',
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryTeal),
                        title: const Text('Data e Hora Personalizada (Obrigatório)'),
                        subtitle: Text(_dataCustomizada != null 
                          ? '${_dataCustomizada!.day.toString().padLeft(2, '0')}/${_dataCustomizada!.month.toString().padLeft(2, '0')}/${_dataCustomizada!.year} às ${_dataCustomizada!.hour.toString().padLeft(2, '0')}:${_dataCustomizada!.minute.toString().padLeft(2, '0')}'
                          : 'Toque para selecionar uma data no passado'),
                        trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dataCustomizada ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null && mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_dataCustomizada ?? DateTime.now()),
                            );
                            if (time != null) {
                              setState(() {
                                _dataCustomizada = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                              });
                            }
                          }
                        },
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.map_rounded, color: AppColors.primaryTeal),
                        title: const Text('Localização Manual'),
                        subtitle: Text(_posicaoAtual != null ? '${_posicaoAtual!.latitude.toStringAsFixed(5)}, ${_posicaoAtual!.longitude.toStringAsFixed(5)}\n${_cidadeDetectada ?? ""}' : 'Sem localização definida'),
                        trailing: const Icon(Icons.edit_location_alt_rounded, size: 20),
                        onTap: () {
                          _mostrarDialogLocalizacaoManual(usuarioProvider);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Mostrar Card do tipo selecionado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
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
                  controller: _descricaoController.value,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Descreva o que você observou (uso comunitário, não substitui os órgãos oficiais)...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                  ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return "Digite uma descrição";
                      }
                      return null;
                    },
                ),
              ),

              const SizedBox(height: 12),
              
              // === VISÃO À DISTÂNCIA ===
              Container(
                decoration: BoxDecoration(
                  color: _visaoDistancia ? AppColors.accentAmber.withValues(alpha: 0.1) : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _visaoDistancia ? AppColors.accentAmber.withValues(alpha: 0.5) : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Estou reportando à distância',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Marque se você não está no local exato do GPS, mas tem contato visual',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      activeThumbColor: AppColors.accentAmber,
                      value: _visaoDistancia,
                      onChanged: (val) => setState(() => _visaoDistancia = val),
                    ),
                    if (_visaoDistancia)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _distanciaController.value,
                                decoration: InputDecoration(
                                  labelText: 'Distância estimada',
                                  hintText: 'Ex: 500m, 2km',
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _direcaoController.value,
                                decoration: InputDecoration(
                                  labelText: 'Direção / Lado',
                                  hintText: 'Ex: Norte, Direita',
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // === FOTO ===
              _buildSectionHeader(
                icon: Icons.photo_camera_rounded,
                title: 'Foto',
                subtitle: usuarioOuAdminLogado
                    ? 'Tire uma foto or escolha da galeria'
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
                    _fotoPath.value != null
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
                    shadowColor: AppColors.accentAmber.withValues(alpha: 0.4),
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
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
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
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
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
    if (_fotoPath.value != null) {
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
              child: kIsWeb
                  ? Image.network(
                      _fotoPath.value!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(_fotoPath.value!),
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
                  _fotoPath.value = null;
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
                      color: Colors.black.withValues(alpha: 0.2),
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
                color: AppColors.primaryTeal.withValues(alpha: 0.08),
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
            if (_cidadeDetectada != null) ...[
              const SizedBox(height: 8),
              _buildLocationRow(
                Icons.location_city_rounded,
                'Cidade',
                _cidadeDetectada!,
              ),
            ],
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
    _fotoPath.dispose();
    super.dispose();
  }
}
