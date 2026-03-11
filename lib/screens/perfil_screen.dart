import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
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
      builder: (context, usuarioProvider, _) {
        // Se não houver usuário comum logado e também não for admin,
        // mostrar tela de login/registro.
        if (!usuarioProvider.estaLogado && !usuarioProvider.isAdmin) {
          return _construirTelaDeslogado(context, usuarioProvider);
        }

        // Se for admin (mesmo sem usuário comum), mostrar estado administrativo
        if (usuarioProvider.isAdmin && !usuarioProvider.estaLogado) {
          return _construirTelaAdmin(context, usuarioProvider);
        }

        final usuario = usuarioProvider.usuarioLogado!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: Text(
                      usuario.nome.isNotEmpty
                          ? usuario.nome[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Informações do Usuário
              Text(
                'Informações Pessoais',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Nome
              Text(
                'Nome',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              if (_editando)
                TextField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(usuario.nome),
                ),
              const SizedBox(height: 16),

              // Email
              Text(
                'Email',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(usuario.email),
              ),
              const SizedBox(height: 16),

              // Telefone
              Text(
                'Telefone',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              if (_editando)
                TextField(
                  controller: _telefoneController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(usuario.telefone),
                ),
              const SizedBox(height: 24),

              // Botões de Ação
              if (_editando)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final sucesso =
                              await usuarioProvider.atualizarPerfil(
                            nome: _nomeController.text,
                            telefone: _telefoneController.text,
                          );

                          if (sucesso && mounted) {
                            setState(() {
                              _editando = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Perfil atualizado com sucesso'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text('Salvar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _editando = false;
                            _nomeController.text = usuario.nome;
                            _telefoneController.text = usuario.telefone;
                          });
                        },
                        child: const Text('Cancelar'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _editando = true;
                      });
                    },
                    child: const Text('Editar Perfil'),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await usuarioProvider.logout();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Desconectado com sucesso'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirTelaDeslogado(
    BuildContext context,
    UsuarioProvider usuarioProvider,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Você não está conectado',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Faça login para acompanhar suas ocorrências e acessar recursos especiais',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final resultado = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                  if (resultado == true && mounted) {
                    setState(() {});
                  }
                },
                child: const Text('Entrar'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final resultado = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(modoRegistro: true),
                    ),
                  );
                  if (resultado == true && mounted) {
                    setState(() {});
                  }
                },
                child: const Text('Criar Conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Widget _construirTelaAdmin(
    BuildContext context,
    UsuarioProvider usuarioProvider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Logado como administrador',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await usuarioProvider.logout();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Administrador deslogado'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
