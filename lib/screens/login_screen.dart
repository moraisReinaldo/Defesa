import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/usuario_provider.dart';

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
  bool _senhaVisivel = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _modoRegistro = widget.modoRegistro;
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    try {
      final prov = context.read<UsuarioProvider>();
      bool ok;

      if (_modoRegistro) {
        ok = await prov.cadastrar(
          nome: _nomeController.text,
          email: _emailController.text,
          telefone: _telefoneController.text,
          senha: _senhaController.text,
        );
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Cadastro realizado! ✅'),
              backgroundColor: AppColors.statusResolved));
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Email já cadastrado'),
              backgroundColor: AppColors.statusActive));
        }
      } else {
        ok = await prov.login(
            email: _emailController.text, senha: _senhaController.text);
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
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
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
                    if (_modoRegistro) _field('Telefone', _telefoneController, Icons.phone_rounded, '(11) 99999-9999', keyboardType: TextInputType.phone, validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null),
                    _field('Senha', _senhaController, Icons.lock_rounded, 'Sua senha', obscure: !_senhaVisivel,
                        suffixIcon: IconButton(icon: Icon(_senhaVisivel ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.textLight), onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel)),
                        validator: (v) { if (v == null || v.isEmpty) return 'Obrigatório'; if (v.length < 6) return 'Mínimo 6 caracteres'; return null; }),
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
                    if (!_modoRegistro) TextButton.icon(icon: const Icon(Icons.admin_panel_settings_rounded, size: 18), label: const Text('Entrar como Administrador'), onPressed: () async {
                      final senha = await showDialog<String>(context: context, builder: (_) => const _SenhaAdminDialog());
                      if (senha != null) {
                        final auth = await context.read<UsuarioProvider>().autenticarAdmin(senha);
                        if (auth && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin! 🔑'), backgroundColor: AppColors.statusResolved)); Navigator.pop(context, true); }
                        else if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha incorreta'), backgroundColor: AppColors.statusActive)); }
                      }
                    }),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () { setState(() { _modoRegistro = !_modoRegistro; _formKey.currentState?.reset(); _emailController.clear(); _senhaController.clear(); _nomeController.clear(); _telefoneController.clear(); }); },
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
          decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: const Offset(0, 2))]),
          child: TextFormField(controller: ctrl, keyboardType: keyboardType, obscureText: obscure,
            decoration: InputDecoration(hintText: hint, prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: Icon(icon, color: AppColors.primaryTeal, size: 20)), prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44), suffixIcon: suffixIcon, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), filled: true, fillColor: AppColors.surfaceCard),
            validator: validator),
        ),
      ]),
    );
  }

  @override
  void dispose() { _emailController.dispose(); _senhaController.dispose(); _nomeController.dispose(); _telefoneController.dispose(); super.dispose(); }
}

class _SenhaAdminDialog extends StatefulWidget {
  const _SenhaAdminDialog();
  @override
  State<_SenhaAdminDialog> createState() => _SenhaAdminDialogState();
}

class _SenhaAdminDialogState extends State<_SenhaAdminDialog> {
  final _controller = TextEditingController();
  bool _vis = false;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryTeal, size: 22)),
        const SizedBox(width: 12),
        const Text('Administrador', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ]),
      content: TextField(controller: _controller, obscureText: !_vis,
        decoration: InputDecoration(hintText: 'Senha de administrador', prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primaryTeal, size: 20),
          suffixIcon: IconButton(icon: Icon(_vis ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.textLight), onPressed: () => setState(() => _vis = !_vis))),
        onSubmitted: (_) => Navigator.of(context).pop(_controller.text)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(_controller.text), child: const Text('Entrar')),
      ],
    );
  }
}
