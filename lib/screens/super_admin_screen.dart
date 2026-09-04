import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../providers/usuario_provider.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> with SingleTickerProviderStateMixin {
  static const Duration _tempoLimiteCarregamento = Duration(seconds: 10);

  late TabController _tabController;
  bool _carregandoPendentes = true;
  bool _carregandoTodas = true;
  String? _erroCarregamento;
  int _requisicaoAtual = 0;
  List<Map<String, dynamic>> _pendentes = [];
  List<Map<String, dynamic>> _todas = [];

  /// Retorna exclusivamente as cidades que já se cadastraram no sistema
  List<Map<String, String>> get _cidadesCadastradas {
    final Map<String, String> unicas = {};

    // 1. Cidades cadastradas e homologadas
    for (final item in _todas) {
      final c = item['cidade'];
      if (c is Map) {
        final cod = c['codigo']?.toString().trim().toUpperCase();
        final nome = c['nome']?.toString().trim();
        if (cod != null && cod.isNotEmpty) {
          unicas[cod] = (nome != null && nome.isNotEmpty) ? nome : cod;
        }
      }
    }

    // 2. Cidades que já se cadastraram mas estão pendentes
    for (final item in _pendentes) {
      final c = item['cidade'];
      if (c is Map) {
        final cod = c['codigo']?.toString().trim().toUpperCase();
        final nome = c['nome']?.toString().trim();
        if (cod != null && cod.isNotEmpty && !unicas.containsKey(cod)) {
          unicas[cod] = (nome != null && nome.isNotEmpty) ? '$nome (Pendente)' : cod;
        }
      }
    }

    final lista = unicas.entries
        .map((e) => {'codigo': e.key, 'nome': e.value})
        .toList();
    lista.sort((a, b) => a['nome']!.toLowerCase().compareTo(b['nome']!.toLowerCase()));
    return lista;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final requisicao = ++_requisicaoAtual;
    setState(() {
      _carregandoPendentes = true;
      _carregandoTodas = true;
      _erroCarregamento = null;
    });
    final apiService = context.read<ApiService>();

    Future<void> carregarPendentes() async {
      try {
        final resultado = await apiService
            .listarCidadesPendentesSuper()
            .timeout(_tempoLimiteCarregamento);
        if (mounted && requisicao == _requisicaoAtual) {
          setState(() {
            _pendentes = resultado;
          });
        }
      } catch (e) {
        if (mounted && requisicao == _requisicaoAtual) {
          final mensagem = e is TimeoutException
              ? 'Tempo limite ao carregar prefeituras pendentes.'
              : 'Não foi possível carregar as prefeituras pendentes.';
          setState(() {
            _erroCarregamento ??= mensagem;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted && requisicao == _requisicaoAtual) {
          setState(() {
            _carregandoPendentes = false;
          });
        }
      }
    }

    Future<void> carregarTodas() async {
      try {
        final resultado = await apiService
            .listarTodasCidadesSuper()
            .timeout(_tempoLimiteCarregamento);
        if (mounted && requisicao == _requisicaoAtual) {
          setState(() {
            _todas = resultado;
          });
        }
      } catch (e) {
        if (mounted && requisicao == _requisicaoAtual) {
          final mensagem = e is TimeoutException
              ? 'Tempo limite ao carregar cidades cadastradas.'
              : 'Não foi possível carregar todas as cidades.';
          setState(() {
            _erroCarregamento ??= mensagem;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted && requisicao == _requisicaoAtual) {
          setState(() {
            _carregandoTodas = false;
          });
        }
      }
    }

    await Future.wait([carregarPendentes(), carregarTodas()]);
  }

  void _mostrarClausulaEHomologar(Map<String, dynamic> item) async {
    final cidadeData = item['cidade'];
    final cidadeId = cidadeData['id']?.toString() ?? '';
    final cidadeNome = cidadeData['nome']?.toString() ?? '';
    final cidadeCodigo = cidadeData['codigo']?.toString() ?? '';
    final gestorData = item['gestor'];
    final gestorNome = gestorData != null ? gestorData['nome']?.toString() ?? 'Gestor' : 'Gestor';
    final gestorTelefone = gestorData != null ? gestorData['telefone']?.toString() ?? '' : '';
    final apiService = context.read<ApiService>();

    // Buscar a cláusula oficial mastigada gerada pelo backend
    String? clausula = await apiService.obterClausulaTrialSuper(cidadeId);
    clausula ??= 'Termo de Homologação de 120 Dias de Trial PRO para $cidadeNome ($cidadeCodigo).';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF0A192F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.gavel_rounded, color: Colors.amberAccent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Termo de Concessão • 120 Dias de Trial PRO',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$cidadeNome ($cidadeCodigo) • Responsável: $gestorNome${gestorTelefone.isNotEmpty ? ' • WhatsApp: $gestorTelefone' : ''}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 700,
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Roteiro Mastigado e Documentado
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.checklist_rounded, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ROTEIRO MASTIGADO DA OPERAÇÃO (120 DIAS)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _buildBadgeItem(Icons.verified_rounded, 'Plano PRO Ativado', Colors.green),
                        _buildBadgeItem(Icons.calendar_month_rounded, '120 Dias Corridos', Colors.indigo),
                        _buildBadgeItem(Icons.money_off_rounded, 'Custo R\$ 0,00 (Gratuito)', Colors.teal),
                        _buildBadgeItem(Icons.people_rounded, 'Até 5 Gestores + Agentes Ilimitados', Colors.deepOrange),
                        _buildBadgeItem(Icons.block_rounded, 'Zero Anúncios na Cidade', Colors.purple),
                        _buildBadgeItem(Icons.security_rounded, 'Enquadramento Lei 14.133/21', Colors.blueGrey),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Documento Oficial Formal (Base Legal & LGPD):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: clausula!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Termo formal dos 120 dias copiado com sucesso! 📋'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar Termo Completo', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Visualizador do Termo Formal
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      clausula!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.45,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Aviso sobre o pós-120 dias
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Régua pós-degustação: Avisos automáticos nos dias 7, 5, 3 e 1 antes do término. '
                        'Se não houver contratação por Dispensa, a cidade é convertida pacificamente ao Plano Base Gratuito.',
                        style: TextStyle(fontSize: 11, color: Colors.brown.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await apiService.aprovarCidadeSuper(cidadeId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Município $cidadeNome homologado! 120 dias de Trial PRO liberados! ✅'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _carregarDados();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao aprovar cidade: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Homologar e Iniciar 120 Dias PRO', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Widget _buildBadgeItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade800),
        ),
      ],
    );
  }

  void _abrirModalEditarPlano(Map<String, dynamic> item) {
    final cidadeData = item['cidade'];
    final cidadeId = cidadeData['id']?.toString() ?? '';
    final cidadeNome = cidadeData['nome']?.toString() ?? '';
    String planoSel = cidadeData['plano']?.toString() ?? 'BASE_GRATUITO';
    String statusSel = cidadeData['status']?.toString() ?? 'CONTRATO_ATIVO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Gerenciar Licença • $cidadeNome', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Plano da Cidade:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: planoSel,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'BASE_GRATUITO', child: Text('Plano Base (Gratuito)')),
                  DropdownMenuItem(value: 'GESTAO_MUNICIPAL', child: Text('Plano Gestão Municipal')),
                  DropdownMenuItem(value: 'PRO_MUNICIPAL', child: Text('Plano PRO Municipal')),
                ],
                onChanged: (v) => setDialogState(() => planoSel = v!),
              ),
              const SizedBox(height: 16),
              const Text('Status de Licenciamento:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: statusSel,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'TRIAL_ATIVO', child: Text('Trial Ativo')),
                  DropdownMenuItem(value: 'CONTRATO_ATIVO', child: Text('Contrato Ativo')),
                  DropdownMenuItem(value: 'EXPIRADO', child: Text('Expirado')),
                  DropdownMenuItem(value: 'BLOQUEADO', child: Text('Bloqueado')),
                ],
                onChanged: (v) => setDialogState(() => statusSel = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await context.read<ApiService>().atualizarPlanoManualSuper(
                    cidadeId,
                    plano: planoSel,
                    status: statusSel,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plano atualizado com sucesso! ✅'), backgroundColor: Colors.green),
                    );
                    _carregarDados();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        title: const Text('Painel Geral • Super Admin'),
        backgroundColor: const Color(0xFF0D253F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<UsuarioProvider>(
            builder: (context, usuario, _) {
              final cidades = _cidadesCadastradas;
              final selecionada = usuario.cidadeSuperAdmin;
              final temCidadeSelecionada = selecionada != null && cidades.any((c) => c['codigo'] == selecionada);

              return PopupMenuButton<String?>(
                tooltip: 'Escolher Cidade para Representar',
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_city_rounded, color: Colors.amberAccent, size: 18),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          temCidadeSelecionada
                              ? cidades.firstWhere((c) => c['codigo'] == selecionada)['nome']!
                              : 'Representar',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 20),
                    ],
                  ),
                ),
                onSelected: (cod) {
                  usuario.selecionarCidadeSuperAdmin(cod);
                },
                itemBuilder: (context) {
                  if (cidades.isEmpty) {
                    return [
                      const PopupMenuItem<String?>(
                        value: null,
                        enabled: false,
                        child: Text(
                          'Nenhuma cidade cadastrada ainda',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ];
                  }

                  return [
                    PopupMenuItem<String?>(
                      value: '',
                      child: Row(
                        children: [
                          Icon(
                            Icons.public_rounded,
                            size: 18,
                            color: selecionada == null || selecionada.isEmpty ? AppColors.primaryTeal : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Visão Geral (Todas)',
                            style: TextStyle(
                              fontWeight: selecionada == null || selecionada.isEmpty ? FontWeight.bold : FontWeight.normal,
                              color: selecionada == null || selecionada.isEmpty ? AppColors.primaryTeal : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    ...cidades.map((c) {
                      final isSelected = selecionada == c['codigo'];
                      return PopupMenuItem<String?>(
                        value: c['codigo'],
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${c['nome']} (${c['codigo']})',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primaryTeal : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ];
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recarregar Dados',
            onPressed: _carregarDados,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions_rounded),
              text: 'Pendentes (${_pendentes.length})',
            ),
            Tab(
              icon: const Icon(Icons.location_city_rounded),
              text: 'Todas as Cidades (${_todas.length})',
            ),
          ],
        ),
      ),
      body: (_carregandoPendentes && _carregandoTodas)
          ? const Center(child: CircularProgressIndicator())
          : (_erroCarregamento != null && _pendentes.isEmpty && _todas.isEmpty)
              ? _buildErroCarregamento()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabPendentes(),
                    _buildTabTodas(),
                  ],
                ),
    );
  }

  Widget _buildErroCarregamento() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _erroCarregamento!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregarDados,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPendentes() {
    if (_carregandoPendentes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendentes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text('Nenhuma prefeitura aguardando aprovação!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Todas as solicitações de coordenadores foram homologadas.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendentes.length,
      itemBuilder: (context, index) {
        final item = _pendentes[index];
        final cidade = item['cidade'];
        final gestores = item['gestores'] as List? ?? [];
        final primeiroGestorRaw = gestores.isNotEmpty ? gestores.first : null;
        final primeiroGestor = primeiroGestorRaw is Map ? primeiroGestorRaw : null;

        final telefone = primeiroGestor?['telefone']?.toString() ?? 'Não informado';
        final waClean = telefone.replaceAll(RegExp(r'\D'), '');

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cidade['nome'] ?? 'Cidade', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('Código: ${cidade['codigo'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade300)),
                      child: const Text('AGUARDANDO TRIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (primeiroGestor != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 16, color: AppColors.primaryTeal),
                      const SizedBox(width: 6),
                      Text('Coordenador: ${primeiroGestor['nome']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(primeiroGestor['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text('WhatsApp: $telefone', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (waClean.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => launchUrl(Uri.parse('https://wa.me/55$waClean')),
                          child: const Text('Conversar ↗', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _mostrarClausulaEHomologar(item),
                    icon: const Icon(Icons.verified_user_rounded, color: Colors.amberAccent),
                    label: const Text('Ver Cláusula dos 120 Dias & Homologar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabTodas() {
    if (_carregandoTodas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_city_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma cidade cadastrada ainda',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Os municípios aparecerão aqui conforme forem cadastrados e homologados.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _carregarDados,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Recarregar'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todas.length,
      itemBuilder: (context, index) {
        final item = _todas[index];
        final cidade = item['cidade'];
        final totalGestores = item['totalGestores'] ?? 0;
        final totalAgentes = item['totalAgentes'] ?? 0;
        final trialAtivo = item['trialAtivo'] == true;
        final diasRestantes = item['diasRestantesTrial'] ?? 0;
        final planoEfetivo = item['planoEfetivo']?.toString() ?? cidade['plano']?.toString() ?? 'BASE_GRATUITO';

        Color badgeColor = Colors.grey;
        String badgeText = planoEfetivo;
        if (trialAtivo) {
          badgeColor = Colors.purple;
          badgeText = 'TRIAL PRO ($diasRestantes dias)';
        } else if (planoEfetivo == 'PRO_MUNICIPAL') {
          badgeColor = Colors.blue.shade700;
        } else if (planoEfetivo == 'GESTAO_MUNICIPAL') {
          badgeColor = Colors.orange.shade700;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Text(cidade['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Text('(${cidade['codigo']})', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                  ),
                  const SizedBox(width: 12),
                  Text('👥 $totalGestores gestor(es) • 🚨 $totalAgentes agente(s)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.primaryTeal),
              tooltip: 'Editar Plano / Licença',
              onPressed: () => _abrirModalEditarPlano(item),
            ),
          ),
        );
      },
    );
  }
}
