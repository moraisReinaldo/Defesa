import 'package:flutter/material.dart';

/// Design system de cores do app Defesa em Foco.
/// Paleta: Azul institucional + Laranja de destaque (Defesa Civil).
class AppColors {
  // === Cores Primárias (Azul Defesa Civil) ===
  static const Color primaryTeal = Color(0xFF0D47A1);
  static const Color primaryTealDark = Color(0xFF082E6A);
  static const Color primaryTealLight = Color(0xFF1565C0);

  // === Cores Accent (Laranja Defesa Civil) ===
  static const Color accentAmber = Color(0xFFFF6D00);
  static const Color accentAmberLight = Color(0xFFFFB74D);
  static const Color accentAmberDark = Color(0xFFE65100);

  // === Background ===
  static const Color backgroundOffWhite = Color(0xFFF5F5F0);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // === Textos ===
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // === Status ===
  static const Color statusActive = Color(0xFFEF4444);
  static const Color statusEnRoute = Color(0xFFF59E0B);
  static const Color statusResolved = Color(0xFF22C55E);

  // === Outros ===
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color shadowColor = Color(0x1A000000);
  static const Color shimmer = Color(0xFFE8E8E8);

  // === Gradientes ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryTealDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentAmber, accentAmberDark],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryTeal, primaryTealLight],
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
