import 'package:flutter_test/flutter_test.dart';
import 'package:defesa_civil_app/models/cidade.dart';
import 'package:defesa_civil_app/models/usuario.dart';
import 'package:defesa_civil_app/services/ad_service.dart';

void main() {
  group('AdService - Governança de Exibição de Anúncios', () {
    test('Usuário com licença vitalícia NUNCA deve ver anúncios', () {
      final cidadeBase = Cidade(
        id: '1',
        codigo: 'BP',
        nome: 'Bragança Paulista',
        plano: PlanoCidade.baseGratuito,
        status: StatusCidade.contratoAtivo,
      );

      final usuarioVitalicio = Usuario(
        id: 'u-vitalicio',
        nome: 'Munícipe Vitalício',
        email: 'vitalicio@gmail.com',
        telefone: '11999999999',
        role: Role.cidadao,
        isSemAnunciosVitalicio: true,
      );

      final deveExibir = AdService.deveExibirAnuncio(
        usuarioLogado: usuarioVitalicio,
        cidadeAtiva: cidadeBase,
      );

      expect(deveExibir, isFalse);

      // Também testando a flag isVitalicio direta
      final deveExibirComFlag = AdService.deveExibirAnuncio(
        usuarioLogado: null,
        cidadeAtiva: cidadeBase,
        isVitalicio: true,
      );

      expect(deveExibirComFlag, isFalse);
    });

    test('Super Admin NUNCA deve ver anúncios na plataforma', () {
      final cidadeBase = Cidade(
        id: '1',
        codigo: 'BP',
        nome: 'Bragança Paulista',
        plano: PlanoCidade.baseGratuito,
        status: StatusCidade.contratoAtivo,
      );

      final superAdmin = Usuario(
        id: 'u-super',
        nome: 'Super Administrador',
        email: 'super@defesacivil.gov.br',
        telefone: '11999999999',
        role: Role.superAdmin,
      );

      final deveExibir = AdService.deveExibirAnuncio(
        usuarioLogado: superAdmin,
        cidadeAtiva: cidadeBase,
      );

      expect(deveExibir, isFalse);
    });

    test('Cidade em Trial PRO de 120 dias ativo -> ZERO anúncios para munícipes', () {
      final agora = DateTime.now();
      final cidadeTrial = Cidade(
        id: '1',
        codigo: 'PIR',
        nome: 'Piracaia',
        plano: PlanoCidade.baseGratuito,
        status: StatusCidade.trialAtivo,
        trialInicio: agora,
        trialFim: agora.add(const Duration(days: 120)),
      );

      final cidadaoComum = Usuario(
        id: 'u-cidadao',
        nome: 'Munícipe Comum',
        email: 'cidadao@gmail.com',
        telefone: '11999999999',
        role: Role.cidadao,
        isSemAnunciosVitalicio: false,
      );

      final deveExibir = AdService.deveExibirAnuncio(
        usuarioLogado: cidadaoComum,
        cidadeAtiva: cidadeTrial,
      );

      expect(deveExibir, isFalse);
    });

    test('Cidade com Plano Gestão Municipal -> ZERO anúncios', () {
      final cidadeGestao = Cidade(
        id: '1',
        codigo: 'JOA',
        nome: 'Joanópolis',
        plano: PlanoCidade.gestaoMunicipal,
        status: StatusCidade.contratoAtivo,
      );

      final cidadaoComum = Usuario(
        id: 'u-cidadao',
        nome: 'Munícipe Comum',
        email: 'cidadao@gmail.com',
        telefone: '11999999999',
        role: Role.cidadao,
        isSemAnunciosVitalicio: false,
      );

      final deveExibir = AdService.deveExibirAnuncio(
        usuarioLogado: cidadaoComum,
        cidadeAtiva: cidadeGestao,
      );

      expect(deveExibir, isFalse);
    });

    test('Cidade com Plano PRO Municipal -> ZERO anúncios', () {
      final cidadePro = Cidade(
        id: '1',
        codigo: 'JOA',
        nome: 'Joanópolis',
        plano: PlanoCidade.proMunicipal,
        status: StatusCidade.contratoAtivo,
      );

      final cidadaoComum = Usuario(
        id: 'u-cidadao',
        nome: 'Munícipe Comum',
        email: 'cidadao@gmail.com',
        telefone: '11999999999',
        role: Role.cidadao,
        isSemAnunciosVitalicio: false,
      );

      final deveExibir = AdService.deveExibirAnuncio(
        usuarioLogado: cidadaoComum,
        cidadeAtiva: cidadePro,
      );

      expect(deveExibir, isFalse);
    });

    test('Cidade no Plano Base Gratuito (sem vitalício) -> DEVE exibir anúncios', () {
      final cidadeBase = Cidade(
        id: '1',
        codigo: 'BP',
        nome: 'Bragança Paulista',
        plano: PlanoCidade.baseGratuito,
        status: StatusCidade.contratoAtivo,
      );

      final cidadaoComum = Usuario(
        id: 'u-cidadao',
        nome: 'Munícipe Comum',
        email: 'cidadao@gmail.com',
        telefone: '11999999999',
        role: Role.cidadao,
        isSemAnunciosVitalicio: false,
      );

      final deveExibir = AdService.deveExibirAnuncio(
        usuarioLogado: cidadaoComum,
        cidadeAtiva: cidadeBase,
      );

      expect(deveExibir, isTrue);
    });

    test('Cidade com Trial expirado e sem contrato PRO -> DEVE exibir anúncios no Plano Base', () {
      final agora = DateTime.now();
      final cidadeExpirada = Cidade(
        id: '1',
        codigo: 'BP',
        nome: 'Bragança Paulista',
        plano: PlanoCidade.baseGratuito,
        status: StatusCidade.expirado,
        trialInicio: agora.subtract(const Duration(days: 130)),
        trialFim: agora.subtract(const Duration(days: 10)),
      );

      final cidadaoComum = Usuario(
        id: 'u-cidadao',
        nome: 'Munícipe Comum',
        email: 'cidadao@gmail.com',
        telefone: '11999999999',
        role: Role.cidadao,
        isSemAnunciosVitalicio: false,
      );

      final deveExibir = AdService.deveExibirAnuncio(
        usuarioLogado: cidadaoComum,
        cidadeAtiva: cidadeExpirada,
      );

      expect(deveExibir, isTrue);
    });
  });
}
