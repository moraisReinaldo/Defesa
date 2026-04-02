import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../providers/usuario_provider.dart';
import '../services/api_service.dart';
import '../services/localizacao_service.dart';
import '../services/geocoding_service.dart';

class LoginScreen extends StatefulWidget {
  final bool modoRegistro;
  const LoginScreen({super.key, this.modoRegistro = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _modoRegistro;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cidadeController = TextEditingController();
  bool _carregando = false;
  bool _senhaVisivel = false;
  String _roleSelecionada = 'CIDADAO'; 
  String? _cidadeSelecionada;
  @override
  void initState() {
    super.initState();
    _modoRegistro = widget.modoRegistro;
    
    // Inicia detecção se as cidades já estiverem carregadas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_modoRegistro) _detectarCidadeAtual();
    });
  }

  Future<void> _detectarCidadeAtual() async {
    try {
      final prov = context.read<UsuarioProvider>();
      final locSvc = LocalizacaoService();
      final pos = await locSvc.obterPosicaoAtual();
      if (pos != null) {
        final geocoder = GeocodingService();
        final cidadeNome = await geocoder.obterCidade(pos.latitude, pos.longitude);
        
        if (cidadeNome != null && mounted) {
          String? codigo;
          for (var c in prov.cidadesSuportadas) {
            final nome = c['nome'] ?? '';
            if (cidadeNome.toLowerCase().contains(nome.toLowerCase()) || 
                nome.toLowerCase().contains(cidadeNome.toLowerCase())) {
              codigo = c['codigo'];
              break;
            }
          }
          if (codigo != null) {
            setState(() => _cidadeSelecionada = codigo);
          }
        }
      }
    } catch (_) {}
  }

  bool _concordaLGPD = false;

  void _mostrarTermos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de Privacidade (LGPD)'),
        content: const SingleChildScrollView(
          child: Text(
            'Ao utilizar este aplicativo, você concorda com a coleta de sua localização para registro de ocorrências, '
            'uso de sua câmera para fotos de desastres e armazenamento de seus dados de contato para fins de segurança pública. '
            '\n\nSeus dados são protegidos seguindo os padrões da LGPD e nunca serão vendidos a terceiros.'
            '\n\nPara ler a política completa, acesse nosso site oficial da Defesa Civil.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_modoRegistro && !_concordaLGPD) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Você deve aceitar os termos da LGPD para continuar'),
          backgroundColor: AppColors.statusActive));
      return;
    }

    setState(() => _carregando = true);

    try {
      final prov = context.read<UsuarioProvider>();
      if (_modoRegistro) {
        final result = await prov.cadastrar(
          UsuarioRequest(
            nome: _nomeController.text,
            email: _emailController.text,
            telefone: _telefoneController.text, 
            senha: _senhaController.text,
            cidade: _cidadeSelecionada ?? '', 
            role: _roleSelecionada,
            status: _roleSelecionada == 'ADMINISTRADOR' ? 'PENDENTE' : 'ATIVO',
            concordaLGPD: _concordaLGPD,
          ),
        );
        bool ok = result['sucesso'] ?? false;
        bool pendente = result['pendente'] ?? false;

        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(pendente 
                ? 'Cadastro realizado! Aguardando aprovação por e-mail. 📧' 
                : 'Cadastro realizado! Você já pode entrar. ✅'),
              backgroundColor: AppColors.statusResolved));
          if (mounted) Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['message'] ?? 'Erro ao cadastrar'),
              backgroundColor: AppColors.statusActive));
        }
      } else {
        bool ok = await prov.login(_emailController.text, _senhaController.text);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Login realizado! ✅'),
              backgroundColor: AppColors.statusResolved));
          if (mounted) Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Email ou senha incorretos'),
              backgroundColor: AppColors.statusActive));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: ${e.toString().replaceAll('Exception: ', '')}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.statusActive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16, bottom: 32),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/images/defe.png', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(_modoRegistro ? 'Criar Conta' : 'Bem-vindo!',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(_modoRegistro ? 'Cadastre-se para acompanhar ocorrências' : 'Entre com sua conta',
                      style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(180))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_modoRegistro) ...[
                      _field('Nome completo', _nomeController, Icons.person_rounded, 'Seu nome', 
                        validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null),
                      
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'CIDADAO', label: Text('Cidadão'), icon: Icon(Icons.person_outline_rounded)),
                            ButtonSegment(value: 'ADMINISTRADOR', label: Text('Admin'), icon: Icon(Icons.admin_panel_settings_outlined)),
                          ],
                          selected: {_roleSelecionada},
                          onSelectionChanged: (Set<String> selection) {
                            setState(() => _roleSelecionada = selection.first);
                          },
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: AppColors.primaryTeal,
                            selectedForegroundColor: Colors.white,
                            side: BorderSide(color: AppColors.primaryTeal.withAlpha(50)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _field('Email', _emailController, Icons.email_rounded, 'seu@email.com', 
                      keyboardType: TextInputType.emailAddress, 
                      validator: (v) { 
                        if (v == null || v.isEmpty) return 'Obrigatório'; 
                        if (!v.contains('@')) return 'Email inválido'; 
                        return null; 
                      }),

                    if (_modoRegistro) ...[
                      const SizedBox(height: 8),
                      _field('Telefone / WhatsApp', _telefoneController, Icons.phone_android_rounded, '(00) 00000-0000', 
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null),
                    ],

                    if (_modoRegistro) ...[
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft, 
                        child: Text('Selecione sua Cidade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _cidadeSelecionada,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_city_rounded, color: AppColors.primaryTeal, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        items: context.watch<UsuarioProvider>().cidadesSuportadas.map((c) => DropdownMenuItem(value: c['codigo'], child: Text(c['nome']!))).toList(),
                        onChanged: (v) => setState(() => _cidadeSelecionada = v),
                        validator: (v) => v == null ? 'Selecione uma cidade' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      if (_roleSelecionada == 'ADMINISTRADOR')
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withAlpha(15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryTeal.withAlpha(50)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.primaryTeal, size: 32),
                              const SizedBox(height: 12),
                              const Text(
                                'Solicitação Manual Necessária',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                                                    const Text(
                                'Contas de administrador requerem aprovação manual. '
                                'Você pode criar sua conta agora e, se desejar agilizar o processo, envie um e-mail para:',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const SelectableText(
                                'reinaldoinfra07@gmail.com',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final Uri emailLaunchUri = Uri(
                                      scheme: 'mailto',
                                      path: 'reinaldoinfra07@gmail.com',
                                      query: 'subject=Solicitação de Acesso - ADMINISTRADOR&body=Olá, gostaria de solicitar acesso como ADMINISTRADOR da cidade de ...',
                                    );
                                    try {
                                      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o app de e-mail')));
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.email_outlined, size: 18),
                                  label: const Text('Enviar E-mail (Opcional)'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryTeal,
                                    side: const BorderSide(color: AppColors.primaryTeal),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],

                    _field('Senha', _senhaController, Icons.lock_rounded, 'Sua senha', 
                      obscure: !_senhaVisivel,
                      suffixIcon: IconButton(
                        icon: Icon(_senhaVisivel ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.textLight), 
                        onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel)
                      ),
                      validator: (v) { 
                        if (v == null || v.isEmpty) return 'Obrigatório'; 
                        if (v.length < 6) return 'Mínimo 6 caracteres'; 
                        return null; 
                      }),
                    
                    if (_modoRegistro) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: _concordaLGPD,
                            activeColor: AppColors.primaryTeal,
                            onChanged: (v) => setState(() => _concordaLGPD = v ?? false),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _mostrarTermos,
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  children: [
                                    TextSpan(text: 'Eu concordo com os '),
                                    TextSpan(
                                      text: 'Termos de Privacidade e LGPD',
                                      style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _carregando ? null : _enviar,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber, foregroundColor: AppColors.textOnAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 4, shadowColor: AppColors.accentAmber.withAlpha(100)),
                        child: _carregando ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(_modoRegistro ? 'Criar Conta' : 'Entrar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () { 
                        setState(() { 
                          _modoRegistro = !_modoRegistro; 
                          _formKey.currentState?.reset(); 
                          _emailController.clear(); 
                          _senhaController.clear(); 
                          _nomeController.clear(); 
                          _cidadeController.clear(); 
                        }); 
                      },
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14), 
                          children: [
                            TextSpan(text: _modoRegistro ? 'Já tem conta? ' : 'Não tem conta? ', style: const TextStyle(color: AppColors.textSecondary)),
                            TextSpan(text: _modoRegistro ? 'Entrar' : 'Criar conta', style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700)),
                          ]
                        )
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, String hint, {TextInputType? keyboardType, bool obscure = false, Widget? suffixIcon, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 2))]),
          child: TextFormField(controller: ctrl, keyboardType: keyboardType, obscureText: obscure,
            decoration: InputDecoration(hintText: hint, prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: Icon(icon, color: AppColors.primaryTeal, size: 20)), prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44), suffixIcon: suffixIcon, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), filled: true, fillColor: AppColors.surfaceCard),
            validator: validator),
        ),
      ]),
    );
  }

  @override
  void dispose() { 
    _emailController.dispose(); 
    _senhaController.dispose(); 
    _nomeController.dispose(); 
    _telefoneController.dispose();
    _cidadeController.dispose(); 
    super.dispose(); 
  }
}
