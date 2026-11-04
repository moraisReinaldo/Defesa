import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PoliticaPrivacidadeScreen extends StatelessWidget {
  final bool isRegistration;

  const PoliticaPrivacidadeScreen({super.key, this.isRegistration = false});

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: canPop
          ? AppBar(
              title: const Text('Política de Privacidade e LGPD'),
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com Badge LGPD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navySidebar, AppColors.primaryTealDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTealDark.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.accentAmberLight.withValues(alpha: 0.6)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, color: AppColors.accentAmberLight, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'LEI FEDERAL Nº 13.709/2018 (LGPD)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Termos de Uso e Política de Privacidade',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistema Integrado de Gestão de Riscos e Desastres — Defesa Civil em Foco. Transparência, proteção de dados dos cidadãos e segurança jurídica municipal.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Seções Estruturadas e Legíveis da LGPD
                _buildCard(
                  icon: Icons.shield_outlined,
                  title: '1. Finalidade e Base Legal',
                  content:
                      'O tratamento de dados pessoais realizado pela plataforma tem como base legal o cumprimento de obrigação legal ou regulatória pelo controlador municipal e a proteção da vida ou da incolumidade física do titular ou de terceiros (Art. 7º, incisos II e VII da Lei nº 13.709/2018).\n\nOs dados são utilizados exclusivamente para gerenciamento de ocorrências, alertas preventivos de desastres climáticos e coordenação de resgate pelas equipes da Defesa Civil.',
                ),

                _buildCard(
                  icon: Icons.fingerprint_rounded,
                  title: '2. Dados Coletados',
                  content:
                      '• Identificação: Nome completo, e-mail de contato e telefone para confirmação de emergência.\n'
                      '• Geolocalização: Coordenadas precisas (latitude e longitude) coletadas no momento da abertura do chamado para localização imediata da equipe de campo.\n'
                      '• Mídia: Fotografias anexadas pelo cidadão como evidência técnica da ocorrência (alagamentos, deslizamentos ou quedas de árvores).',
                ),

                _buildCard(
                  icon: Icons.lock_outline_rounded,
                  title: '3. Segurança e Armazenamento',
                  content:
                      'Todas as credenciais e tokens de acesso são transmitidos sob criptografia TLS 1.3 ponta a ponta e armazenados com hashing seguro (Argon2 / BCrypt).\n\nAs fotos de ocorrências são protegidas em bucket de armazenamento seguro (S3 Object Storage) com acesso autenticado e restrito aos coordenadores e agentes autorizados.',
                ),

                _buildCard(
                  icon: Icons.handshake_outlined,
                  title: '4. Compartilhamento Restrito',
                  content:
                      'A Defesa Civil em Foco não comercializa, não cede e não compartilha dados de usuários com empresas terceiras para fins publicitários.\n\nO compartilhamento ocorre unicamente com órgãos oficiais de socorro e segurança pública (Corpo de Bombeiros, SAMU, Polícia Militar e Secretarias Municipais de Obras e Meio Ambiente) quando indispensável para a resposta a incidentes críticos.',
                ),

                _buildCard(
                  icon: Icons.gavel_rounded,
                  title: '5. Direitos do Titular (Art. 18 da LGPD)',
                  content:
                      'O titular dos dados tem o direito de obter a qualquer momento e mediante requisição:\n'
                      '• Confirmação da existência de tratamento e acesso aos dados;\n'
                      '• Correção de dados incompletos, inexatos ou desatualizados;\n'
                      '• Anonimização, bloqueio ou eliminação de dados desnecessários ou tratados em desconformidade;\n'
                      '• Informação sobre as entidades com as quais o controlador realizou uso compartilhado.',
                ),

                _buildCard(
                  icon: Icons.contact_mail_outlined,
                  title: '6. Encarregado de Dados (DPO) e Contato',
                  content:
                      'Para exercer quaisquer direitos previstos na LGPD ou esclarecer dúvidas sobre esta política, entre em contato diretamente com o Encarregado de Proteção de Dados através do canal oficial:\n\n'
                      'E-mail institucional: reinaldoinfra07@gmail.com\n'
                      'Coordenação de Tecnologia e Segurança — Defesa Civil em Foco.',
                ),

                const SizedBox(height: 32),

                if (isRegistration)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'Li e Concordo com os Termos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentAmber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required IconData icon, required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryTeal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.slate900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.slate700,
              fontSize: 13.8,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
