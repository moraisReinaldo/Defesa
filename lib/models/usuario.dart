import 'package:uuid/uuid.dart';

enum Role {
  CIDADAO,
  AGENTE,
  ADMINISTRADOR
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

  Usuario({
    String? id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.senha,
    this.role = Role.CIDADAO,
    this.concordaLGPD = false,
    this.cidade,
    this.especialidade,
    this.fcmToken,
    DateTime? dataCriacao,
  })  : id = id ?? const Uuid().v4(),
        dataCriacao = dataCriacao ?? DateTime.now();

  bool get isAgente => role == Role.AGENTE || role == Role.ADMINISTRADOR;
  bool get isAdmin => role == Role.ADMINISTRADOR;

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'senha': senha,
      'role': role.name,
      'concordaLGPD': concordaLGPD,
      'cidade': cidade,
      'especialidade': especialidade,
      'fcmToken': fcmToken,
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
        (e) => e.name == json['role'], 
        orElse: () => json['isAgente'] == true ? Role.AGENTE : Role.CIDADAO
      ),
      concordaLGPD: json['concordaLGPD'] ?? false,
      cidade: json['cidade'],
      especialidade: json['especialidade'],
      fcmToken: json['fcmToken'],
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
