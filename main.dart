import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaansi/yaansi.dart';

const String httpLogin = 'http://localhost:8080/login';
const String httpLogout = 'http://localhost:8080/logout';
const String httpalas = 'http://localhost:8080/salas';
const String httpCriarSala = 'http://localhost:8080/sala';
const String httpEditarSala = 'http://localhost:8080/sala';
const String httpEntrarNaSala = 'http://localhost:8080/sala/entrar/';
const String httpairDaSala = 'http://localhost:8080/sala/sair/';
const String httpDadosSala = 'http://localhost:8080/sala/';
const String httpApagarSala = 'http://localhost:8080/sala/';
const String httpEnviarMsg = 'http://localhost:8080/sala/mensagem/';

void main(List<String> arguments) async {
  String token = '';
  String salaEntrada = '';
  bool continuePerguntando = true;

  while (continuePerguntando) {
    print('\n--- Menu ---');
    print('(1) Fazer login');
    print('(2) Fazer logout');
    print('(3) Listar as salas');
    print('(4) Criar sala');
    print('(5) Editar sala');
    print('(6) Entrar na sala');
    print('(7) Sair da sala');
    print('(8) Ver dados da sala');
    print('(9) Apagar a sala');
    print('(10) Enviar mensagem');
    print('(0) Sair');
    stdout.write('Sua resposta: ');
    String? resposta = stdin.readLineSync();

    switch (resposta) {
      case '1':
        token = await obterToken() ?? '';
        break;
      case '2':
        await fazerLogout(token);
        break;
      case '3':
        await listarSalas(token);
        break;
      case '4':
        await criarSala(token);
        break;
      case '5':
        await editarSala(token);
        break;
      case '6':
        salaEntrada = await entrarNaSala(token) ?? '';
        print(salaEntrada);
        break;
      case '7':
        await sairDaSala(token);
        break;
      case '8':
        await carregarDadosSala(token);
        break;
      case '9':
        await apagarSala(token);
        break;
      case '10':
        await enviarMensagem(token, salaEntrada);
        break;
      case '0':
        continuePerguntando = false;
        break;
      default:
        print(red('Opção inválida. Tente novamente.'));
    }
  }
}

//Faz login
Future<String?> obterToken() async {
  Uri uri = Uri.parse(httpLogin); //Obtem Uri
  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "login": "alexandre",
      "senha": "alXe",
    }),
  );
  //Verificação e retorno
  if (response.statusCode == 200) {
    print(green('Login realizado com sucesso.'));

    var tokenUsuario = json.decode(response.body);
    return tokenUsuario['token'] as String?; //Retorna o token do usuario
  } else {
    print(red('Erro ao obter token de login: ${response.body}'));
    return null;
  }
}

//Faz logout do usuario
Future<void> fazerLogout(String token) async {
  //Verificação de login
  if (token.isEmpty) {
    print(red('Você precisa fazer login primeiro.'));
    return;
  }
  Uri uri = Uri.parse(httpLogout); //Obter Uri
  final response = await http
      .post(uri, headers: {'Authorization': token}); //Envia a requisição
  //Verificação e retorno
  if (response.statusCode == 200) {
    print(green('Logout com sucesso!'));
  } else {
    print(red('Erro ao fazer logout: ${response.body}'));
  }
}

//Lista salas
Future<void> listarSalas(String token) async {
  //Verificação de login
  if (token.isEmpty) {
    print(red('Você precisa fazer login primeiro.'));
    return;
  }
  Uri uri = Uri.parse(httpalas); //Obter Uri
  final response =
      await http.get(uri, headers: {'Authorization': token}); //Metodo get
  //Verificação e retorno
  if (response.statusCode == 200) {
    print('Salas disponíveis:');
    final salas = json.decode(response.body) as List; //Retorna os dados em List
    var minhasSalas = Salas(salas);
    minhasSalas.salas.forEach((element) {
      var sala = Sala.fromJson(element);
      print(
          'Codigo: ${sala.codigo}, Nome: ${sala.nome}, Vagas: ${sala.vagas}, Adminstrador ${sala.administrador}, Mensagem ${sala.mensagens}');
    });
  } else {
    print(red('Erro ao listar salas: ${response.body}'));
  }
}

//Criar sala
Future<void> criarSala(String token) async {
  //Verificação de login
  if (token.isEmpty) {
    print(red('Você precisa fazer login primeiro.'));
    return;
  }
  //Nome da sala
  stdout.write('Nome da sala: ');
  String? salaNome = stdin.readLineSync();
  //Quantidade de vaga
  stdout.write('Quantidade de vagas: ');
  String? vagaSala = stdin.readLineSync();
  int? vagaInt = int.tryParse(vagaSala ?? '');

  Uri uri = Uri.parse(httpCriarSala); //Obter Uri
  final response = await http.post(
    //Inserir sala nova
    uri,
    body: jsonEncode({"nome": salaNome, "vagas": vagaInt}),
    headers: {'Authorization': token},
  );
  //Verificação e retorno
  if (response.statusCode == 200) {
    print(green('Sala criada com sucesso.'));
  } else {
    print(red('Erro ao criar a sala: ${response.body}'));
  }
}

//Classe editar sala
Future<void> editarSala(String token) async {
  //Verificação de login
  if (token.isEmpty) {
    print(red('Você precisa fazer login primeiro.'));
    return;
  }
  //Obter codigo da sala
  stdout.write('Digite o código da sala que gostaria de editar: ');
  String? codigoSala = stdin.readLineSync();
  //Novo nome
  stdout.write('Novo nome: ');
  String? salaNome = stdin.readLineSync();
  //Quantidade de vaga
  stdout.write('Nova quantidade de vagas: ');
  String? vagaSala = stdin.readLineSync();
  int? vagaSalaInt = int.tryParse(vagaSala ?? '');

  Uri uri = Uri.parse(httpEditarSala); //Obter Uri
  final response = await http.post(
    //Fazer alteração
    uri,
    body: jsonEncode(
        {"codigo": codigoSala, "nome": salaNome, "vagas": vagaSalaInt}),
    headers: {'Authorization': token},
  );
  //Verificação e retorno
  if (response.statusCode == 200) {
    print(green("Sala editada com sucesso."));
  } else {
    print(red('Erro ao editar a sala: ${response.body}'));
  }
}

//Entrar na sala
Future<String?> entrarNaSala(String token) async {
  //Verificação de login
  if (token.isEmpty) {
    print(red('Você precisa fazer login primeiro.'));
    return null;
  }
  //Codigo da sala
  stdout.write('Digite o código da sala para entrar: ');
  String? codigoSala = stdin.readLineSync();

  if (codigoSala == null || codigoSala.isEmpty) {
    //Se a sala nao encontrada
    print(red('Código da sala inválido.'));
    return null;
  }

  Uri uri = Uri.parse(httpEntrarNaSala + codigoSala); //Obtem uri
  final response =
      await http.post(uri, headers: {'Authorization': token}); //Metodo post
  //Verificação e retorno
  if (response.statusCode == 200) {
    print(green('Entrou na sala com sucesso.'));
    var salaCodigo = json.decode(response.body);
    return salaCodigo['codigo'] as String?; //Retorna a sala
  } else {
    print(red('Erro ao entrar na sala: ${response.body}'));
  }
}

//Sair da sala
Future<void> sairDaSala(String token) async {
  //Verificação de login
  if (token.isEmpty) {
    print(red('Você precisa fazer login primeiro.'));
    return;
  }
  //Codigo para sair da sala
  stdout.write('Digite o código da sala para sair: ');
  String? codigoSala = stdin.readLineSync();

  if (codigoSala == null || codigoSala.isEmpty) {
    //verifica se vazio
    print(red('Código da sala inválido.'));
    return;
  }

  Uri uri = Uri.parse(httpairDaSala + codigoSala); //Obtem Uri
  final response =
      await http.post(uri, headers: {'Authorization': token}); //Metodo post
  //Verificação e retorno
  if (response.statusCode == 200) {
    print(green('Saiu da sala com sucesso.'));
  } else {
    print('Erro ao sair da sala: ${response.body}');
  }
}

//Carrega as salas
Future<void> carregarDadosSala(String token) async {
  if (token.isEmpty) {
    print(red('Você precisa fazer login primeiro.'));
    return;
  }

  stdout.write('Digite o código da sala para ver os dados: ');
  String? codigoSala = stdin.readLineSync();

  if (codigoSala == null || codigoSala.isEmpty) {
    print(red('Código da sala inválido.'));
    return;
  }

  Uri uri = Uri.parse(httpDadosSala + codigoSala);
  final response = await http.get(uri, headers: {'Authorization': token});
  //Verificação e retorno
  if (response.statusCode == 200) {
    print(green('Dados da sala:'));
    print(response.body);
  } else {
    print(red('Erro ao carregar dados da sala: ${response.body}'));
  }
}

//Apaga a sala
Future<void> apagarSala(String token) async {
  //Verificação de login
  if (token.isEmpty) {
    print(red('Você precisa fazer login primeiro.'));
    return;
  }
  //Codigo para apagar sala
  stdout.write('Digite o código da sala apagar: ');
  String? codigoSala = stdin.readLineSync();

  if (codigoSala == null || codigoSala.isEmpty) {
    //Se a sala nao encontrada
    print(red('Código da sala inválido.'));
    return null;
  }

  Uri uri = Uri.parse(httpApagarSala + codigoSala); //Obtem uri
  final response =
      await http.delete(uri, headers: {'Authorization': token}); //Metodo get
  //Verificação e retorno
  if (response.statusCode == 200) {
    print(green('Sala apagada com sucesso:'));
    print(response.body);
  } else {
    print(red('Erro ao apagar sala: ${response.body}'));
  }
}

//Enviar mensagem
Future<void> enviarMensagem(String token, String codigoSala) async {
  //Verificação de login
  if (token.isEmpty) {
    print(red('Você precisa fazer login primeiro.'));
    return;
  }
  if (codigoSala.isEmpty || codigoSala == '') {
    print('Codigo da sala esta vezio');
  }
  //Enviar mensagem
  stdout.write('Enviar mensagem: ');
  String? mensagem = stdin.readLineSync() ?? '';

  Uri uri = Uri.parse(httpEnviarMsg + codigoSala); //Obtem uri
  final response = await http.post(uri,
      body: jsonEncode({'mensagem': mensagem}),
      headers: {'Authorization': token}); //Metodo get
  //Verificação e retorno
  if (response.statusCode == 200) {
    print(response.body);
  } else {
    print(red('Erro ao enviar mensagem: ${response.body}'));
  }
}

class Salas {
  List salas = [];
  Salas(this.salas);
}

class Sala {
  final String codigo;
  final String nome;
  final int vagas;
  final String administrador;
  final List participantes;
  final List mensagens;

  Sala({
    required this.codigo,
    required this.nome,
    required this.vagas,
    required this.administrador,
    required this.participantes,
    required this.mensagens,
  });

  factory Sala.fromJson(Map<String, dynamic> json) {
    return Sala(
      codigo: json['codigo'],
      nome: json['nome'],
      vagas: json['vagas'],
      administrador: json['administrador'],
      participantes: json['participantes'],
      mensagens: json['mensagens'],
    );
  }

  @override
  String toString() {
    return 'Sala: $nome, Código: $codigo, Vagas: $vagas, Admin: $administrador';
  }
}
