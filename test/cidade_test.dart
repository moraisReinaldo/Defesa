import 'package:flutter_test/flutter_test.dart';
import 'package:defesa_civil_app/models/cidade.dart';

void main() {
  group('Cidade Model - Planos, Trial e Homologação', () {
    test('Trial Ativo concede Plano PRO e label de 120 Dias', () {
      final agora = DateTime.now();
      final cidade = Cidade(
        id: 'cid-1',
        codigo: 'ATI',
        nome: 'Atibaia',
        plano: PlanoCidade.baseGratuito,
        status: StatusCidade.trialAtivo,
        trialInicio: agora,
        trialFim: agora.add(const Duration(days: 120)),
        diasRestantesTrial: 120,
      );

      expect(cidade.isTrialAtivo, isTrue);
      expect(cidade.planoEfetivo, equals(PlanoCidade.proMunicipal));
      expect(cidade.status.label, equals('Trial PRO Ativo (120 Dias)'));
      expect(cidade.diasRestantesTrial, inInclusiveRange(119, 120));
      expect(cidade.recursoAgentesLiberado, isTrue);
      expect(cidade.recursoPoiLiberado, isTrue);
      expect(cidade.recursoAlertasLiberado, isTrue);
      expect(cidade.limiteGestores, equals(5));
    });

    test('Trial Expirado regride plano efetivo para baseGratuito', () {
      final agora = DateTime.now();
      final cidade = Cidade(
        id: 'cid-2',
        codigo: 'PIR',
        nome: 'Piracaia',
        plano: PlanoCidade.baseGratuito,
        status: StatusCidade.trialAtivo,
        trialInicio: agora.subtract(const Duration(days: 125)),
        trialFim: agora.subtract(const Duration(days: 5)),
      );

      expect(cidade.isTrialAtivo, isFalse);
      expect(cidade.planoEfetivo, equals(PlanoCidade.baseGratuito));
      expect(cidade.diasRestantesTrial, equals(0));
      expect(cidade.recursoAgentesLiberado, isFalse);
      expect(cidade.limiteGestores, equals(1));
    });

    test('Plano Gestão Municipal com contrato ativo libera 2 gestores e bloqueia agentes', () {
      final cidade = Cidade(
        id: 'cid-3',
        codigo: 'JOA',
        nome: 'Joanópolis',
        plano: PlanoCidade.gestaoMunicipal,
        status: StatusCidade.contratoAtivo,
      );

      expect(cidade.isContratoAtivo, isTrue);
      expect(cidade.planoEfetivo, equals(PlanoCidade.gestaoMunicipal));
      expect(cidade.limiteGestores, equals(2));
      expect(cidade.recursoAgentesLiberado, isFalse);
      expect(cidade.recursoPoiLiberado, isFalse);
      expect(cidade.plano.label, equals('Plano Gestão Municipal'));
    });

    test('Deserialização fromJson null-safe com chaves completas', () {
      final json = {
        'id': 'abc-123',
        'codigo': 'BP',
        'nome': 'Bragança Paulista',
        'plano': 'PRO_MUNICIPAL',
        'status': 'CONTRATO_ATIVO',
        'contratoExpiracao': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      };

      final cidade = Cidade.fromJson(json);

      expect(cidade.id, equals('abc-123'));
      expect(cidade.codigo, equals('BP'));
      expect(cidade.nome, equals('Bragança Paulista'));
      expect(cidade.plano, equals(PlanoCidade.proMunicipal));
      expect(cidade.status, equals(StatusCidade.contratoAtivo));
      expect(cidade.isContratoAtivo, isTrue);
    });
  });
}
