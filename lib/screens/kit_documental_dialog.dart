import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_pagamentos.dart';

class KitDocumentalDialog extends StatefulWidget {
  final String cidadeNome;
  final String cidadeCodigo;
  final bool isHomologado;

  const KitDocumentalDialog({
    super.key,
    required this.cidadeNome,
    required this.cidadeCodigo,
    this.isHomologado = false,
  });

  static void show(
    BuildContext context, {
    required String cidadeNome,
    required String cidadeCodigo,
    bool isHomologado = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => KitDocumentalDialog(
        cidadeNome: cidadeNome,
        cidadeCodigo: cidadeCodigo,
        isHomologado: isHomologado,
      ),
    );
  }

  @override
  State<KitDocumentalDialog> createState() => _KitDocumentalDialogState();
}

class _KitDocumentalDialogState extends State<KitDocumentalDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _gerarTermoReferencia() {
    return '''TERMO DE REFERÊNCIA - CONTRATAÇÃO DE SISTEMA DE GESTÃO DE DEFESA CIVIL
MUNICÍPIO: ${widget.cidadeNome} (${widget.cidadeCodigo})
ENQUADRAMENTO LEGAL: LEI FEDERAL Nº 12.608/2012 (POLÍTICA NACIONAL DE PROTEÇÃO E DEFESA CIVIL)

1. OBJETO
Contratação de plataforma tecnológica em nuvem (SaaS) para gestão de riscos, monitoramento climático, despacho operacional de agentes e emissão de alertas georreferenciados à população para a Defesa Civil de ${widget.cidadeNome}.

2. JUSTIFICATIVA DA CONTRATAÇÃO
A Lei Federal nº 12.608/2012 estabelece o dever dos municípios em estruturar sistemas eficientes de resposta e prevenção a desastres naturais e eventos climáticos extremos. O sistema "Defesa em Foco" atende aos seguintes requisitos primordiais:
- Canal bidirecional e georreferenciado entre munícipes e o Centro de Operações;
- Despacho em tempo real e rotas de viaturas para agentes em campo;
- Sistema oficial de notificações push via satélite/OneSignal;
- Exportação padronizada no layout oficial COBRADE / S2ID do Ministério do Desenvolvimento Regional.

3. ESPECIFICAÇÕES TÉCNICAS E MÓDULOS
- Painel Web Integrado e aplicativo mobile iOS e Android;
- Gestão de equipes de campo e rotas de deslocamento;
- Módulo de Abrigos Temporários, Pontos de Apoio e Áreas de Risco (POIs);
- Total conformidade com a LGPD (Lei nº 13.709/2018).

4. ESTIMATIVA ORÇAMENTÁRIA E VALOR ANUAL
Plano PRO Municipal: R\$ 1.490,00 / mês (Total anual com empenho: R\$ 17.880,00).
Plano Gestão Municipal: R\$ 490,00 / mês (Total anual com empenho: R\$ 5.880,00).
Ambos situam-se amplamente abaixo do teto de dispensa da Lei Federal nº 14.133/2021.
''';
  }

  String _gerarMinutaDispensa() {
    return '''MINUTA DE JUSTIFICATIVA DE DISPENSA DE LICITAÇÃO
PROCESSO ADMINISTRATIVO Nº ___/2026
FUNDAMENTAÇÃO: ART. 75, INCISO II, DA LEI FEDERAL Nº 14.133/2021

À Coordenadoria de Compras e Licitações de ${widget.cidadeNome}:

I - DO OBJETO E ENQUADRAMENTO
Trata-se de contratação direta de prestação de serviços de tecnologia da informação para o sistema "Defesa em Foco", destinado à modernização e suporte operacional da Defesa Civil Municipal.

II - DA DISPENSA POR BAIXO VALOR
A presente contratação encontra pleno amparo no Art. 75, inciso II, da Lei nº 14.133/2021, que dispõe:
"Art. 75. É dispensável a licitação:
II - para contratação de serviço que envolva valores inferiores a R\$ 59.906,02 (atualizado pelo Decreto Federal nº 11.871/2023)."

O valor anual estimado da contratação é de R\$ 17.880,00 (dezessete mil, oitocentos e oitenta reais) no Plano PRO Municipal (ou R\$ 5.880,00 no Plano Gestão), representando menos de 30% do limite legal para contratação direta sem licitação.

III - DA RAZÃO DA ESCOLHA DO PRESTADOR E ECONOMICIDADE
A plataforma Defesa em Foco oferece arquitetura completa já integrada ao padrão COBRADE e S2ID, sem custos de instalação ou taxas adicionais de servidor, gerando economia expressiva aos cofres públicos municipais em comparação ao desenvolvimento próprio.

IV - CONCLUSÃO
Diante do exposto, manifesta-se pela viabilidade jurídica e orçamentária da DISPENSA DE LICITAÇÃO com base no Art. 75, II, da Lei Federal nº 14.133/2021.
''';
  }

  String _gerarPropostaComercial() {
    return '''PROPOSTA COMERCIAL OFICIAL - DEFESA EM FOCO
PARA: Prefeitura Municipal de ${widget.cidadeNome}
ATENÇÃO: Gabinete do Prefeito e Coordenadoria Municipal de Defesa Civil
DATA: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

1. OPÇÕES DE PLANOS:
• PLANO PRO MUNICIPAL (O MAIS COMPLETO):
  - Valor Mensal: R\$ 1.490,00 (Hum mil, quatrocentos e noventa reais)
  - Faturamento Anual com Empenho: R\$ 17.880,00
  - Até 5 Gestores, Agentes de Rua ILIMITADOS, Alertas OneSignal, POIs/Abrigos, Dashboard Web e Zero Anúncios.

• PLANO GESTÃO MUNICIPAL (SOLO / GABINETE):
  - Valor Mensal: R\$ 490,00 (Quatrocentos e noventa reais)
  - Faturamento Anual com Empenho: R\$ 5.880,00
  - Até 2 Gestores, Alertas OneSignal, Relatórios COBRADE/S2ID e Zero Anúncios.

2. FORMAS DE PAGAMENTO:
- Anuidade empenhada via Nota Fiscal de Serviços Eletrônica (NFSe) com liquidação bancária;
- Assinatura mensal online com ativação imediata via Stripe (Cartão de Crédito).

${widget.isHomologado ? '''3. DADOS PARA CONTATO E FORMALIZAÇÃO:
- Consultor Responsável: Reinaldo Morais
- Telefone / WhatsApp: ${AppPagamentos.zapOficialFormatado}
- E-mail Comercial: ${AppPagamentos.emailComercial}
- Checkout Online Plano PRO: ${AppPagamentos.stripeLinkPlanoPro}
- Checkout Online Plano Gestão: ${AppPagamentos.stripeLinkPlanoGestao}''' : '''3. DADOS PARA CONTATO E FORMALIZAÇÃO:
- Canal Institucional Oficial: Reinaldo Morais
- E-mail de Homologação: ${AppPagamentos.emailComercial}
- Portal Oficial: https://defesaemfoco.com.br
(O contato direto via WhatsApp e links diretos são liberados exclusivamente após a homologação inicial do município)'''}
''';
  }

  void _copiarTexto(String texto, String nomeDoc) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nomeDoc copiado para a área de transferência! 📋'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kit Dispensa de Licitação', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Lei Federal nº 14.133/21 • ${widget.cidadeNome}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 650,
        height: 500,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryTeal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primaryTeal,
              tabs: const [
                Tab(text: 'Termo de Referência'),
                Tab(text: 'Minuta Dispensa'),
                Tab(text: 'Proposta Comercial'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent('Termo de Referência', _gerarTermoReferencia()),
                  _buildTabContent('Minuta de Dispensa (Lei 14.133/21)', _gerarMinutaDispensa()),
                  _buildTabContent('Proposta Comercial Oficial', _gerarPropostaComercial()),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isHomologado) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blueAccent,
              side: const BorderSide(color: Colors.blueAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => launchUrl(Uri.parse(AppPagamentos.stripeLinkPlanoPro)),
            icon: const Icon(Icons.credit_card_rounded, size: 16),
            label: const Text('Assinar via Cartão (Stripe)', style: TextStyle(fontSize: 12)),
          ),
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(AppPagamentos.obterUrlWhatsApp(
              cidadeNome: widget.cidadeNome,
              motivo: 'Olá Reinaldo, sou da Defesa Civil de ${widget.cidadeNome} e gostaria de formalizar a contratação por Dispensa de Licitação.',
            ))),
            icon: const Icon(Icons.chat_bubble_rounded, color: Colors.green),
            label: const Text('Falar no WhatsApp'),
          ),
        ] else ...[
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(AppPagamentos.obterUrlEmail(
              cidadeNome: widget.cidadeNome,
              assunto: 'Homologação e Contratação • Defesa Civil de ${widget.cidadeNome}',
            ))),
            icon: const Icon(Icons.email_rounded, color: AppColors.primaryTeal),
            label: const Text('Contato por E-mail'),
          ),
        ],
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Concluído'),
        ),
      ],
    );
  }

  Widget _buildTabContent(String titulo, String conteudo) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
              OutlinedButton.icon(
                onPressed: () => _copiarTexto(conteudo, titulo),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar Texto', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundOffWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  conteudo,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
