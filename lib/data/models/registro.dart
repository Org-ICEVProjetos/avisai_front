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
  final String photoPath;
  final String? observation;
  final StatusValidacao status;
  final bool sincronizado;
  final String? validadoPorUsuarioId;
  final DateTime? dataValidacao;
  final String? resposta; // NOVA PROPRIEDADE

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
    required this.photoPath,
    this.observation,
    this.status = StatusValidacao.pendente,
    this.sincronizado = false,
    this.validadoPorUsuarioId,
    this.dataValidacao,
    this.resposta, // ADICIONAR AQUI
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
    String? photoPath,
    String? observation,
    StatusValidacao? status,
    bool? sincronizado,
    String? validadoPorUsuarioId,
    DateTime? dataValidacao,
    String? resposta, // ADICIONAR AQUI
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
      photoPath: photoPath ?? this.photoPath,
      observation: observation ?? this.observation,
      status: status ?? this.status,
      sincronizado: sincronizado ?? this.sincronizado,
      validadoPorUsuarioId: validadoPorUsuarioId ?? this.validadoPorUsuarioId,
      dataValidacao: dataValidacao ?? this.dataValidacao,
      resposta: resposta ?? this.resposta, // ADICIONAR AQUI
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
      'photoPath': photoPath,
      'observation': observation,
      'status': _stringFromSatus(status),
      'sincronizado': sincronizado ? 1 : 0,
      'validadoPorUsuarioId': validadoPorUsuarioId,
      'dataValidacao': dataValidacao?.toIso8601String(),
      'resposta': resposta, // ADICIONAR AQUI
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
      'photoPath': photoPath,
      'observation': observation,
      'status': _stringFromSatus(status),
      'synchronizedStatus': sincronizado ? 1 : 0,
      'validatedByUserId': validadoPorUsuarioId,
      'validationDate': dataValidacao?.toIso8601String(),
      'response': resposta, // MAPEAMENTO PARA API
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
    final String photoPath =
        isApiJson ? (json['photoPath'] ?? '') : (json['photoPath'] ?? '');
    final String? observation = json['observation'];
    final String? resposta = isApiJson ? json['response'] : json['resposta'];

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
      photoPath: photoPath,
      observation: _normalizarTexto(observation),
      status: _statusFromString(json['status'] ?? 'PENDENTE_VALIDACAO'),
      resposta: _normalizarTexto(resposta),
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
