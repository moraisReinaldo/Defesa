import 'package:flutter_test/flutter_test.dart';
import 'package:defesa_civil_app/models/usuario.dart';

void main() {
  group('Usuario Model - Roles, LGPD e Parsing', () {
    test('Parsing de SUPER_ADMIN a partir de string backend', () {
      final json = {
        'id': 'usr-super',
        'nome': 'Super Administrador',
        'email': 'super@defesacivil.gov.br',
        'telefone': '11999999999',
        'role': 'SUPER_ADMIN',
        'concordaLGPD': true,
        'cidade': 'GERAL',
        'status': 'ATIVO',
        'semAnunciosVitalicio': true,
        'dataCriacao': '2026-09-04T12:00:00.123456789', // Formato com nanos Java
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.id, equals('usr-super'));
      expect(usuario.role, equals(Role.superAdmin));
      expect(usuario.isSuperAdmin, isTrue);
      expect(usuario.isAdmin, isTrue);
      expect(usuario.isAgente, isTrue);
      expect(usuario.isSemAnunciosVitalicio, isTrue);
      expect(usuario.dataCriacao, isNotNull);
    });

    test('Parsing de ADMINISTRADOR municipal', () {
      final json = {
        'id': 'usr-admin',
        'nome': 'Coordenador Defesa',
        'email': 'coordenador@piracaia.sp.gov.br',
        'telefone': '11988888888',
        'role': 'ADMINISTRADOR',
        'cidade': 'PIR',
        'status': 'ATIVO',
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.role, equals(Role.administrador));
      expect(usuario.isAdmin, isTrue);
      expect(usuario.isSuperAdmin, isFalse);
      expect(usuario.isAgente, isTrue);
      expect(usuario.cidade, equals('PIR'));
    });

    test('Parsing de AGENTE operacional', () {
      final json = {
        'id': 'usr-agente',
        'nome': 'Agente Silva',
        'email': 'silva@defesacivil.gov.br',
        'telefone': '11977777777',
        'role': 'AGENTE',
        'cidade': 'BP',
        'status': 'ATIVO',
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.role, equals(Role.agente));
      expect(usuario.isAgente, isTrue);
      expect(usuario.isAdmin, isFalse);
      expect(usuario.isSuperAdmin, isFalse);
    });

    test('Parsing de CIDADAO com chave isSemAnunciosVitalicio', () {
      final json = {
        'id': 'usr-cidadao',
        'nome': 'Munícipe João',
        'email': 'joao@gmail.com',
        'telefone': '11966666666',
        'role': 'CIDADAO',
        'isSemAnunciosVitalicio': true,
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.role, equals(Role.cidadao));
      expect(usuario.isAgente, isFalse);
      expect(usuario.isAdmin, isFalse);
      expect(usuario.isSuperAdmin, isFalse);
      expect(usuario.isSemAnunciosVitalicio, isTrue);
    });

    test('Serialização toJson mantém consistência', () {
      final usuario = Usuario(
        id: 'u-1',
        nome: 'Teste',
        email: 'teste@exemplo.com',
        telefone: '11999999999',
        role: Role.superAdmin,
        concordaLGPD: true,
        cidade: 'BP',
        isSemAnunciosVitalicio: true,
      );

      final json = usuario.toJson();

      expect(json['id'], equals('u-1'));
      expect(json['email'], equals('teste@exemplo.com'));
      expect(json['role'], equals('SUPERADMIN'));
      expect(json['concordaLGPD'], isTrue);
      expect(json['semAnunciosVitalicio'], isTrue);
    });
  });
}
