# Testes da API (Thunder Client / Postman)

Este documento contém apenas os corpos de requisição (JSON) ordenados **exatamente na mesma sequência da Especificação**. 
Copie o bloco de código correspondente e cole no *Body* da sua requisição no Thunder Client.
*(A URL base usada aqui é `https://api.rhprogramer.com.br`, mude para `http://localhost:8080` se for rodar local)*.

---

## 4.1 Autenticação (`/api/auth`)

### 1. Cadastro de Usuário (Cidadão)
**POST** `https://api.rhprogramer.com.br/api/auth/cadastro`
```json
{
  "nome": "João Silva",
  "email": "joao@teste.com",
  "telefone": "(11) 99999-9999",
  "senha": "Senha123!",
  "cidade": "SAO PAULO",
  "role": "CIDADAO",
  "concordaLGPD": true
}
```

### 2. Login (Usuário Comum)
**POST** `https://api.rhprogramer.com.br/api/usuarios/login`
```json
{
  "email": "joao@teste.com",
  "senha": "Senha123!"
}
```
*(Copie o token JWT que será retornado)*

### 3. Login de Administrador
**POST** `https://api.rhprogramer.com.br/api/auth/admin-login`
```json
{
  "senha": "Henrique0712$"
}
```
*(Copie o token JWT de admin que será retornado)*

### 4. Logout (Requer Token Bearer)
**POST** `https://api.rhprogramer.com.br/api/auth/logout`
*(Sem Body)*

---

## 4.2 Ocorrências (`/api/ocorrencias`)

### 5. Criar Ocorrência (Público)
**POST** `https://api.rhprogramer.com.br/api/ocorrencias`
```json
{
  "tipo": "Alagamento",
  "descricao": "Rua completamente alagada após chuva forte",
  "latitude": -23.5505,
  "longitude": -46.6333,
  "cidade": "SAO PAULO",
  "dataHora": "2026-06-15T10:30:00",
  "criadoPorAgente": false
}
```

### 6. Listar Ocorrências (Público)
**GET** `https://api.rhprogramer.com.br/api/ocorrencias?cidade=SAO PAULO`
*(Sem Body)*

### 7. Buscar Ocorrência por ID (Público)
**GET** `https://api.rhprogramer.com.br/api/ocorrencias/COLE_O_ID_DA_OCORRENCIA_AQUI`
*(Sem Body)*

### 8. Atualizar Ocorrência (Requer Token Bearer)
**PATCH** `https://api.rhprogramer.com.br/api/ocorrencias/COLE_O_ID_DA_OCORRENCIA_AQUI`
```json
{
  "descricao": "A água baixou. Rua parcialmente liberada."
}
```

### 9. Deletar Ocorrência (Requer Token ADMIN)
**DELETE** `https://api.rhprogramer.com.br/api/ocorrencias/COLE_O_ID_DA_OCORRENCIA_AQUI`
*(Sem Body)*

### 10. Aprovar Ocorrência (Requer Token Agente/Admin)
**POST** `https://api.rhprogramer.com.br/api/ocorrencias/COLE_O_ID_DA_OCORRENCIA_AQUI/aprovar`
*(Sem Body)*

### 11. Registrar Chegada na Ocorrência (Requer Token Agente/Admin)
**POST** `https://api.rhprogramer.com.br/api/ocorrencias/COLE_O_ID_DA_OCORRENCIA_AQUI/chegada`
```json
{
  "parecer": "Equipe no local. Situação sob controle."
}
```

### 12. Resolver Ocorrência (Requer Token Agente/Admin)
**POST** `https://api.rhprogramer.com.br/api/ocorrencias/COLE_O_ID_DA_OCORRENCIA_AQUI/resolver`
```json
{
  "parecer": "Local desobstruído e limpo."
}
```

### 13. Reativar Ocorrência (Requer Token Agente/Admin)
**POST** `https://api.rhprogramer.com.br/api/ocorrencias/COLE_O_ID_DA_OCORRENCIA_AQUI/reativar`
*(Sem Body)*

---

## 4.3 Usuários (`/api/usuarios`)

*(Nota: O Cadastro já foi testado no 4.1)*

### 14. Listar Todos os Usuários (Requer Token ADMIN)
**GET** `https://api.rhprogramer.com.br/api/usuarios`
*(Sem Body)*

### 15. Buscar Usuário por ID (Requer Token Bearer)
**GET** `https://api.rhprogramer.com.br/api/usuarios/COLE_O_ID_DO_USUARIO_AQUI`
*(Sem Body)*

### 16. Atualizar Usuário (Requer Token Bearer do próprio usuário ou Admin)
**PUT** `https://api.rhprogramer.com.br/api/usuarios/COLE_O_ID_DO_USUARIO_AQUI`
```json
{
  "nome": "João da Silva",
  "telefone": "(11) 98888-8888"
}
```

### 17. Deletar Usuário (Requer Token ADMIN)
**DELETE** `https://api.rhprogramer.com.br/api/usuarios/COLE_O_ID_DO_USUARIO_AQUI`
*(Sem Body)*

### 18. Listar Agentes (Requer Token Agente/Admin)
**GET** `https://api.rhprogramer.com.br/api/usuarios/agentes?cidade=SAO PAULO`
*(Sem Body)*

### 19. Promover Cidadão a Agente (Requer Token ADMIN)
**POST** `https://api.rhprogramer.com.br/api/usuarios/promover`
```json
{
  "email": "joao@teste.com"
}
```

### 20. Solicitar Reset de Senha (Público)
**POST** `https://api.rhprogramer.com.br/api/usuarios/esqueci-senha`
```json
{
  "email": "joao@teste.com"
}
```

### 21. Resetar Senha com Código (Público)
**POST** `https://api.rhprogramer.com.br/api/usuarios/resetar-senha`
```json
{
  "email": "joao@teste.com",
  "codigo": "123456",
  "novaSenha": "NovaSenhaSegura123!"
}
```

---

## 4.4 Cidades (`/api/cidades`)

### 22. Criar Cidade (Público)
**POST** `https://api.rhprogramer.com.br/api/cidades`
```json
{
  "codigo": "3550308",
  "nome": "SAO PAULO"
}
```

### 23. Listar Cidades (Público)
**GET** `https://api.rhprogramer.com.br/api/cidades`
*(Sem Body)*

### 24. Buscar Cidade por ID (Público)
**GET** `https://api.rhprogramer.com.br/api/cidades/COLE_O_ID_AQUI`
*(Sem Body)*

### 25. Atualizar Cidade (Público)
**PUT** `https://api.rhprogramer.com.br/api/cidades/COLE_O_ID_AQUI`
```json
{
  "codigo": "3550308",
  "nome": "SÃO PAULO"
}
```

### 26. Deletar Cidade (Público)
**DELETE** `https://api.rhprogramer.com.br/api/cidades/COLE_O_ID_AQUI`
*(Sem Body)*

---

## 4.5 Pontos de Interesse / Marcações (`/api/marcacoes`)

### 27. Criar Ponto de Interesse (Requer Token Agente/Admin)
**POST** `https://api.rhprogramer.com.br/api/marcacoes`
```json
{
  "tipo": "Abrigo",
  "descricao": "Escola Municipal sendo usada como abrigo",
  "latitude": -23.5489,
  "longitude": -46.6388,
  "cidade": "SAO PAULO"
}
```

### 28. Listar Pontos de Interesse (Público)
**GET** `https://api.rhprogramer.com.br/api/marcacoes?cidade=SAO PAULO`
*(Sem Body)*

### 29. Atualizar Ponto de Interesse (Requer Token Agente/Admin)
**PUT** `https://api.rhprogramer.com.br/api/marcacoes/COLE_O_ID_DA_MARCACAO_AQUI`
```json
{
  "tipo": "Hospital",
  "descricao": "Hospital de emergência",
  "latitude": -23.5500,
  "longitude": -46.6400,
  "cidade": "SAO PAULO"
}
```

### 30. Deletar Ponto de Interesse (Requer Token ADMIN)
**DELETE** `https://api.rhprogramer.com.br/api/marcacoes/COLE_O_ID_DA_MARCACAO_AQUI`
*(Sem Body)*
