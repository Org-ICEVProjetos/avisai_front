class Usuario {
  final String? id;
  final String nome;
  final String cpf;
  final String email;
  final String senha;

  Usuario({
    this.id,
    required this.nome,
    required this.cpf,
    required this.email,
    required this.senha,
  });

  Usuario copyWith({
    String? id,
    String? nome,
    String? cpf,
    String? email,
    String? senha,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cpf: cpf ?? this.cpf,
      email: email ?? this.email,
      senha: senha ?? this.senha,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'cpf': cpf, 'email': email, 'senha': senha};
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? '',
      nome: _corrigirTextoAcentuado(json['name'] ?? ''),
      cpf: json['cpf'] ?? '',
      email: json['email'] ?? '',
      senha: json['senha'] ?? '',
    );
  }

  static String _corrigirTextoAcentuado(String texto) {
    final Map<String, String> substituicoes = {
      'Ã£': 'ã',
      'Ã¡': 'á',
      'Ã©': 'é',
      'Ã³': 'ó',
      'Ãº': 'ú',
      'Ã§': 'ç',
      'Ã': 'Á',
      'Ãª': 'ê',
      'Ã¢': 'â',
      'Ãµ': 'õ',
      'Ã­': 'í',
      'Ã´': 'ô',
    };

    String resultado = texto;
    substituicoes.forEach((padrao, substituto) {
      resultado = resultado.replaceAll(padrao, substituto);
    });

    return resultado;
  }

  @override
  String toString() {
    return 'Usuario{id: $id, nome: $nome, cpf: $cpf, email: $email}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario &&
        other.id == id &&
        other.nome == nome &&
        other.cpf == cpf &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nome.hashCode ^ cpf.hashCode ^ email.hashCode;
  }
}
