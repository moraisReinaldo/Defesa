import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/usuario_provider.dart';
import '../providers/ocorrencia_provider.dart';
import 'mapa_screen.dart';
import 'historico_screen.dart';
import 'perfil_screen.dart';
import 'dashboard_relatorios_screen.dart';
import 'super_admin_screen.dart';
import 'login_screen.dart';
import 'gerenciar_poi_screen.dart';
import 'cadastro_agente_screen.dart';
import 'politica_privacidade_screen.dart';
import 'registro_ocorrencia_screen.dart';
import '../models/usuario.dart';

class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  int _selectedIndex = 0;

  Future<bool> _abrirModalLogin({bool modoRegistro = false}) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 820),
          decoration: BoxDecoration(
            color: AppColors.backgroundOffWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: LoginScreen(modoRegistro: modoRegistro),
        ),
      ),
    );
    if (!mounted) return false;
    return res == true || context.read<UsuarioProvider>().estaLogado;
  }

  Future<void> _onRegistrarOcorrenciaSidebar(UsuarioProvider userProv) async {
    if (!userProv.estaLogado) {
      final acao = await showDialog<String>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_person_rounded, size: 34, color: AppColors.primaryTeal),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Login Necessário',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Para registrar uma ocorrência pela Web e acompanhar o atendimento da Defesa Civil em tempo real, entre na sua conta ou crie um cadastro gratuito.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'login'),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Entrar na Conta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'registro'),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Criar Conta Gratuita'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                      side: const BorderSide(color: AppColors.primaryTeal),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Agora não', style: TextStyle(color: AppColors.textLight)),
                ),
              ],
            ),
          ),
        ),
      );

      if (!mounted || acao == null) return;
      final logou = await _abrirModalLogin(modoRegistro: acao == 'registro');
      if (!logou || !mounted) return;
    }

    if (!mounted) return;
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 850),
          decoration: BoxDecoration(
            color: AppColors.backgroundOffWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => const SelecaoTipoOcorrenciaScreen(),
            ),
          ),
        ),
      ),
    );

    if (res == true && mounted) {
      final ocProv = context.read<OcorrenciaProvider>();
      await ocProv.carregarOcorrencias(
        cidade: userProv.cidadeAtiva,
        userId: userProv.usuarioLogado?.id,
        isAdmin: userProv.isAdmin,
      );
      setState(() => _selectedIndex = 0);
    }
  }

  Widget _buildContent(UsuarioProvider userProv) {
    final isGestor = userProv.isAdmin || userProv.isAgente || userProv.isSuperAdmin;

    switch (_selectedIndex) {
      case 0:
        return const MapaScreen(isWebDashboard: true);
      case 1:
        return const HistoricoScreen();
      case 2:
        return const PerfilScreen();
      case 3:
        if (isGestor) return const DashboardRelatoriosScreen();
        return const MapaScreen(isWebDashboard: true);
      case 4:
        if (isGestor) return const GerenciarPOIScreen();
        return const MapaScreen(isWebDashboard: true);
      case 5:
        if (userProv.isAdmin || userProv.isSuperAdmin) {
          return const CadastroAgenteScreen();
        }
        return const Center(child: Text('Acesso Negado'));
      case 6:
        if (userProv.isSuperAdmin) {
          return const SuperAdminScreen();
        }
        return const Center(child: Text('Acesso Negado'));
      case 7:
        return const PoliticaPrivacidadeScreen();
      default:
        return const MapaScreen(isWebDashboard: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UsuarioProvider>();
    final usuario = userProv.usuarioLogado;
    final estaLogado = userProv.estaLogado && usuario != null;
    final isGestor = userProv.isAdmin || userProv.isAgente || userProv.isSuperAdmin;

    final nomeUsuario = usuario?.nome ?? 'Visitante';
    final roleNome = !estaLogado
        ? 'Acesso Público'
        : usuario.role == Role.superAdmin
            ? 'Super Admin'
            : usuario.role == Role.administrador
                ? 'Coordenador'
                : usuario.role == Role.agente
                    ? 'Agente'
                    : 'Cidadão';

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: Row(
        children: [
          // Sidebar de Centro de Operações & Portal Web Autossustentável
          Container(
            width: 270,
            decoration: const BoxDecoration(
              color: AppColors.navySidebar,
              border: Border(
                right: BorderSide(color: AppColors.navyBorder, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),

                // Topo da Sidebar: Logo & Título
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accentAmber, AppColors.accentAmberDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentAmber.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Defesa em Foco',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.statusResolved,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isGestor ? 'CICC Operacional' : 'Portal Web Oficial',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Botão Principal: Registrar Nova Ocorrência pela Web
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _onRegistrarOcorrenciaSidebar(userProv),
                      icon: const Icon(Icons.add_alert_rounded, size: 19),
                      label: const Text(
                        'Nova Ocorrência',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentAmber,
                        foregroundColor: AppColors.textOnAccent,
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Lista de Navegação Scrollável
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('PORTAL & MONITORAMENTO'),
                        const SizedBox(height: 6),
                        _buildNavItem(Icons.map_rounded, 'Mapa de Ocorrências', 0),
                        _buildNavItem(Icons.history_rounded, 'Histórico & Relatos', 1),
                        _buildNavItem(Icons.person_rounded, estaLogado ? 'Meu Perfil' : 'Entrar / Minha Conta', 2),

                        if (isGestor) ...[
                          const SizedBox(height: 18),
                          _buildSectionHeader('CENTRO DE OPERAÇÕES'),
                          const SizedBox(height: 6),
                          _buildNavItem(Icons.bar_chart_rounded, 'Painel & Relatórios', 3),
                          _buildNavItem(Icons.roofing_rounded, 'Abrigos & Rotas', 4),
                          if (userProv.isAdmin || userProv.isSuperAdmin)
                            _buildNavItem(Icons.badge_rounded, 'Equipe de Agentes', 5),
                          if (userProv.isSuperAdmin)
                            _buildNavItem(Icons.admin_panel_settings_rounded, 'Super Admin', 6),
                        ],

                        const SizedBox(height: 18),
                        _buildSectionHeader('INSTITUCIONAL'),
                        const SizedBox(height: 6),
                        _buildNavItem(Icons.verified_user_rounded, 'Privacidade & LGPD', 7),
                      ],
                    ),
                  ),
                ),

                // Rodapé: Card do Usuário Logado ou Botão de Login Rápido
                Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.navyCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.navyBorder),
                  ),
                  child: estaLogado
                      ? Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryTealLight,
                              child: Text(
                                nomeUsuario.isNotEmpty ? nomeUsuario[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    nomeUsuario,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    roleNome,
                                    style: const TextStyle(
                                      color: AppColors.accentAmberLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: AppColors.slate400, size: 20),
                              tooltip: 'Sair da Conta',
                              onPressed: () async {
                                await userProv.logout();
                                if (mounted) {
                                  setState(() => _selectedIndex = 0);
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_circle_outlined, color: AppColors.slate300, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Modo Visitante',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Faça login para registrar e acompanhar ocorrências na Web.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _abrirModalLogin(),
                                icon: const Icon(Icons.login_rounded, size: 16),
                                label: const Text('Entrar / Cadastrar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accentAmberLight,
                                  side: BorderSide(color: AppColors.accentAmber.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // Área Principal de Conteúdo
          Expanded(
            child: Container(
              color: AppColors.slate50,
              child: _buildContent(userProv),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.navyActive : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4), width: 1)
                  : Border.all(color: Colors.transparent, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.accentAmber : AppColors.slate400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.slate300,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13.5,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.accentAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
