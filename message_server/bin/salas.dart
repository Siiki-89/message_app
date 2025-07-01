import 'package:intl/intl.dart';
import 'package:uuid/v4.dart';

import 'users.dart';

final _formatarDatas = DateFormat('yyyy-MM-dd HH:mm:ss');

/// Exceção lançada caso tente manipular uma sala que não existe
class SalaNaoEncontradaException implements Exception {
  const SalaNaoEncontradaException();

  @override
  String toString() {
    return 'sala não encontrada';
  }
}

/// Exceção lançada caso tente manipular uma sala que não tem permissão
class AcaoNaoAutorizadaException implements Exception {
  const AcaoNaoAutorizadaException();

  @override
  String toString() {
    return 'voce nao tem autorização para realizar essa ação';
  }
}

/// Exceção lançada caso tente entrar em uma sala lotada
class SalaLotadaException implements Exception {
  const SalaLotadaException();

  @override
  String toString() {
    return 'essa sala está lotada';
  }
}

/// Mensagem enviada a uma sala
class Mensagem {
  /// Construtor padrão
  const Mensagem({
    required this.codigo,
    required this.conteudo,
    required this.criacao,
  });

  /// Codigo unico da imagem
  final String codigo;

  /// Conteudo da mensagem
  final String conteudo;

  /// Data e hora de criação dessa mensagem
  final DateTime criacao;

  /// Retorna os dados da sala serializados em um map
  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'mensagem': conteudo,
      'criacao': _formatarDatas.format(criacao),
    };
  }
}

/// Representa uma sala/lobby para partidas de jogos
class Sala {
  /// Construtor padrão
  const Sala({
    required this.codigo,
    required this.nome,
    required this.vagas,
    required this.criador,
    this.participantes = const {},
    this.mensagens = const [],
  });

  /// Código identificador unico da sala
  final String codigo;

  /// Nome da sala
  final String nome;

  /// Número maximo de vagas para a sala
  final int vagas;

  /// Usuário que criou a sala, e tem permissão para alterar os dados
  final Usuario criador;

  /// Contem os participantes que entraram na sala
  final Set<Usuario> participantes;

  /// Lista de mensagens da sala
  final List<Mensagem> mensagens;

  /// Retorna uma copia dessa sala, com os valores atualizados
  Sala copyWith({
    String? nome,
    int? vagas,
    Set<Usuario>? participantes,
    List<Mensagem>? mensagens,
  }) {
    return Sala(
      codigo: codigo,
      nome: nome ?? this.nome,
      vagas: vagas ?? this.vagas,
      criador: criador,
      participantes: Set.unmodifiable(participantes ?? this.participantes),
      mensagens: List.unmodifiable(mensagens ?? this.mensagens),
    );
  }

  /// Retorna os dados da sala serializados em um map
  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nome': nome,
      'vagas': vagas,
      'administrador': criador.nome,
      'participantes': participantes.map((i) => i.toMap()).toList(),
      'mensagens': mensagens.map((i) => i.toMap()).toList(),
    };
  }
}

/// Gerencia as salas
class GerenciadorDeSalas {
  GerenciadorDeSalas._();

  static GerenciadorDeSalas? _instance;

  static GerenciadorDeSalas getInstance() {
    _instance ??= GerenciadorDeSalas._();
    return _instance!;
  }

  // Mantêm todas as salas ativas
  final Map<String, Sala> _salasAtivas = {};
  final _geradorCodigos = UuidV4();

  /// Retorna uma lista com todas as salas ativas
  Future<List<Sala>> listarSalasAtivas() async {
    return List.unmodifiable(_salasAtivas.values);
  }

  /// Cria uma nova sala
  Future<void> apagarSala(Usuario criador, String codigoDaSala) async {
    final sala = _salasAtivas[codigoDaSala];
    if (sala == null) {
      throw const SalaNaoEncontradaException();
    }
    if (sala.criador != criador) {
      throw const AcaoNaoAutorizadaException();
    }
    _salasAtivas.remove(codigoDaSala);
  }

  /// Cria uma nova sala
  Future<Sala> criarSala(Usuario criador, String nome, int vagas) async {
    final codigo = _geradorCodigos.generate();
    final sala = Sala(
      codigo: codigo,
      nome: nome,
      vagas: vagas,
      criador: criador,
    );
    _salasAtivas[codigo] = sala;
    return sala;
  }

  /// Cria uma nova sala
  Future<Sala> atualizarSala(
    String codigoDaSala,
    Usuario criador,
    String nome,
    int vagas,
  ) async {
    final sala = _salasAtivas[codigoDaSala];
    if (sala == null) {
      throw const SalaNaoEncontradaException();
    }
    if (sala.criador != criador) {
      throw const AcaoNaoAutorizadaException();
    }
    final salaAtualizada = sala.copyWith(nome: nome, vagas: vagas);
    _salasAtivas[codigoDaSala] = salaAtualizada;
    return salaAtualizada;
  }

  /// Adiciona um usuario a uma sala
  Future<Sala> entrarEmSala(String codigoDaSala, Usuario usuario) async {
    final sala = _salasAtivas[codigoDaSala];
    if (sala == null) {
      throw const SalaNaoEncontradaException();
    }
    if (sala.criador == usuario) {
      throw const AcaoNaoAutorizadaException();
    }
    if (sala.participantes.length >= sala.vagas) {
      throw const SalaLotadaException();
    }
    final salaAtualizada = sala.copyWith(
      participantes: {...sala.participantes, usuario},
    );
    _salasAtivas[codigoDaSala] = salaAtualizada;
    return salaAtualizada;
  }

  /// Remove um usuario de uma sala
  Future<Sala> sairDaSala(String codigoDaSala, Usuario usuario) async {
    final sala = _salasAtivas[codigoDaSala];
    if (sala == null) {
      throw const SalaNaoEncontradaException();
    }
    if (sala.criador == usuario) {
      throw const AcaoNaoAutorizadaException();
    }
    final salaAtualizada = sala.copyWith(
      participantes: {...sala.participantes}..remove(usuario),
    );
    _salasAtivas[codigoDaSala] = salaAtualizada;
    return salaAtualizada;
  }

  /// Remove um usuario de uma sala
  Future<Sala> carregarSala(String codigoDaSala) async {
    final sala = _salasAtivas[codigoDaSala];
    if (sala == null) {
      throw const SalaNaoEncontradaException();
    }
    return sala;
  }

  /// Remove um usuario de uma sala
  Future<Mensagem> enviarMensagem(
    Usuario usuario,
    String codigoDaSala,
    String mensagem,
  ) async {
    final sala = _salasAtivas[codigoDaSala];
    if (sala == null) {
      throw const SalaNaoEncontradaException();
    }
    final isParticipante = sala.participantes.contains(usuario);
    final isCriador = sala.criador == usuario;
    if (!isParticipante && !isCriador) {
      throw const AcaoNaoAutorizadaException();
    }
    if (sala.participantes.length >= sala.vagas) {
      throw const SalaLotadaException();
    }
    final mensagemCriada = Mensagem(
      codigo: _geradorCodigos.generate(),
      conteudo: mensagem,
      criacao: DateTime.now(),
    );
    final salaAtualizada = sala.copyWith(
      mensagens: [...sala.mensagens, mensagemCriada],
    );
    _salasAtivas[codigoDaSala] = salaAtualizada;
    return mensagemCriada;
  }
}
