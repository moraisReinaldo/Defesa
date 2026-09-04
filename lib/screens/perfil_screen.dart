import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_pagamentos.dart';
import '../providers/usuario_provider.dart';
import 'login_screen.dart';
import 'cadastro_agente_screen.dart';
import 'gerenciar_poi_screen.dart';
import 'loading_screen.dart';
import '../widgets/responsive_layout.dart';
import 'dashboard_relatorios_screen.dart';
import '../models/usuario.dart';
import '../providers/cidade_provider.dart';

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
          body: ResponsiveContainer(
            maxWidth: ResponsiveLayout.isDesktop(context) ? 1000 : 600,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ResponsiveLayout.isDesktop(context) && prov.isAdmin
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildHeader(usuario),
                              const SizedBox(height: 28),
                              _buildInfoCard(prov, usuario),
                              const SizedBox(height: 16),
                              _buildCardVitalicio(prov, usuario),
                              const SizedBox(height: 24),
                              _buildActionButtons(prov, usuario),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 1,
                          child: _buildAdminCard(prov),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildHeader(usuario),
                        const SizedBox(height: 28),
                        _buildInfoCard(prov, usuario),
                        const SizedBox(height: 16),
                        _buildCardVitalicio(prov, usuario),
                        const SizedBox(height: 16),
                        if (prov.isAdmin) ...[
                          _buildAdminCard(prov),
                          const SizedBox(height: 16),
                        ],
                        _buildActionButtons(prov, usuario),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Usuario usuario) {
    return Column(
      children: [
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
                offset: const Offset(0, 6),
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
      ],
    );
  }

  Widget _buildInfoCard(UsuarioProvider prov, Usuario usuario) {
    return Container(
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
          _buildInfoField(
            label: 'Nome',
            icon: Icons.badge_rounded,
            editing: _editando,
            controller: _nomeController,
            value: usuario.nome,
          ),
          const SizedBox(height: 14),
          _buildInfoField(
            label: 'Email',
            icon: Icons.email_rounded,
            editing: false,
            value: usuario.email,
          ),
          const SizedBox(height: 14),
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
          _buildInfoField(
            label: 'Cidade',
            icon: Icons.location_city_rounded,
            editing: false,
            value: prov.cidadesSuportadas.firstWhere(
              (c) => c['codigo'] == usuario.cidade,
              orElse: () => {'nome': usuario.cidade ?? 'Não informada'},
            )['nome']!,
          ),
        ],
      ),
    );
  }

  Widget _buildCardVitalicio(UsuarioProvider prov, Usuario usuario) {
    final bool isVitalicio = prov.isSemAnunciosVitalicio;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVitalicio
              ? [Colors.teal.shade50, Colors.amber.shade50]
              : [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVitalicio ? Colors.teal.shade400 : Colors.amber.shade400,
          width: 1.5,
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isVitalicio ? Colors.teal.shade100 : Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isVitalicio ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                  color: isVitalicio ? Colors.teal.shade800 : Colors.amber.shade900,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVitalicio ? 'Licença Vitalícia Ativa' : 'Remover Anúncios para Sempre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isVitalicio ? Colors.teal.shade900 : Colors.brown.shade900,
                      ),
                    ),
                    Text(
                      isVitalicio
                          ? 'Zero anúncios em qualquer município'
                          : 'Pagamento único • Válido para sempre',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isVitalicio ? Colors.teal.shade700 : Colors.brown.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isVitalicio ? Colors.teal.shade600 : Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isVitalicio ? 'VITALÍCIO' : 'VÁLIDO P/ SEMPRE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isVitalicio
                ? 'Sua conta está vinculada permanentemente ao plano sem anúncios. Você nunca mais verá propagandas no Defesa em Foco, independente da cidade em que estiver.'
                : 'Garanta navegação limpa e sem interrupções em todo o país. O benefício é permanente e fica gravado na sua conta e dispositivo para você nunca perder.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isVitalicio ? Colors.teal.shade900 : Colors.brown.shade900,
            ),
          ),
          const SizedBox(height: 16),
          if (!isVitalicio) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF635BFF), // Cor do Stripe
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () {
                  final email = usuario.email;
                  final url = '${AppPagamentos.stripeLinkVitalicioSemAnuncios}?prefilled_email=${Uri.encodeComponent(email)}';
                  launchUrl(Uri.parse(url));
                },
                icon: const Icon(Icons.credit_card_rounded, size: 20),
                label: const Text(
                  'Adquirir Licença Vitalícia no Stripe',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await prov.ativarAcessoVitalicio();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? '⭐ Licença Vitalícia ativada com sucesso! Você nunca mais verá anúncios.'
                            : '❌ Nenhum pagamento aprovado no Stripe foi encontrado para o seu e-mail (${usuario.email}). Conclua o pagamento pelo botão acima antes de ativar.'),
                        backgroundColor: ok ? Colors.green : Colors.redAccent.shade700,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.sync_rounded, size: 16, color: Colors.blueGrey),
                label: const Text(
                  'Já realizou o pagamento no Stripe? Clique para ativar',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Vinculado ao seu perfil: ${usuario.email}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminCard(UsuarioProvider prov) {
    return Container(
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
                    builder: (_) => const CadastroAgenteScreen(),
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
                    builder: (_) => const GerenciarPOIScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Gerenciar Pontos de Apoio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                side: const BorderSide(color: AppColors.primaryTeal),
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
                    builder: (_) => const DashboardRelatoriosScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_rounded, size: 18),
              label: const Text('Ver Dashboard de Relatórios'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
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
            child: ElevatedButton.icon(
              onPressed: () {
                final cidadeNome = context.read<CidadeProvider>().cidadeAtiva?.nome ?? 'Defesa Civil';
                final url = AppPagamentos.obterUrlWhatsApp(
                  cidadeNome: cidadeNome,
                  motivo: 'Olá Reinaldo, sou gestor da Defesa Civil de $cidadeNome e gostaria de suporte para a plataforma Defesa em Foco.',
                );
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.support_agent_rounded, size: 20),
              label: const Text('Falar com Suporte (WhatsApp Oficial)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
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
    );
  }

  Widget _buildActionButtons(UsuarioProvider prov, Usuario usuario) {
    return Column(
      children: [
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoadingScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sair da Conta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textLight,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _confirmarExclusaoConta(prov),
            icon: Icon(Icons.delete_forever_rounded, size: 18, color: Colors.red.shade700),
            label: const Text('Excluir minha conta'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
          ),
        ),
      ],
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
      body: ResponsiveContainer(
        maxWidth: 600,
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
      body: ResponsiveContainer(
        maxWidth: 600,
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

  void _confirmarExclusaoConta(UsuarioProvider prov) {
    // Etapa 1: Aviso inicial
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 48),
        title: const Text('Excluir conta?'),
        content: const Text(
          'Esta ação é irreversível. Todos os seus dados pessoais serão removidos permanentemente.\n\n'
          'Suas ocorrências registradas serão mantidas de forma anônima para fins de histórico público.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmarExclusaoEtapa2(prov);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusaoEtapa2(UsuarioProvider prov) {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmação final', style: TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Para confirmar, digite EXCLUIR abaixo:',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'EXCLUIR',
                filled: true,
                fillColor: AppColors.backgroundOffWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                ),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (confirmController.text.trim().toUpperCase() != 'EXCLUIR') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Digite EXCLUIR para confirmar.'),
                    backgroundColor: AppColors.statusActive,
                  ),
                );
                return;
              }
              Navigator.pop(context); // Fecha diálogo
              await _executarExclusaoConta(prov);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir definitivamente'),
          ),
        ],
      ),
    );
  }

  Future<void> _executarExclusaoConta(UsuarioProvider prov) async {
    try {
      await prov.excluirMinhaConta();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta excluída com sucesso.'),
          backgroundColor: AppColors.statusResolved,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoadingScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir conta: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.statusActive,
        ),
      );
    }
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
