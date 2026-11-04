import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/usuario_provider.dart';
import 'mapa_screen.dart';
import 'dashboard_relatorios_screen.dart';
import 'super_admin_screen.dart';
import 'login_screen.dart';
import 'gerenciar_poi_screen.dart';
import 'cadastro_agente_screen.dart';
import 'politica_privacidade_screen.dart';
import '../models/usuario.dart';

class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  int _selectedIndex = 0;

  Widget _buildContent(UsuarioProvider userProv) {
    if (!userProv.estaLogado || userProv.usuarioLogado?.role == Role.cidadao) {
      return const LoginScreen();
    }

    switch (_selectedIndex) {
      case 0:
        return const MapaScreen(isWebDashboard: true);
      case 1:
        return const DashboardRelatoriosScreen();
      case 2:
        return const GerenciarPOIScreen();
      case 3:
        if (userProv.isAdmin || userProv.isSuperAdmin) {
          return const CadastroAgenteScreen();
        }
        return const Center(child: Text('Acesso Negado'));
      case 4:
        if (userProv.isSuperAdmin) {
          return const SuperAdminScreen();
        }
        return const Center(child: Text('Acesso Negado'));
      case 5:
        return const PoliticaPrivacidadeScreen();
      default:
        return const MapaScreen(isWebDashboard: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UsuarioProvider>();

    if (!userProv.estaLogado || userProv.usuarioLogado?.role == Role.cidadao) {
      return const Scaffold(
        body: LoginScreen(),
      );
    }

    final usuario = userProv.usuarioLogado;
    final nomeUsuario = usuario?.nome ?? 'Operador';
    final roleNome = usuario?.role == Role.superAdmin
        ? 'Super Admin'
        : (usuario?.role == Role.administrador ? 'Coordenador' : 'Agente');

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: Row(
        children: [
          // Sidebar de Centro de Operações (Anti-Slop / Professional SaaS)
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
                const SizedBox(height: 24),

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
                                  'CICC Operacional',
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

                const SizedBox(height: 28),

                // Seção: OPERAÇÕES
                _buildSectionHeader('OPERAÇÕES AO VIVO'),
                const SizedBox(height: 6),
                _buildNavItem(Icons.map_rounded, 'Mapa de Ocorrências', 0),
                _buildNavItem(Icons.bar_chart_rounded, 'Painel & Relatórios', 1),
                _buildNavItem(Icons.roofing_rounded, 'Abrigos & Rotas', 2),

                const SizedBox(height: 20),

                // Seção: GESTÃO & EQUIPE
                _buildSectionHeader('GESTÃO & SISTEMA'),
                const SizedBox(height: 6),
                if (userProv.isAdmin || userProv.isSuperAdmin)
                  _buildNavItem(Icons.badge_rounded, 'Equipe de Agentes', 3),
                if (userProv.isSuperAdmin)
                  _buildNavItem(Icons.admin_panel_settings_rounded, 'Super Admin', 4),
                _buildNavItem(Icons.verified_user_rounded, 'Privacidade & LGPD', 5),

                const Spacer(),

                // Rodapé: Card do Usuário Logado
                Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.navyCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.navyBorder),
                  ),
                  child: Row(
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
                        tooltip: 'Sair do Sistema',
                        onPressed: () => userProv.logout(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
