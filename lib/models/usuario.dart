import 'package:uuid/uuid.dart';

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final String? senha; // Armazenado localmente (hash em produção)
  final DateTime dataCriacao;

  Usuario({
    String? id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.senha,
    DateTime? dataCriacao,
  })  : id = id ?? const Uuid().v4(),
        dataCriacao = dataCriacao ?? DateTime.now();

  // Removido verificação de administrador por telefone.
  // Se precisar de flags adicionais, adicione campo separado.


  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'senha': senha,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  // Criar Usuario a partir de JSON
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      telefone: json['telefone'],
      senha: json['senha'],
      dataCriacao: DateTime.parse(json['dataCriacao']),
    );
  }

  // Copiar com alterações
  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    String? senha,
    DateTime? dataCriacao,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      senha: senha ?? this.senha,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}
