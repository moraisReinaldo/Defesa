class AppPagamentos {
  // WhatsApp comercial oficial (RESTRITO: liberado exclusivamente para cidades homologadas no PRO)
  static const String zapOficialNumero = '5511914043387';
  static const String zapOficialFormatado = '(11) 91404-3387';
  static const String emailComercial = 'reinaldohm07@gmail.com';

  // Stripe Payment Links (Opção 1 A - Links Diretos de Checkout)
  // Altere aqui para os links criados no seu painel Stripe (ex: https://buy.stripe.com/...)
  static const String stripeLinkPlanoGestao = 'https://buy.stripe.com/link_gestao_municipal';
  static const String stripeLinkPlanoPro = 'https://buy.stripe.com/link_pro_municipal';

  /// Gera a URL do WhatsApp oficial com mensagem contextualizada
  static String obterUrlWhatsApp({required String cidadeNome, String? motivo}) {
    final texto = motivo ?? 'Olá Reinaldo, sou da Defesa Civil de $cidadeNome e gostaria de falar sobre a contratação da plataforma Defesa em Foco.';
    return 'https://wa.me/$zapOficialNumero?text=${Uri.encodeComponent(texto)}';
  }

  /// Gera a URL de e-mail comercial para municípios não homologados
  static String obterUrlEmail({required String cidadeNome, String? assunto, String? corpo}) {
    final subject = assunto ?? 'Solicitação de Homologação / Contato • Defesa Civil de $cidadeNome';
    final body = corpo ?? 'Olá Reinaldo,\n\nGostaria de solicitar a homologação e informações sobre a plataforma Defesa em Foco para o município de $cidadeNome.\n\nAtenciosamente,';
    return 'mailto:$emailComercial?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
  }
}
