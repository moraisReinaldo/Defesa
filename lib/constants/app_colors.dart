import 'package:flutter/material.dart';

/// Design system de cores do app Defesa em Foco.
/// Paleta: Azul institucional + Laranja de destaque (Defesa Civil).
class AppColors {
  // === Cores Primárias (Azul Defesa Civil) ===
  static const Color primaryTeal = Color(0xFF0D47A1);
  static const Color primaryTealDark = Color(0xFF082E6A);
  static const Color primaryTealLight = Color(0xFF1565C0);

  // === Design System Moderno (Centro de Comando & Anti-Slop) ===
  static const Color navyDeep = Color(0xFF0A192F);
  static const Color navySidebar = Color(0xFF0B192E);
  static const Color navyCard = Color(0xFF112240);
  static const Color navyActive = Color(0xFF1E3A5F);
  static const Color navyBorder = Color(0xFF1F3556);

  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // === Cores Accent (Laranja Defesa Civil) ===
  static const Color accentAmber = Color(0xFFFF6D00);
  static const Color accentAmberLight = Color(0xFFFFB74D);
  static const Color accentAmberDark = Color(0xFFE65100);

  // === Background ===
  static const Color backgroundOffWhite = Color(0xFFF8FAFC);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // === Textos ===
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // === Status ===
  static const Color statusActive = Color(0xFFEF4444);
  static const Color statusEnRoute = Color(0xFFF59E0B);
  static const Color statusResolved = Color(0xFF10B981);

  // === Outros ===
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color shadowColor = Color(0x0D000000);
  static const Color shimmer = Color(0xFFE2E8F0);

  // === Gradientes ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF0A192F)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentAmber, accentAmberDark],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
  );

  // === Cores por Tipo de Ocorrência ===
  static const Map<String, Color> tipoColors = {
    'alagamento': Color(0xFF3B82F6),
    'deslizamento': Color(0xFF8B5CF6),
    'queda_arvore': Color(0xFF22C55E),
    'incendio_vegetacao': Color(0xFFEF4444),
    'colapso_estrutural': Color(0xFF6B7280),
    'vazamento_perigoso': Color(0xFFF59E0B),
    'tempestade': Color(0xFF6366F1),
    'animais_peconhentos': Color(0xFF9333EA),
    'obstrucao_via': Color(0xFF475569),
    'outro': Color(0xFF14B8A6),
  };

  static const Map<String, Color> tipoColorsLight = {
    'alagamento': Color(0xFFDBEAFE),
    'deslizamento': Color(0xFFEDE9FE),
    'queda_arvore': Color(0xFFDCFCE7),
    'incendio_vegetacao': Color(0xFFFEE2E2),
    'colapso_estrutural': Color(0xFFF3F4F6),
    'vazamento_perigoso': Color(0xFFFEF3C7),
    'tempestade': Color(0xFFE0E7FF),
    'animais_peconhentos': Color(0xFFF3E8FF),
    'obstrucao_via': Color(0xFFF1F5F9),
    'outro': Color(0xFFCCFBF1),
  };

  static Color getTipoColor(String tipo) => tipoColors[tipo] ?? accentAmber;
  static Color getTipoColorLight(String tipo) =>
      tipoColorsLight[tipo] ?? accentAmberLight;
}
