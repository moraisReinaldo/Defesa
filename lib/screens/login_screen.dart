import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';

class LoginScreen extends StatefulWidget {
  final bool modoRegistro;

  const LoginScreen({super.key, this.modoRegistro = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _modoRegistro;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _modoRegistro = widget.modoRegistro;
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final usuarioProvider = context.read<UsuarioProvider>();
      bool sucesso;

      if (_modoRegistro) {
        sucesso = await usuarioProvider.cadastrar(
          nome: _nomeController.text,
          email: _emailController.text,
          telefone: _telefoneController.text,
          senha: _senhaController.text,
        );

        if (sucesso && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cadastro realizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email já cadastrado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        sucesso = await usuarioProvider.login(
          email: _emailController.text,
          senha: _senhaController.text,
        );

        if (sucesso && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login realizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email ou senha incorretos'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modoRegistro ? 'Criar Conta' : 'Entrar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                _modoRegistro
                    ? 'Crie sua conta para acompanhar suas ocorrências'
                    : 'Entre com sua conta',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),

              // Nome (apenas no registro)
              if (_modoRegistro)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nome',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        hintText: 'Seu nome completo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return 'Digite seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Email
              Text(
                'Email',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'seu.email@exemplo.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Digite seu email';
                  }
                  if (!valor.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Telefone (apenas no registro)
              if (_modoRegistro)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telefone',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '(11) 99999-9999',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return 'Digite seu telefone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Senha
              Text(
                'Senha',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _senhaController,
                obscureText: !_senhaVisivel,
                decoration: InputDecoration(
                  hintText: 'Digite sua senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _senhaVisivel = !_senhaVisivel;
                      });
                    },
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Digite sua senha';
                  }
                  if (valor.length < 6) {
                    return 'Senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botão Enviar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _enviar,
                  child: _carregando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_modoRegistro ? 'Criar Conta' : 'Entrar'),
                ),
              ),
              const SizedBox(height: 16),

              // Botão administrador (modo especial)
              if (!_modoRegistro)
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final senha = await showDialog<String>(
                        context: context,
                        builder: (context) => _SenhaAdminDialog(),
                      );
                      if (senha != null) {
                        final auth = await context
                            .read<UsuarioProvider>()
                            .autenticarAdmin(senha);
                        if (auth && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Login como administrador!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context, true);
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Senha de administrador incorreta'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Entrar como Administrador'),
                  ),
                ),
              const SizedBox(height: 16),

              // Alternar entre Login e Registro
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _modoRegistro = !_modoRegistro;
                      _formKey.currentState?.reset();
                      _emailController.clear();
                      _senhaController.clear();
                      _nomeController.clear();
                      _telefoneController.clear();
                    });
                  },
                  child: Text(
                    _modoRegistro
                        ? 'Já tem conta? Entrar'
                        : 'Não tem conta? Criar',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }
}

// Diálogo simples para pedir senha de administrador
class _SenhaAdminDialog extends StatefulWidget {
  @override
  State<_SenhaAdminDialog> createState() => _SenhaAdminDialogState();
}

class _SenhaAdminDialogState extends State<_SenhaAdminDialog> {
  final _controller = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Senha de Administrador'),
      content: TextField(
        controller: _controller,
        obscureText: !_senhaVisivel,
        decoration: InputDecoration(
          hintText: 'Digite a senha',
          suffixIcon: IconButton(
            icon: Icon(
              _senhaVisivel ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _senhaVisivel = !_senhaVisivel;
              });
            },
          ),
        ),
        onSubmitted: (_) => Navigator.of(context).pop(_controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Entrar'),
        ),
      ],
    );
  }
}
