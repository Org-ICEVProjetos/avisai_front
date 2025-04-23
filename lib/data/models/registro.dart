enum StatusValidacao { validado, naoValidado, pendente }

enum CategoriaIrregularidade { buraco, posteDefeituoso, lixoIrregular }

class Registro {
  final String? id;
  final String? usuarioId;
  final String usuarioNome;
  final CategoriaIrregularidade categoria;
  final DateTime dataHora;
  final double latitude;
  final double longitude;
  final String? endereco;
  final String? rua;
  final String? bairro;
  final String? cidade;
  final String caminhoFoto;
  final StatusValidacao status;
  final bool sincronizado;
  final String? validadoPorUsuarioId;
  final DateTime? dataValidacao;

  Registro({
    this.id,
    this.usuarioId,
    required this.usuarioNome,
    required this.categoria,
    required this.dataHora,
    required this.latitude,
    required this.longitude,
    this.endereco,
    this.rua,
    this.bairro,
    this.cidade,
    required this.caminhoFoto,
    this.status = StatusValidacao.pendente,
    this.sincronizado = false,
    this.validadoPorUsuarioId,
    this.dataValidacao,
  });

  Registro copyWith({
    String? id,
    String? usuarioId,
    String? usuarioNome,
    CategoriaIrregularidade? categoria,
    DateTime? dataHora,
    double? latitude,
    double? longitude,
    String? endereco,
    String? rua,
    String? bairro,
    String? cidade,
    String? caminhoFoto,
    StatusValidacao? status,
    bool? sincronizado,
    String? validadoPorUsuarioId,
    DateTime? dataValidacao,
  }) {
    return Registro(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      categoria: categoria ?? this.categoria,
      dataHora: dataHora ?? this.dataHora,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      endereco: endereco ?? this.endereco,
      rua: rua ?? this.rua,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      caminhoFoto: caminhoFoto ?? this.caminhoFoto,
      status: status ?? this.status,
      sincronizado: sincronizado ?? this.sincronizado,
      validadoPorUsuarioId: validadoPorUsuarioId ?? this.validadoPorUsuarioId,
      dataValidacao: dataValidacao ?? this.dataValidacao,
    );
  }

  // Converter para JSON para salvar no banco local ou enviar para API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'categoria': categoria.toString(),
      'dataHora': dataHora.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'endereco': endereco,
      'rua': rua,
      'bairro': bairro,
      'cidade': cidade,
      'caminhoFoto': caminhoFoto,
      'status': status.toString(),
      'sincronizado': sincronizado ? 1 : 0, // Converte boolean para int
      'validadoPorUsuarioId': validadoPorUsuarioId,
      'dataValidacao': dataValidacao?.toIso8601String(),
    };
  }

  // Criar a partir de JSON (do banco local ou API)
  factory Registro.fromJson(Map<String, dynamic> json) {
    return Registro(
      id: json['id'],
      usuarioId: json['usuarioId'],
      usuarioNome: json['usuarioNome'],
      categoria: _categoriaFromString(json['categoria']),
      dataHora: DateTime.parse(json['dataHora']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      endereco: json['endereco'],
      rua: json['rua'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      caminhoFoto: json['caminhoFoto'],
      status: _statusFromString(json['status']),
      sincronizado: json['sincronizado'] == 1, // Converte int para boolean
      validadoPorUsuarioId: json['validadoPorUsuarioId'],
      dataValidacao:
          json['dataValidacao'] != null
              ? DateTime.parse(json['dataValidacao'])
              : null,
    );
  }
  static CategoriaIrregularidade _categoriaFromString(String categoria) {
    switch (categoria) {
      case 'CategoriaIrregularidade.buraco':
        return CategoriaIrregularidade.buraco;
      case 'CategoriaIrregularidade.posteDefeituoso':
        return CategoriaIrregularidade.posteDefeituoso;
      case 'CategoriaIrregularidade.lixoIrregular':
        return CategoriaIrregularidade.lixoIrregular;
      default:
        return CategoriaIrregularidade.lixoIrregular;
    }
  }

  static StatusValidacao _statusFromString(String status) {
    switch (status) {
      case 'StatusValidacao.validado':
        return StatusValidacao.validado;
      case 'StatusValidacao.naoValidado':
        return StatusValidacao.naoValidado;
      case 'StatusValidacao.pendente':
        return StatusValidacao.pendente;
      default:
        return StatusValidacao.pendente;
    }
  }
}
