import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'users.dart';
import 'salas.dart';

// Configure routes.
final _router =
Router()
  ..post('/login', _loginHandler)
  ..post('/logout', _logoutHandler)
  ..get('/salas', _listarSalasHandler)
  ..post('/sala', _atualizarSalaHandler)
  ..delete('/sala/<codigo>', _apagarSalaHandler)
  ..get('/sala/<codigo>', _situacaoSalaHandler)
  ..post('/sala/entrar/<codigo>', _entrarSalaHandler)
  ..post('/sala/sair/<codigo>', _sairSalaHandler)
  ..post('/sala/mensagem/<codigo>', _enviarMensagemSalaHandler)
  ..get('/', _rootHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

// Recebe as requisições de login
Future<Response> _loginHandler(Request request) async {
  try {
    final credenciais = jsonDecode(await request.readAsString());
    final sessao = await GerenciadorDeSessoes.getInstance().login(
      credenciais['login'],
      credenciais['senha'],
    );
    return Response.ok(
      jsonEncode(sessao.toMap()),
      headers: {'Content-Type': 'application/json'},
    );
  } on CredenciaisInvalidasException catch (e) {
    return Response.unauthorized(e.toString());
  } catch (e) {
    return Response.internalServerError(body: e.toString());
  }
}

// Recebe as requisições de logout
Future<Response> _logoutHandler(Request request) async {
  final token = request.headers['Authorization'];
  if (token == null) {
    return Response.unauthorized('nao autorizado');
  }
  try {
    await GerenciadorDeSessoes.getInstance().logout(token);
    return Response.ok('', headers: {'Content-Type': 'text/plain'});
  } on SessaoInvalidaException catch (e) {
    return Response.unauthorized(e.toString());
  } catch (e) {
    return Response.internalServerError(body: e.toString());
  }
}

// DELETE /sala
Future<Response> _apagarSalaHandler(Request request) async {
  final gerenciador = GerenciadorDeSalas.getInstance();
  try {
    final sessao = request.context['sessao'] as Sessao;
    final usuario = sessao.usuario;
    final codigoDaSala = request.params['codigo'] ?? '';
    final sala = await gerenciador.apagarSala(usuario, codigoDaSala);
    return Response.ok('', headers: {'Content-Type': 'text/plain'});
  } on SalaNaoEncontradaException catch (e) {
    return Response.notFound(e.toString());
  } on AcaoNaoAutorizadaException catch (e) {
    return Response.forbidden(e.toString());
  } catch (e) {
    return Response.internalServerError(body: e.toString());
  }
}

// Cadastra ou atualiza uma sala.
Future<Response> _atualizarSalaHandler(Request request) async {
  final gerenciador = GerenciadorDeSalas.getInstance();
  try {
    final sessao = request.context['sessao'] as Sessao;
    final dados = jsonDecode(await request.readAsString());
    final nome = dados['nome'] as String;
    final vagas = dados['vagas'] as int;
    final sala = dados['codigo'] as String?;
    final Sala resultado;

    // verificar se é uma nova sala
    if (sala == null) {
      resultado = await gerenciador.criarSala(sessao.usuario, nome, vagas);
    } else {
      resultado = await gerenciador.atualizarSala(
        sala,
        sessao.usuario,
        nome,
        vagas,
      );
    }

    return Response.ok(
      jsonEncode(resultado.toMap()),
      headers: {'Content-Type': 'application/json'},
    );
  } on SalaNaoEncontradaException catch (e) {
    return Response.notFound(e.toString());
  } on AcaoNaoAutorizadaException catch (e) {
    return Response.forbidden(e.toString());
  } catch (e) {
    return Response.internalServerError(body: e.toString());
  }
}

// Usuario entra em sala
Future<Response> _entrarSalaHandler(Request request) async {
  final gerenciador = GerenciadorDeSalas.getInstance();
  try {
    final sessao = request.context['sessao'] as Sessao;
    final usuario = sessao.usuario;
    final codigoDaSala = request.params['codigo'] ?? '';
    final sala = await gerenciador.entrarEmSala(codigoDaSala, usuario);
    return Response.ok(
      jsonEncode(sala.toMap()),
      headers: {'Content-Type': 'application/json'},
    );
  } on SalaNaoEncontradaException catch (e) {
    return Response.notFound(e.toString());
  } on AcaoNaoAutorizadaException catch (e) {
    return Response.forbidden(e.toString());
  } on SalaLotadaException catch (e) {
    return Response.forbidden(e.toString());
  } catch (e) {
    return Response.internalServerError(body: e.toString());
  }
}

// Enviar uma mensagem para uma sala
Future<Response> _enviarMensagemSalaHandler(Request request) async {
  final gerenciador = GerenciadorDeSalas.getInstance();
  try {
    final sessao = request.context['sessao'] as Sessao;
    final usuario = sessao.usuario;
    final codigoDaSala = request.params['codigo'] ?? '';
    final conteudo = jsonDecode(await request.readAsString());
    final mensagem = await gerenciador.enviarMensagem(
      usuario,
      codigoDaSala,
      conteudo['mensagem'],
    );
    return Response.ok(
      jsonEncode(mensagem.toMap()),
      headers: {'Content-Type': 'application/json'},
    );
  } on SalaNaoEncontradaException catch (e) {
    return Response.notFound(e.toString());
  } on AcaoNaoAutorizadaException catch (e) {
    return Response.forbidden(e.toString());
  } catch (e) {
    return Response.internalServerError(body: e.toString());
  }
}

// Usuario sair de sala
Future<Response> _sairSalaHandler(Request request) async {
  final gerenciador = GerenciadorDeSalas.getInstance();
  try {
    final sessao = request.context['sessao'] as Sessao;
    final usuario = sessao.usuario;
    final codigoDaSala = request.params['codigo'] ?? '';
    final sala = await gerenciador.sairDaSala(codigoDaSala, usuario);
    return Response.ok(
      jsonEncode(sala.toMap()),
      headers: {'Content-Type': 'application/json'},
    );
  } on SalaNaoEncontradaException catch (e) {
    return Response.notFound(e.toString());
  } on AcaoNaoAutorizadaException catch (e) {
    return Response.forbidden(e.toString());
  } catch (e) {
    return Response.internalServerError(body: e.toString());
  }
}

// Consulta situação de uma sala
Future<Response> _situacaoSalaHandler(Request request) async {
  final gerenciador = GerenciadorDeSalas.getInstance();
  try {
    final codigoDaSala = request.params['codigo'] ?? '';
    final sala = await gerenciador.carregarSala(codigoDaSala);
    return Response.ok(
      jsonEncode(sala.toMap()),
      headers: {'Content-Type': 'application/json'},
    );
  } on SalaNaoEncontradaException catch (e) {
    return Response.notFound(e.toString());
  } catch (e) {
    return Response.internalServerError(body: e.toString());
  }
}

// Listar salas ativas.
Future<Response> _listarSalasHandler(Request request) async {
  final gerenciador = GerenciadorDeSalas.getInstance();
  try {
    final salas = await gerenciador.listarSalasAtivas();
    return Response.ok(
      jsonEncode(salas.map((i) => i.toMap()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: e.toString());
  }
}

// Handler Function(Handler innerHandler)
Handler _middlewareDeSeguranca(Handler handler) {
  final gerenciador = GerenciadorDeSessoes.getInstance();
  return (Request request) async {
    // A requisição de login não precisa de cabecalho de seguranca
    if (request.requestedUri.path == '/login') {
      final resposta = await handler(request);
      return resposta.change(
        headers: {...resposta.headers, 'Access-Control-Allow-Origin': '*'},
      );
    }
    if (!request.headers.containsKey('Authorization')) {
      return Response.unauthorized('não autorizado');
    }
    final token = request.headers['Authorization']!;
    try {
      final sessao = await gerenciador.carregarSessao(token);
      final resposta = await handler(
        request.change(context: {'sessao': sessao}),
      );
      return resposta.change(
        headers: {...resposta.headers, 'Access-Control-Allow-Origin': '*'},
      );
    } on SessaoInvalidaException catch (e) {
      return Response.unauthorized(e.toString());
    } catch (e) {
      return Response.internalServerError();
    }
  };
}

Future<void> main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_middlewareDeSeguranca)
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
