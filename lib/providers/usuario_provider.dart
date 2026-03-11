import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/storage_service.dart';

class UsuarioProvider extends ChangeNotifier {
  final StorageService _storageService;
  Usuario? _usuarioLogado;
  bool _carregando = false;
  bool _isAdmin = false;

  UsuarioProvider(this._storageService);

  Usuario? get usuarioLogado => _usuarioLogado;
  bool get estaLogado => _usuarioLogado != null;
  bool get carregando => _carregando;
  bool get isAdmin => _isAdmin;

  /// Reseta o estado de administrador
  void logoutAdmin() {
    _isAdmin = false;
    notifyListeners();
  }

  /// Tenta autenticar como administrador usando [senhaAdmin].
  /// Retorna true se a senha estiver correta.
  Future<bool> autenticarAdmin(String senhaAdmin) async {
    // senha fixa para demonstração; em produção isso viria de servidor seguro
    const adminPassword = 'SenhaDefesa!';
    if (senhaAdmin == adminPassword) {
      _isAdmin = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> verificarUsuarioLogado() async {
    _carregando = true;
    notifyListeners();
    
    _usuarioLogado = await _storageService.obterUsuarioLogado();
    
    _carregando = false;
    notifyListeners();
  }

  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    try {
      // Verificar se email já existe
      final usuarioExistente =
          await _storageService.obterUsuarioPorEmail(email);
      if (usuarioExistente != null) {
        return false;
      }

      // Criar novo usuário
      final novoUsuario = Usuario(
        nome: nome,
        email: email,
        telefone: telefone,
        senha: senha, // Em produção, usar hash
      );

      await _storageService.salvarUsuario(novoUsuario);
      await _storageService.salvarUsuarioLogado(novoUsuario);
      _usuarioLogado = novoUsuario;
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao cadastrar: $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String senha,
  }) async {
    try {
      final usuario = await _storageService.obterUsuarioPorEmail(email);
      if (usuario == null) {
        return false;
      }

      // Verificar senha (em produção, usar hash)
      if (usuario.senha != senha) {
        return false;
      }

      await _storageService.salvarUsuarioLogado(usuario);
      _usuarioLogado = usuario;
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao fazer login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.limparUsuarioLogado();
    _usuarioLogado = null;
    _isAdmin = false;
    notifyListeners();
  }

  Future<bool> atualizarPerfil({
    required String nome,
    required String telefone,
  }) async {
    if (_usuarioLogado == null) return false;

    try {
      final usuarioAtualizado = _usuarioLogado!.copyWith(
        nome: nome,
        telefone: telefone,
      );

      await _storageService.atualizarUsuario(usuarioAtualizado);
      await _storageService.salvarUsuarioLogado(usuarioAtualizado);
      _usuarioLogado = usuarioAtualizado;
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
      return false;
    }
  }
}
