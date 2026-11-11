import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class AcessibilidadeProvider extends ChangeNotifier {
  final HiveService _hiveService;
  bool _modoAltoContraste = false;
  double _escalaFonte = 1.0;

  AcessibilidadeProvider(this._hiveService) {
    _carregarPreferencias();
  }

  bool get modoAltoContraste => _modoAltoContraste;
  double get escalaFonte => _escalaFonte;

  void _carregarPreferencias() {
    _modoAltoContraste = _hiveService.altoContraste;
    _escalaFonte = _modoAltoContraste ? 1.15 : 1.0;
    notifyListeners();
  }

  Future<void> alternarAltoContraste() async {
    _modoAltoContraste = !_modoAltoContraste;
    _escalaFonte = _modoAltoContraste ? 1.15 : 1.0;
    await _hiveService.salvarAltoContraste(_modoAltoContraste);
    notifyListeners();
  }

  ThemeData get temaAltoContraste {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000), // Preto absoluto
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFD700), // Amarelo de alto contraste
        secondary: Color(0xFF00E5FF), // Ciano de alto contraste
        surface: Color(0xFF141414),
        error: Color(0xFFFF1744),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000),
        foregroundColor: Color(0xFFFFD700),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFFFD700),
        thickness: 1.5,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
