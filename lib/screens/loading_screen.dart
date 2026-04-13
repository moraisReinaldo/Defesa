import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/usuario_provider.dart';
import 'mapa_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _mensagem = 'Conectando ao servidor...';
  String _subMensagem = 'Preparando ambiente seguro';

  @override
  void initState() {
    super.initState();
    
    // Mostra mensagem amigável caso o servidor demore a ligar (Render free tier cold start)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !context.read<UsuarioProvider>().estaInicializado) {
        setState(() {
          _mensagem = 'Ligando o servidor...';
          _subMensagem = 'O servidor gratuito pode demorar até 50s para despertar. Aguarde!';
        });
      }
    });

    // Inicia a carga de dados assim que a tela abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioProvider>().carregarTudo();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Monitora o estado de inicialização
    final estaPronto = context.select<UsuarioProvider, bool>((p) => p.estaInicializado);

    if (estaPronto) {
      return const MapaScreen();
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Logo ou Ícone Central
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset('assets/images/defe.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 48),
            // Spinner Premium
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            // Mensagem de Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _subMensagem,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(flex: 2),
            // Créditos solicitados
            Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: Column(
                children: [
                  Text(
                    'Desenvolvido por',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Reinaldo Henrique Morais e Pedro Guedes de Azevedo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
