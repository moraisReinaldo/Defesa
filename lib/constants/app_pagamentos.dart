class AppPagamentos {
  // WhatsApp comercial oficial (RESTRITO: liberado exclusivamente para cidades homologadas no PRO)
  static const String zapOficialNumero = '5511914043387';
  static const String zapOficialFormatado = '(11) 91404-3387';
  static const String emailComercial = 'reinaldohm07@gmail.com';

  // Stripe Keys
  static const String stripePublishableKey = 'pk_live_51UBjQsRptjvZgxMgoIWMJZkOQl4o4QCgDxBu1W8LMEEImtjSlz5j1sgc7wYUn90bIYNn4ooE9h0mIFsq7CIEBL2400bQhqxtVa';

  // Stripe Payment Links (Opção 1 A - Links Diretos de Checkout Oficiais)
  static const String stripeLinkPlanoGestao = 'https://buy.stripe.com/fZudRb0J15jHdRPgF9fbq01';
  static const String stripeLinkPlanoPro = 'https://buy.stripe.com/6oU7sNdvN3bz297ex1fbq00';
  // Licença Vitalícia Sem Anúncios para Munícipes (Válido para sempre em qualquer cidade)
  static const String stripeLinkVitalicioSemAnuncios = 'https://buy.stripe.com/dRmeVf3VdbI59Bz4Wrfbq02';

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
