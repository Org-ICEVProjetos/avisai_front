enum StatusValidacao { validado, naoValidado, pendente, emRota, resolvido }

enum CategoriaIrregularidade { buraco, posteDefeituoso, lixoIrregular, outro }

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
  final String base64Foto;
  final String? observation; // NOVO CAMPO
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
    required this.base64Foto,
    this.observation, // NOVO PARÂMETRO
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
    String? base64Foto,
    String? observation, // NOVO
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
      base64Foto: base64Foto ?? this.base64Foto,
      observation: observation ?? this.observation, // NOVO
      status: status ?? this.status,
      sincronizado: sincronizado ?? this.sincronizado,
      validadoPorUsuarioId: validadoPorUsuarioId ?? this.validadoPorUsuarioId,
      dataValidacao: dataValidacao ?? this.dataValidacao,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'categoria': _stringFromCategoria(categoria),
      'dataHora': dataHora.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'endereco': endereco,
      'rua': rua,
      'bairro': bairro,
      'cidade': cidade,
      'base64Foto': base64Foto,
      'observation': observation, // NOVO
      'status': _stringFromSatus(status),
      'sincronizado': sincronizado ? 1 : 0,
      'validadoPorUsuarioId': validadoPorUsuarioId,
      'dataValidacao': dataValidacao?.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'category': _stringFromCategoria(categoria),
      'dataHora': dataHora.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'address': endereco,
      'street': rua,
      'neighborhood': bairro,
      'city': cidade,
      'photoPath': base64Foto,
      'observation': observation, // NOVO
      'status': _stringFromSatus(status),
      'synchronizedStatus': sincronizado ? 1 : 0,
      'validatedByUserId': validadoPorUsuarioId,
      'validationDate': dataValidacao?.toIso8601String(),
    };
  }

  factory Registro.fromJson(Map<String, dynamic> json) {
    final bool isApiJson =
        json.containsKey('userId') || json.containsKey('category');

    final String? id = json['id'];
    final String? usuarioId = isApiJson ? json['userId'] : json['usuarioId'];
    final String usuarioNome =
        isApiJson ? (json['userName'] ?? '') : (json['usuarioNome'] ?? '');
    final String categoriaStr =
        isApiJson ? (json['category'] ?? '') : (json['categoria'] ?? '');
    final CategoriaIrregularidade categoria = _categoriaFromString(
      categoriaStr,
    );
    final String endereco =
        isApiJson ? (json['address'] ?? '') : (json['endereco'] ?? '');
    final String rua = isApiJson ? (json['street'] ?? '') : (json['rua'] ?? '');
    final String bairro =
        isApiJson ? (json['neighborhood'] ?? '') : (json['bairro'] ?? '');
    final String cidade =
        isApiJson ? (json['city'] ?? '') : (json['cidade'] ?? '');
    final String base64Foto =
        isApiJson ? (json['photoPath'] ?? '') : (json['base64Foto'] ?? '');
    final String? observation = json['observation']; // NOVO

    return Registro(
      id: id,
      usuarioId: usuarioId,
      usuarioNome: _normalizarTexto(usuarioNome),
      categoria: categoria,
      dataHora: DateTime.parse(json['dataHora']),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      endereco: _normalizarTexto(endereco),
      rua: _normalizarTexto(rua),
      bairro: _normalizarTexto(bairro),
      cidade: _normalizarTexto(cidade),
      base64Foto: base64Foto,
      observation: _normalizarTexto(observation), // NOVO
      status: _statusFromString(json['status'] ?? 'PENDENTE_VALIDACAO'),
      sincronizado: isApiJson ? true : (json['sincronizado'] == 1),
      validadoPorUsuarioId:
          isApiJson ? json['validatedByUserId'] : json['validadoPorUsuarioId'],
      dataValidacao:
          json['dataValidacao'] != null
              ? DateTime.parse(json['dataValidacao'])
              : json['validationDate'] != null
              ? DateTime.parse(json['validationDate'])
              : null,
    );
  }
  // Função para normalizar textos com problemas de codificação
  static String _normalizarTexto(String? texto) {
    if (texto == null) return '';

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
      'NÃ£o': 'Não',
    };

    String resultado = texto;
    substituicoes.forEach((padrao, substituto) {
      resultado = resultado.replaceAll(padrao, substituto);
    });

    return resultado;
  }

  static CategoriaIrregularidade _categoriaFromString(String categoria) {
    switch (categoria) {
      case 'BURACO_VIA':
        return CategoriaIrregularidade.buraco;
      case 'POSTE_DEFEITO':
        return CategoriaIrregularidade.posteDefeituoso;
      case 'LIXO_DESCARTADO':
        return CategoriaIrregularidade.lixoIrregular;
      case 'OUTRO':
      default:
        return CategoriaIrregularidade.outro;
    }
  }

  static String _stringFromCategoria(CategoriaIrregularidade categoria) {
    switch (categoria) {
      case CategoriaIrregularidade.buraco:
        return "BURACO_VIA";
      case CategoriaIrregularidade.posteDefeituoso:
        return 'POSTE_DEFEITO';
      case CategoriaIrregularidade.lixoIrregular:
        return 'LIXO_DESCARTADO';

      case CategoriaIrregularidade.outro:
        return 'OUTRO';
    }
  }

  static StatusValidacao _statusFromString(String status) {
    switch (status) {
      case 'StatusValidacao.validado':
      case 'VALIDADO':
        return StatusValidacao.validado;
      case 'StatusValidacao.naoValidado':
      case 'NAO_VALIDADO':
        return StatusValidacao.naoValidado;
      case 'PENDENTE':
      case 'StatusValidacao.pendente':
        return StatusValidacao.pendente;
      case 'StatusValidacao.emRota':
      case 'EM_ROTA':
        return StatusValidacao.emRota;
      case 'StatusValidacao.resolvido':
      case 'RESOLVIDO':
        return StatusValidacao.resolvido;
      default:
        return StatusValidacao.pendente;
    }
  }

  static String _stringFromSatus(StatusValidacao status) {
    switch (status) {
      case StatusValidacao.pendente:
        return "PENDENTE";
      case StatusValidacao.validado:
        return "VALIDADO";
      case StatusValidacao.naoValidado:
        return "NAO_VALIDADO";
      case StatusValidacao.emRota:
        return "EM_ROTA";
      case StatusValidacao.resolvido:
        return "RESOLVIDO";
    }
  }
}
