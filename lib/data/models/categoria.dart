class Categoria {
  final String id;
  final String nome;
  final String icone;
  final String descricao;
  final bool ativo;

  Categoria({
    required this.id,
    required this.nome,
    required this.icone,
    this.descricao = '',
    this.ativo = true,
  });

  Categoria copyWith({
    String? id,
    String? nome,
    String? icone,
    String? descricao,
    bool? ativo,
  }) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      icone: icone ?? this.icone,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'icone': icone,
      'descricao': descricao,
      'ativo': ativo ? 1 : 0,
    };
  }

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nome: json['nome'],
      icone: json['icone'],
      descricao: json['descricao'] ?? '',
      ativo: json['ativo'] == 1 || json['ativo'] == true,
    );
  }

  static List<Categoria> getCategoriasDefault() {
    return [
      Categoria(
        id: 'buraco',
        nome: 'Buraco na via',
        icone: 'assets/icons/buraco.png',
        descricao: 'Buracos, crateras ou ondulações na via pública',
      ),
      Categoria(
        id: 'poste',
        nome: 'Poste com defeito',
        icone: 'assets/icons/poste.png',
        descricao: 'Postes de iluminação com problemas ou sem funcionamento',
      ),
      Categoria(
        id: 'lixo',
        nome: 'Descarte irregular',
        icone: 'assets/icons/lixo.png',
        descricao: 'Lixo descartado de forma irregular em vias públicas',
      ),
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
