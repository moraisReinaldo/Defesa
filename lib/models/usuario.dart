import 'package:uuid/uuid.dart';

enum Role {
  cidadao,
  agente,
  administrador
}

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final String? senha; 
  final Role role; 
  final bool concordaLGPD; // Obrigatório pela LGPD
  final String? cidade;
  final String? especialidade;
  final String? fcmToken;
  final DateTime dataCriacao;
  final String situacao; // PENDENTE ou ATIVO

  Usuario({
    String? id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.senha,
    this.role = Role.cidadao,
    this.concordaLGPD = false,
    this.cidade,
    this.especialidade,
    this.fcmToken,
    this.situacao = 'ATIVO',
    DateTime? dataCriacao,
  })  : id = id ?? const Uuid().v4(),
        dataCriacao = dataCriacao ?? DateTime.now();

  bool get isAgente => role == Role.agente || role == Role.administrador;
  bool get isAdmin => role == Role.administrador;
  bool get isAtivo => situacao.toUpperCase() == 'ATIVO';

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'senha': senha,
      'role': role.name.toUpperCase(),
      'concordaLGPD': concordaLGPD,
      'cidade': cidade,
      'especialidade': especialidade,
      'fcmToken': fcmToken,
      'situacao': situacao,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  // Criar Usuario a partir de JSON
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? '',
      nome: json['nome'] ?? 'Usuário',
      email: json['email'] ?? '',
      telefone: json['telefone'] ?? '',
      senha: json['senha'],
      role: Role.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['role'] as String?)?.toUpperCase(),
        orElse: () => json['isAgente'] == true ? Role.agente : Role.cidadao
      ),
      concordaLGPD: json['concordaLGPD'] ?? false,
      cidade: json['cidade'],
      especialidade: json['especialidade'],
      fcmToken: json['fcmToken'],
      situacao: json['situacao'] ?? 'ATIVO',
      dataCriacao: _parseSafe(json['dataCriacao']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseSafe(dynamic val) {
    if (val == null) return null;
    try {
      String s = val.toString();
      // Se tiver nanosegundos (Java), corta para microsegundos (Dart aceita até 6 dígitos após o ponto)
      if (s.contains('.')) {
        var parts = s.split('.');
        if (parts[1].length > 6) {
          s = '${parts[0]}.${parts[1].substring(0, 6)}';
        }
      }
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}
