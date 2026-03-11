# Guia de Integração com Backend Spring

Este documento fornece instruções para integrar o aplicativo Flutter com um backend Spring.

## Visão Geral da Integração

O aplicativo foi desenvolvido com separação clara entre camadas, facilitando a integração com um backend:

1. **StorageService**: Camada de persistência (atualmente local)
2. **Providers**: Lógica de negócio e gerenciamento de estado
3. **Screens**: Interface do usuário

## Arquitetura Recomendada

```
Flutter App
    ↓
API Service (novo)
    ↓
HTTP Client (dio/http)
    ↓
Backend Spring
    ↓
Database
```

## Passos para Integração

### 1. Criar Serviço de API

Crie um novo arquivo `lib/services/api_service.dart`:

```dart
import 'package:dio/dio.dart';
import '../models/ocorrencia.dart';
import '../models/usuario.dart';

class ApiService {
  late Dio _dio;
  final String baseUrl = 'https://seu-backend.com/api';

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    // Adicionar interceptor para token JWT
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Adicionar token ao header
          // options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
      ),
    );
  }

  // ========== AUTENTICAÇÃO ==========
  
  Future<Map<String, dynamic>> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/cadastro',
        data: {
          'nome': nome,
          'email': email,
          'telefone': telefone,
          'senha': senha,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Erro ao cadastrar: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'senha': senha,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  // ========== OCORRÊNCIAS ==========
  
  Future<List<Ocorrencia>> obterOcorrencias() async {
    try {
      final response = await _dio.get('/ocorrencias');
      final lista = response.data as List;
      return lista.map((o) => Ocorrencia.fromJson(o)).toList();
    } catch (e) {
      throw Exception('Erro ao obter ocorrências: $e');
    }
  }

  Future<Ocorrencia> criarOcorrencia(Ocorrencia ocorrencia) async {
    try {
      final response = await _dio.post(
        '/ocorrencias',
        data: ocorrencia.toJson(),
      );
      return Ocorrencia.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao criar ocorrência: $e');
    }
  }

  Future<void> atualizarOcorrencia(Ocorrencia ocorrencia) async {
    try {
      await _dio.put(
        '/ocorrencias/${ocorrencia.id}',
        data: ocorrencia.toJson(),
      );
    } catch (e) {
      throw Exception('Erro ao atualizar ocorrência: $e');
    }
  }

  Future<void> deletarOcorrencia(String id) async {
    try {
      await _dio.delete('/ocorrencias/$id');
    } catch (e) {
      throw Exception('Erro ao deletar ocorrência: $e');
    }
  }
}
```

### 2. Adicionar Dependência Dio

No `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.3.0
```

Execute:
```bash
flutter pub get
```

### 3. Modificar StorageService

Atualize `lib/services/storage_service.dart` para usar a API:

```dart
import 'api_service.dart';

class StorageService {
  final ApiService _apiService = ApiService();
  
  // ... código existente ...
  
  // Substituir métodos para chamar API ao invés de SharedPreferences
  Future<void> salvarOcorrencia(Ocorrencia ocorrencia) async {
    // Salvar localmente primeiro (cache)
    // Depois sincronizar com servidor
    await _apiService.criarOcorrencia(ocorrencia);
  }
  
  // ... outros métodos ...
}
```

### 4. Endpoints Esperados do Backend

#### Autenticação
```
POST /api/auth/cadastro
POST /api/auth/login
POST /api/auth/logout
POST /api/auth/refresh-token
```

#### Ocorrências
```
GET    /api/ocorrencias
GET    /api/ocorrencias/:id
POST   /api/ocorrencias
PUT    /api/ocorrencias/:id
DELETE /api/ocorrencias/:id
GET    /api/ocorrencias/usuario/:usuarioId
GET    /api/ocorrencias/filtro?tipo=...&status=...
```

#### Usuários
```
GET    /api/usuarios/:id
PUT    /api/usuarios/:id
GET    /api/usuarios/email/:email
```

### 5. Modelo de Dados Esperado

#### Ocorrência
```json
{
  "id": "uuid",
  "tipo": "alagamento",
  "descricao": "Descrição da ocorrência",
  "latitude": -15.7942,
  "longitude": -47.8822,
  "caminhoFoto": "url_da_foto",
  "dataHora": "2026-03-10T10:30:00Z",
  "usuarioId": "uuid",
  "resolvida": false,
  "dataResolucao": null,
  "criadoEm": "2026-03-10T10:30:00Z",
  "atualizadoEm": "2026-03-10T10:30:00Z"
}
```

#### Usuário
```json
{
  "id": "uuid",
  "nome": "João Silva",
  "email": "joao@example.com",
  "telefone": "(11) 99999-9999",
  "dataCriacao": "2026-03-10T10:30:00Z"
}
```

#### Resposta de Login
```json
{
  "token": "jwt_token",
  "usuario": {
    "id": "uuid",
    "nome": "João Silva",
    "email": "joao@example.com",
    "telefone": "(11) 99999-9999"
  }
}
```

### 6. Tratamento de Erros

Implemente tratamento de erros consistente:

```dart
try {
  await _apiService.criarOcorrencia(ocorrencia);
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Token expirado - fazer logout
  } else if (e.response?.statusCode == 400) {
    // Dados inválidos
  } else if (e.response?.statusCode == 500) {
    // Erro do servidor
  } else {
    // Erro de conexão
  }
}
```

### 7. Sincronização Offline

Para suportar uso offline:

```dart
class SyncService {
  final StorageService _storageService;
  final ApiService _apiService;
  
  Future<void> sincronizar() async {
    // Obter dados pendentes do armazenamento local
    final ocorrenciasPendentes = 
        await _storageService.obterOcorrenciasPendentes();
    
    // Enviar para servidor
    for (final ocorrencia in ocorrenciasPendentes) {
      try {
        await _apiService.criarOcorrencia(ocorrencia);
        // Marcar como sincronizada
      } catch (e) {
        // Manter como pendente
      }
    }
  }
}
```

### 8. Autenticação com JWT

Implemente gerenciamento de tokens:

```dart
class TokenService {
  static const String _tokenKey = 'jwt_token';
  late SharedPreferences _prefs;
  
  Future<void> salvarToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }
  
  Future<String?> obterToken() async {
    return _prefs.getString(_tokenKey);
  }
  
  Future<void> limparToken() async {
    await _prefs.remove(_tokenKey);
  }
}
```

### 9. Upload de Fotos

Para fazer upload de fotos para o servidor:

```dart
Future<String> enviarFoto(File foto) async {
  try {
    final formData = FormData.fromMap({
      'foto': await MultipartFile.fromFile(
        foto.path,
        filename: 'ocorrencia_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });
    
    final response = await _dio.post(
      '/upload/foto',
      data: formData,
    );
    
    return response.data['url']; // URL da foto no servidor
  } catch (e) {
    throw Exception('Erro ao enviar foto: $e');
  }
}
```

## Checklist de Integração

- [ ] Backend Spring configurado e rodando
- [ ] Endpoints de autenticação implementados
- [ ] Endpoints de ocorrências implementados
- [ ] Banco de dados configurado
- [ ] ApiService criado e testado
- [ ] StorageService atualizado para usar API
- [ ] Tratamento de erros implementado
- [ ] Sincronização offline testada
- [ ] Upload de fotos funcionando
- [ ] Autenticação JWT implementada
- [ ] Testes de integração realizados
- [ ] Documentação atualizada

## Próximos Passos

1. Desenvolver backend Spring com os endpoints especificados
2. Configurar banco de dados (PostgreSQL recomendado)
3. Implementar autenticação JWT
4. Testar integração com o aplicativo Flutter
5. Implementar notificações em tempo real (WebSocket/Firebase)
6. Configurar CI/CD para deploy automático

## Recursos Úteis

- [Documentação Dio](https://pub.dev/packages/dio)
- [JWT em Flutter](https://pub.dev/packages/jwt_decoder)
- [Firebase Messaging](https://pub.dev/packages/firebase_messaging)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)

---

Para dúvidas ou sugestões, entre em contato com a equipe de desenvolvimento.
