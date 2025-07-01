import 'package:uuid/v4.dart';

/// Usuario da aplicação
class Usuario {
  const Usuario._(this.nome, this.login, this._senha);

  /// Nome do usuario
  final String nome;

  /// Login utilizado para autenticação
  final String login;

  /// Chave secreta para autenticação
  final String _senha;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Usuario &&
          runtimeType == other.runtimeType &&
          login == other.login;

  @override
  int get hashCode => login.hashCode;

  /// Retorna os dados do usuario serializados em um map
  Map<String, dynamic> toMap() {
    return {'nome': nome, 'login': login};
  }
}

/// Sessão que indica que um usuario pode acessar a aplicação
class Sessao {
  const Sessao({required this.token, required this.usuario});

  /// Token identificador da sessão do usuario
  final String token;

  /// Usuario autenticado da sessão
  final Usuario usuario;

  /// Retorna os dados da sessão serializados em um map
  Map<String, dynamic> toMap() {
    return {'token': token, 'usuario': usuario.toMap()};
  }
}

/// Exceção lançada em logins mal sucedidos
class CredenciaisInvalidasException implements Exception {
  const CredenciaisInvalidasException();

  @override
  String toString() {
    return 'Credenciais invalidas';
  }
}

/// Exceção lançada em logins mal sucedidos
class SessaoInvalidaException implements Exception {
  const SessaoInvalidaException();

  @override
  String toString() {
    return 'Sessao invalida';
  }
}

/// Serviço responsavel pelo controle das sessões dos usuarios.
/// Singleton.
class GerenciadorDeSessoes {
  GerenciadorDeSessoes._();

  // Mantem a instancia unica do gerenciador de sessoes
  static GerenciadorDeSessoes? _instance;

  /// Retorna instancia do gerenciador de sessao
  static GerenciadorDeSessoes getInstance() {
    _instance ??= GerenciadorDeSessoes._();
    return _instance!;
  }

  // Lista de usuarios da aplicação
  static const _users = [
    Usuario._('Alexandre', 'alexandre', 'alXe'),
    Usuario._('Usuario', 'usuario', 'senha'),
  ];

  // Armazena as sessões ativas dos usuarios
  final Map<String, Sessao> _sessoes = {};
  final _geradorTokens = UuidV4();

  /// Realiza a autenticação do usuário
  Future<Sessao> login(String login, String senha) async {
    for (final usuario in _users) {
      if (usuario.login == login && usuario._senha == senha) {
        final sessao = Sessao(
          token: _geradorTokens.generate(),
          usuario: usuario,
        );
        _sessoes[sessao.token] = sessao;
        return sessao;
      }
    }

    throw const CredenciaisInvalidasException();
  }

  /// Elimina a sessão do usuario
  Future<void> logout(String token) async {
    if (!_sessoes.containsKey(token)) {
      throw const SessaoInvalidaException();
    }
    _sessoes.remove(token);
  }

  /// Retorna a sessão associada ao token
  Future<Sessao> carregarSessao(String token) async {
    if (!_sessoes.containsKey(token)) {
      throw const SessaoInvalidaException();
    }
    return _sessoes[token]!;
  }
}
