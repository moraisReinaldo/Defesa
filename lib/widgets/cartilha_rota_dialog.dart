import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class CartilhaRotaDialog extends StatelessWidget {
  const CartilhaRotaDialog({super.key});

  static void exibir(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CartilhaRotaDialog(),
    );
  }

  Future<void> _fazerLigacao(String numero) async {
    final uri = Uri.parse('tel:$numero');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 2),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.primaryTeal, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cartilha de Emergência R.O.T.A.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Guia rápido de sobrevivência • Defesa Civil',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mnemônico R.O.T.A.
            _buildPasso(
              letra: 'R',
              titulo: 'Reconhecer o Perigo',
              descricao: 'Fique atento a postes inclinados, trincas novas nas paredes, água subindo rapidamente ou cheiro forte de gás/fumaça.',
              icone: Icons.search_rounded,
              cor: Colors.amber.shade700,
            ),
            _buildPasso(
              letra: 'O',
              titulo: 'Observar os Arredores',
              descricao: 'Identifique rotas de fuga seguras e pontos de abrigo (POIs) cadastrados no app. Evite pontes baixas e áreas alagadas.',
              icone: Icons.visibility_rounded,
              cor: Colors.blue.shade600,
            ),
            _buildPasso(
              letra: 'T',
              titulo: 'Telefonar com Precisão',
              descricao: 'Ligue imediatamente antes do sinal cair. Informe o endereço exato, ponto de referência e se há feridos ou idosos.',
              icone: Icons.phone_in_talk_rounded,
              cor: Colors.deepOrange.shade600,
            ),
            _buildPasso(
              letra: 'A',
              titulo: 'Agir com Calma',
              descricao: 'Desligue chave geral de energia e registro de gás. Leve documentos essenciais e remédios. Siga a rota sinalizada.',
              icone: Icons.directions_run_rounded,
              cor: Colors.green.shade600,
            ),

            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 12),

            // Botões de Discagem Rápida
            const Text(
              'Telefones de Emergência Gratuitos (24 Horas):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _fazerLigacao('199'),
                    icon: const Icon(Icons.call, color: Colors.white, size: 18),
                    label: const Text('199 Defesa Civil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _fazerLigacao('193'),
                    icon: const Icon(Icons.fire_truck_rounded, color: Colors.white, size: 18),
                    label: const Text('193 Bombeiros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasso({
    required String letra,
    required String titulo,
    required String descricao,
    required IconData icone,
    required Color cor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              letra,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
