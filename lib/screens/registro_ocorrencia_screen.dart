import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/ocorrencia_tipos.dart';
import '../widgets/tipo_ocorrencia_card.dart';
import 'detalhes_ocorrencia_screen.dart'; // Tela do Passo 2 (a ser criada)

class SelecaoTipoOcorrenciaScreen extends StatefulWidget {
  const SelecaoTipoOcorrenciaScreen({super.key});

  @override
  State<SelecaoTipoOcorrenciaScreen> createState() =>
      _SelecaoTipoOcorrenciaScreenState();
}

class _SelecaoTipoOcorrenciaScreenState
    extends State<SelecaoTipoOcorrenciaScreen> {
  String? _tipoSelecionado;

  @override
  Widget build(BuildContext context) {
    final tipos = OcorrenciaTipos.getTiposLista();

    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        title: const Text("Nova Ocorrência"),
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
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.category_rounded,
                      size: 18, color: AppColors.primaryTeal),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passo 1: Tipo de Ocorrência',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Selecione uma categoria para começar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: tipos.length,
              itemBuilder: (context, index) {
                final tipo = tipos[index];
                return TipoOcorrenciaCard(
                  tipo: tipo,
                  selected: _tipoSelecionado == tipo,
                  onTap: () {
                    setState(() {
                      _tipoSelecionado = tipo;
                    });
                    
                    Future.delayed(const Duration(milliseconds: 150), () async {
                      // Navigate (Push) to Step 2
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalhesOcorrenciaScreen(
                            tipoOcorrencia: tipo,
                          ),
                        ),
                      );

                      if (result == true && mounted) {
                        Navigator.pop(context, true); // Pop out to map
                      }
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}