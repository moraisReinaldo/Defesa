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
      // Força login para acessar o painel
      return const Scaffold(
        body: LoginScreen(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppColors.primaryTeal,
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.shield, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Defesa Em Foco',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Painel do Gestor',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildNavItem(Icons.map_rounded, 'Mapa ao Vivo', 0),
                _buildNavItem(Icons.analytics_rounded, 'Estatísticas', 1),
                _buildNavItem(Icons.location_city_rounded, 'Abrigos e POIs', 2),
                if (userProv.isAdmin || userProv.isSuperAdmin)
                  _buildNavItem(Icons.group_add_rounded, 'Equipe', 3),
                if (userProv.isSuperAdmin)
                  _buildNavItem(Icons.admin_panel_settings_rounded, 'Super Admin', 4),
                _buildNavItem(Icons.policy_rounded, 'Política de Privacidade', 5),
                  
                const Spacer(),
                
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.white70),
                  title: const Text('Sair', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    userProv.logout();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: Container(
              color: AppColors.backgroundOffWhite,
              child: ClipRRect(
                child: _buildContent(userProv),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black.withValues(alpha: 0.2) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.accentAmber : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.accentAmber : Colors.white70),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
