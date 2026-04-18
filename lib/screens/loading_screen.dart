import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
    
    // Sequência de Inicialização Crítica e Bloqueante
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProv = context.read<UsuarioProvider>();
      
      // 1. Permissões (Pilar 1)
      await _solicitarPermissoesIniciais();
      
      if (mounted) {
        // 2. Carga Base: Cidades e Sessão (Pilar 2)
        // Isso garante que temos a lista de cidades suportadas para o 'match' do GPS
        await userProv.carregarTudo();
        
        // 3. Contexto Geográfico (Pilar 3)
        // Só tentamos o GPS se não houver um usuário logado (que já tem cidade no perfil)
        if (userProv.usuarioLogado == null) {
          setState(() {
            _mensagem = 'Localizando sua região...';
            _subMensagem = 'Isolando ocorrências próximas';
          });
          await userProv.determinarCidadePorGps();
        }
        
        // FIM: A UI reagirá ao 'estaInicializado' setado no final do carregarTudo
        // ou podemos forçar um notify se necessário.
      }
    });
  }

  Future<void> _solicitarPermissoesIniciais() async {
    setState(() {
      _mensagem = 'Verificando acesso...';
      _subMensagem = 'Preparando sua localização';
    });

    try {
      // Solicita em bloco as permissões essenciais
      await [
        Permission.location,
        Permission.camera,
        Permission.notification,
        Permission.photos,
      ].request();
      
      // Removemos o Future.delayed fixo para acelerar a resposta
    } catch (e) {
      debugPrint('Erro ao solicitar permissões: $e');
    }
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
