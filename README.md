
# Message App - API e Cliente Dart

## Visão geral

Este projeto contém:

- **API de gerenciamento de salas e mensagens**, localizada em `message_app/message_serve/`
- **Cliente Dart para interação com a API**, localizado em `message_app/main.dart`
- O servidor API é executado como um executável `.exe` em `message_app/message_serve/bin/server.exe`
- Toda comunicação ocorre via HTTP em `http://localhost:8080`

---

## Como iniciar o servidor

1. Navegue até a pasta do servidor:

```bash
cd message_app/message_serve/bin
```

2. Execute o servidor:

- No Windows:

```bash
./server.exe
```

- No Linux/macOS (caso compile para esses sistemas):

```bash
./server
```

3. O servidor ficará escutando em `http://localhost:8080`

---

## Como usar o cliente Dart (`main.dart`)

O arquivo `main.dart` contém um menu interativo via terminal para usar as funcionalidades da API. Ele faz requisições HTTP para o servidor em `localhost:8080`.

### Funcionalidades disponíveis:

![image](https://github.com/user-attachments/assets/c840fa71-8b7b-45d3-b438-803cf024fa02)

### Como rodar o cliente

Na pasta raiz do projeto (`message_app`), execute:

```bash
dart run main.dart
```

O programa apresentará o menu para interação.

---

## Endpoints da API usados no cliente

- `POST /login` — Login do usuário (necessário para obter o token)
- `POST /logout` — Logout do usuário (token obrigatório)
- `GET /salas` — Lista todas as salas (token obrigatório)
- `POST /sala` — Cria ou edita uma sala (token obrigatório)
- `POST /sala/entrar/<codigo>` — Entrar numa sala (token obrigatório)
- `POST /sala/sair/<codigo>` — Sair de uma sala (token obrigatório)
- `GET /sala/<codigo>` — Ver dados de uma sala (token obrigatório)
- `DELETE /sala/<codigo>` — Apagar uma sala (token obrigatório)
- `POST /sala/mensagem/<codigo>` — Enviar mensagem para uma sala (token obrigatório)

---

## Requisitos

- Dart SDK instalado ([https://dart.dev/get-dart](https://dart.dev/get-dart))
- Executável do servidor rodando antes de usar o cliente (`server.exe`)

---

## Observações

- Para fazer qualquer ação, exceto login, o token retornado no login deve ser usado no cabeçalho `Authorization`.
- O cliente interativo armazena temporariamente o token para realizar as operações.
- O servidor deve estar rodando no endereço e porta padrão (`http://localhost:8080`).

