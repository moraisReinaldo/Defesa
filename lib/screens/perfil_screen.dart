import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/usuario_provider.dart';
import 'login_screen.dart';
import 'cadastro_agente_screen.dart';
import 'gerenciar_poi_screen.dart';
import 'loading_screen.dart';

class PerfilScreen extends StatefulWidget {
   const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  final TextEditingController _emailPromoController = TextEditingController();
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<UsuarioProvider>().usuarioLogado;
    _nomeController = TextEditingController(text: usuario?.nome ?? '');
    _telefoneController = TextEditingController(text: usuario?.telefone ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UsuarioProvider>(
      builder: (context, prov, _) {
        if (!prov.estaLogado && !prov.isAdmin) {
          return _buildDeslogado(context);
        }
        if (prov.isAdmin && !prov.estaLogado) {
          return _buildAdmin(context, prov);
        }

        if (prov.usuarioLogado == null) {
          return  const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final usuario = prov.usuarioLogado!;

        return Scaffold(
          backgroundColor: AppColors.backgroundOffWhite,
          appBar: AppBar(
            title: const Text('Meu Perfil'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentAmber,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset:  const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      usuario.nome.isNotEmpty
                          ? usuario.nome[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  usuario.nome,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  usuario.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Row(
                        children: [
                          Icon(Icons.person_rounded,
                              color: AppColors.primaryTeal, size: 20),
                          SizedBox(width: 8),
                          Text('Informações Pessoais',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Nome
                      _buildInfoField(
                        label: 'Nome',
                        icon: Icons.badge_rounded,
                        editing: _editando,
                        controller: _nomeController,
                        value: usuario.nome,
                      ),
                      const SizedBox(height: 14),

                      // Email (read-only)
                      _buildInfoField(
                        label: 'Email',
                        icon: Icons.email_rounded,
                        editing: false,
                        value: usuario.email,
                      ),
                      const SizedBox(height: 14),

                      // Telefone
                      if (!prov.isAdmin) ...[
                        _buildInfoField(
                          label: 'Telefone',
                          icon: Icons.phone_rounded,
                          editing: _editando,
                          controller: _telefoneController,
                          value: usuario.telefone,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Cidade (Mapeada de ID para Nome)
                      _buildInfoField(
                        label: 'Cidade',
                        icon: Icons.location_city_rounded,
                        editing: false, // Por enquanto não permite editar cidade aqui para evitar desalinhamento com o cadastro
                        value: prov.cidadesSuportadas.firstWhere(
                          (c) => c['codigo'] == usuario.cidade,
                          orElse: () => {'nome': usuario.cidade ?? 'Não informada'},
                        )['nome']!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Seção Administrativa (Sempre mostrar se for ADMIN)
                if (prov.isAdmin)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         const Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                color: AppColors.primaryTeal, size: 20),
                            SizedBox(width: 8),
                            Text('Administração',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>  const CadastroAgenteScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.group_add_rounded, size: 18),
                            label: const Text('Cadastrar Agentes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>  const GerenciarPOIScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_rounded, size: 18),
                            label: const Text('Gerenciar Pontos de Apoio'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryTeal,
                              side:  const BorderSide(color: AppColors.primaryTeal),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 32),
                        const Text('Promover Usuário a Agente', 
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emailPromoController,
                                decoration: InputDecoration(
                                  hintText: 'E-mail do cidadão...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.primaryTeal.withAlpha(50)),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () => _promoverUsuario(prov),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              style: IconButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 0),

                // Botões
                if (_editando)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await prov.atualizarPerfil(
                              nome: _nomeController.text,
                              telefone: _telefoneController.text,
                            );
                            if (!context.mounted) return;
                            if (ok) {
                              setState(() => _editando = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Perfil atualizado! ✅'),
                                  backgroundColor: AppColors.statusResolved,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Salvar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusResolved,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _editando = false;
                              _nomeController.text = usuario.nome;
                              _telefoneController.text = usuario.telefone;
                            });
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _editando = true),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Editar Perfil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentAmber,
                        foregroundColor: AppColors.textOnAccent,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await prov.logout();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Desconectado')),
                      );
                      
                      // IMPORTANTE: Força a recriação do LoadingScreen para rodar o initState
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoadingScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sair'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusActive,
                      side: const BorderSide(color: AppColors.statusActive),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoField({
    required String label,
    required IconData icon,
    required bool editing,
    TextEditingController? controller,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight)),
        const SizedBox(height: 6),
        if (editing && controller != null)
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundOffWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, size: 18, color: AppColors.primaryTeal),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.backgroundOffWhite,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundOffWhite,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryTeal),
                const SizedBox(width: 12),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textPrimary)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDeslogado(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(title: const Text('Perfil')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_circle_rounded,
                    size: 60, color: AppColors.primaryTeal),
              ),
              const SizedBox(height: 24),
              const Text('Você não está conectado',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                  'Faça login para acompanhar suas ocorrências e recursos especiais',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final r = await Navigator.push<bool>(context,
                        MaterialPageRoute(builder: (_) =>  const LoginScreen()));
                    if (r == true && mounted) setState(() {});
                  },
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text('Entrar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentAmber,
                    foregroundColor: AppColors.textOnAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final r = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                 const LoginScreen(modoRegistro: true)));
                    if (r == true && mounted) setState(() {});
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: const Text('Criar Conta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdmin(BuildContext context, UsuarioProvider prov) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(title: const Text('Perfil')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.accentAmber, width: 3),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('Administrador',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Modo administrador ativo',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>  const CadastroAgenteScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.group_add_rounded, size: 18),
                  label: const Text('Cadastrar Agentes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>  const GerenciarPOIScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('Gerenciar Pontos de Apoio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side:  const BorderSide(color: AppColors.primaryTeal),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await prov.logout();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Deslogado com sucesso')));
                    
                    // IMPORTANTE: Força a recriação do LoadingScreen para rodar o initState
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoadingScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sair'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusActive,
                    side: const BorderSide(color: AppColors.statusActive),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _promoverUsuario(UsuarioProvider prov) async {
    final email = _emailPromoController.text.trim();
    if (email.isEmpty) return;

    try {
      await prov.promoverParaAgente(email);
      if (mounted) {
        _emailPromoController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário promovido com sucesso! 🎉'),
            backgroundColor: AppColors.statusResolved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.statusActive,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailPromoController.dispose();
    super.dispose();
  }
}
