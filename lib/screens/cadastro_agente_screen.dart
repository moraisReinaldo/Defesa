import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geocoding/geocoding.dart';

import '../constants/app_colors.dart';
import '../providers/usuario_provider.dart';
import '../services/localizacao_service.dart';

class CadastroAgenteScreen extends StatefulWidget {
  const CadastroAgenteScreen({super.key});

  @override
  State<CadastroAgenteScreen> createState() => _CadastroAgenteScreenState();
}

class _CadastroAgenteScreenState extends State<CadastroAgenteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _especialidadeController = TextEditingController();

  final LocalizacaoService _localizacaoService = LocalizacaoService();
  bool _obtendoLocalizacao = false;
  bool _salvando = false;
  bool _senhaVisivel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioProvider>().carregarTudo();
    });
  }

  Future<void> _obterCidadePorLocalizacao() async {
    setState(() => _obtendoLocalizacao = true);
    try {
      final posicao = await _localizacaoService.obterPosicaoAtual();
      if (posicao != null) {
        final placemarks = await placemarkFromCoordinates(
          posicao.latitude,
          posicao.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final cidade = placemark.subAdministrativeArea ??
              placemark.locality ??
              placemark.administrativeArea ??
              'Desconhecida';

          setState(() {
            _cidadeController.text = cidade;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cidade detectada: $cidade'),
                backgroundColor: AppColors.statusResolved,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao obter localização: $e'),
            backgroundColor: AppColors.statusActive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _obtendoLocalizacao = false);
    }
  }

  Future<void> _salvarAgente() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final sucesso = await context.read<UsuarioProvider>().cadastrarAgente(
            nome: _nomeController.text.trim(),
            email: _emailController.text.trim(),
            telefone: _telefoneController.text.trim(),
            senha: _senhaController.text,
            cidade: _cidadeController.text.trim(),
            especialidade: _especialidadeController.text.trim(),
          );

      if (mounted) {
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agente cadastrado com sucesso!'),
              backgroundColor: AppColors.statusResolved,
            ),
          );
          _formKey.currentState!.reset();
          _nomeController.clear();
          _emailController.clear();
          _senhaController.clear();
          _telefoneController.clear();
          _cidadeController.clear();
          _especialidadeController.clear();
          FocusScope.of(context).unfocus();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro: Email já cadastrado ou erro no servidor.'),
              backgroundColor: AppColors.statusActive,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
            backgroundColor: AppColors.statusActive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        title: const Text('Cadastro de Agentes'),
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulário de Cadastro
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_add_rounded,
                            color: AppColors.primaryTeal, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Novo Agente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      'Nome Completo',
                      _nomeController,
                      Icons.badge_rounded,
                      'Ex: João da Silva',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'Email (Login)',
                      _emailController,
                      Icons.email_rounded,
                      'Ex: joao@defesa.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    // Campo de senha
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Senha de Acesso',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: !_senhaVisivel,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            if (value.length < 6) return 'Mín. 6 caracteres';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Senha temporária',
                            prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primaryTeal, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_senhaVisivel ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.primaryTeal),
                              onPressed: () {
                                setState(() {
                                  _senhaVisivel = !_senhaVisivel;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: AppColors.backgroundOffWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'Telefone',
                      _telefoneController,
                      Icons.phone_rounded,
                      'Ex: (11) 99999-9999',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'Especialidade / Cargo',
                      _especialidadeController,
                      Icons.work_rounded,
                      'Ex: Bombeiro, Eng. Civil',
                    ),
                    const SizedBox(height: 16),
                    // Campo de Cidade com Botão de GPS
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cidade de Atuação',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextFieldOnly(
                                _cidadeController,
                                Icons.location_city_rounded,
                                'Sua cidade',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 54, // Altura padrão do TextField
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                onPressed: _obtendoLocalizacao
                                    ? null
                                    : _obterCidadePorLocalizacao,
                                icon: _obtendoLocalizacao
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primaryTeal,
                                        ),
                                      )
                                    : const Icon(Icons.my_location_rounded,
                                        color: AppColors.primaryTeal),
                                tooltip: 'Obter cidade pelo GPS',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _salvando ? null : _salvarAgente,
                        icon: _salvando
                            ? const SizedBox()
                            : const Icon(Icons.save_rounded, size: 20),
                        label: _salvando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Cadastrar Agente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentAmber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Lista de Agentes Cadastrados
            const Text(
              'Agentes Cadastrados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<UsuarioProvider>(
              builder: (context, provider, _) {
                final agentes = provider.todosAgentes;
                if (agentes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.group_off_rounded,
                              size: 40, color: AppColors.textLight),
                          SizedBox(height: 12),
                          Text(
                            'Nenhum agente cadastrado.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: agentes.length,
                  itemBuilder: (context, index) {
                    final agente = agentes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.primaryTeal),
                        ),
                        title: Text(
                          agente.nome,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${agente.especialidade ?? "Geral"} • ${agente.cidade ?? "Sem local"}',
                                style: const TextStyle(fontSize: 12)),
                            Text(agente.telefone,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.statusActive),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Excluir agente'),
                                content: Text(
                                    'Deseja remover o agente ${agente.nome} (Usuário e Agente)?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.statusActive),
                                    onPressed: () {
                                      provider.deletarUsuario(agente.id);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextFieldOnly(controller, icon, hint, keyboardType: keyboardType),
      ],
    );
  }

  Widget _buildTextFieldOnly(
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Campo obrigatório';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryTeal, size: 20),
        filled: true,
        fillColor: AppColors.backgroundOffWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _telefoneController.dispose();
    _cidadeController.dispose();
    _especialidadeController.dispose();
    super.dispose();
  }
}
