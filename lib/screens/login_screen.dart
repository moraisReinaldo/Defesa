import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/usuario_provider.dart';
import '../services/api_service.dart';

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
  bool _senhaVisivel = false;
  bool _carregando = false;
  String _roleSelecionada = 'CIDADAO'; 

  @override
  void initState() {
    super.initState();
    _modoRegistro = widget.modoRegistro;
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
      bool ok;

      if (_modoRegistro) {
        final result = await prov.cadastrar(
          UsuarioRequest(
            nome: _nomeController.text,
            email: _emailController.text,
            telefone: _telefoneController.text,
            senha: _senhaController.text,
            cidade: _roleSelecionada == 'ADMINISTRADOR' ? _cidadeController.text : '', 
            role: _roleSelecionada,
            concordaLGPD: _concordaLGPD,
          ),
        );
        
        ok = result['sucesso'] ?? false;
        bool pendente = result['pendente'] ?? false;

        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(pendente 
                ? 'Cadastro realizado! Aguardando aprovação por e-mail. 📧' 
                : 'Cadastro realizado! Você já pode entrar. ✅'),
              backgroundColor: AppColors.statusResolved));
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['message'] ?? 'Erro ao cadastrar'),
              backgroundColor: AppColors.statusActive));
        }
      } else {
        ok = await prov.login(_emailController.text, _senhaController.text);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Login realizado! ✅'),
              backgroundColor: AppColors.statusResolved));
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Email ou senha incorretos'),
              backgroundColor: AppColors.statusActive));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: AppColors.statusActive));
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
          // Header gradiente
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
                              color: Colors.white.withOpacity(0.15),
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
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
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                ],
              ),
            ),
          ),
          // Form
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_modoRegistro) _field('Nome completo', _nomeController, Icons.person_rounded, 'Seu nome', validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null),
                    _field('Email', _emailController, Icons.email_rounded, 'seu@email.com', keyboardType: TextInputType.emailAddress, validator: (v) { if (v == null || v.isEmpty) return 'Obrigatório'; if (!v.contains('@')) return 'Email inválido'; return null; }),
                    if (_modoRegistro) ...[
                      _field('Telefone', _telefoneController, Icons.phone_rounded, '(11) 99999-9999', keyboardType: TextInputType.phone, validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null),
                      
                      const SizedBox(height: 8),
                      const Align(alignment: Alignment.centerLeft, child: Text('Tipo de Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Row(children: [
                        Flexible(child: RadioListTile<String>(title: const Text('Cidadão', style: TextStyle(fontSize: 13)), value: 'CIDADAO', groupValue: _roleSelecionada, onChanged: (v) => setState(() => _roleSelecionada = v!), contentPadding: EdgeInsets.zero)),
                        Flexible(child: RadioListTile<String>(title: const Text('Admin', style: TextStyle(fontSize: 13)), value: 'ADMINISTRADOR', groupValue: _roleSelecionada, onChanged: (v) => setState(() => _roleSelecionada = v!), contentPadding: EdgeInsets.zero)),
                      ]),

                      if (_roleSelecionada == 'ADMINISTRADOR')
                        _field('Cidade de Atuação', _cidadeController, Icons.location_city_rounded, 'Ex: Rio de Janeiro', validator: (v) => v == null || v.isEmpty ? 'Obrigatório para Admin' : null),
                      const SizedBox(height: 8),
                    ],
                    _field('Senha', _senhaController, Icons.lock_rounded, 'Sua senha', obscure: !_senhaVisivel,
                        suffixIcon: IconButton(icon: Icon(_senhaVisivel ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.textLight), onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel)),
                        validator: (v) { if (v == null || v.isEmpty) return 'Obrigatório'; if (v.length < 6) return 'Mínimo 6 caracteres'; return null; }),
                    
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
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber, foregroundColor: AppColors.textOnAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 4, shadowColor: AppColors.accentAmber.withOpacity(0.4)),
                        child: _carregando ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(_modoRegistro ? 'Criar Conta' : 'Entrar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () { setState(() { _modoRegistro = !_modoRegistro; _formKey.currentState?.reset(); _emailController.clear(); _senhaController.clear(); _nomeController.clear(); _telefoneController.clear(); _cidadeController.clear(); }); },
                      child: RichText(text: TextSpan(style: const TextStyle(fontSize: 14), children: [
                        TextSpan(text: _modoRegistro ? 'Já tem conta? ' : 'Não tem conta? ', style: const TextStyle(color: AppColors.textSecondary)),
                        TextSpan(text: _modoRegistro ? 'Entrar' : 'Criar conta', style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700)),
                      ]))),
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
  void dispose() { _emailController.dispose(); _senhaController.dispose(); _nomeController.dispose(); _telefoneController.dispose(); _cidadeController.dispose(); super.dispose(); }
}
