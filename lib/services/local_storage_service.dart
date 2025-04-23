import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import '../data/models/registro.dart';

import '../data/models/usuario.dart';
import 'location_service.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'cidadao_vigilante.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE usuarios (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        cpf TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        senha TEXT NOT NULL
      )
    ''');

    // Tabela de registros
    await db.execute('''
      CREATE TABLE registros (
        id TEXT PRIMARY KEY,
        usuarioId TEXT,
        usuarioNome TEXT NOT NULL,
        categoria TEXT NOT NULL,
        dataHora TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        endereco TEXT,
        rua TEXT,
        bairro TEXT,
        cidade TEXT,
        caminhoFoto TEXT NOT NULL,
        status TEXT NOT NULL,
        sincronizado INTEGER NOT NULL,
        validadoPorUsuarioId TEXT,
        dataValidacao TEXT,
        FOREIGN KEY (usuarioId) REFERENCES usuarios (id)
      )
    ''');
  }

  // Métodos para Usuário
  Future<Usuario?> getUsuario(String cpf) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'cpf = ?',
      whereArgs: [cpf],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromJson(maps.first);
    }
    return null;
  }

  Future<String> insertUsuario(Usuario usuario) async {
    final db = await database;
    await db.insert(
      'usuarios',
      usuario.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return usuario.id!;
  }

  Future<void> updateUsuario(Usuario usuario) async {
    final db = await database;
    await db.update(
      'usuarios',
      usuario.toJson(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
  }

  // Métodos para Registro
  Future<List<Registro>> getRegistros(
      {bool apenasNaoSincronizados = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'registros',
      where: apenasNaoSincronizados ? 'sincronizado = 0' : null,
    );

    return List.generate(maps.length, (i) {
      return Registro.fromJson(maps[i]);
    });
  }

  Future<List<Registro>> getRegistrosProximos(double latitude, double longitude,
      double raioMetros, CategoriaIrregularidade categoria) async {
    // Dada a complexidade de calcular distâncias em SQL para SQLite,
    // vamos buscar todos os registros da categoria e filtrar em memória
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'registros',
      where: 'categoria = ?',
      whereArgs: [categoria.toString()],
    );

    // Converter para objetos Registro
    final registros = List.generate(maps.length, (i) {
      return Registro.fromJson(maps[i]);
    });

    // Filtrar por distância usando o LocationService
    final locationService = LocationService();
    return registros.where((registro) {
      final distancia = locationService.calculateDistance(
          latitude, longitude, registro.latitude, registro.longitude);
      return distancia <= raioMetros;
    }).toList();
  }

  Future<String> insertRegistro(Registro registro) async {
    final db = await database;
    await db.insert(
      'registros',
      registro.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return registro.id!;
  }

  Future<void> updateRegistro(Registro registro) async {
    final db = await database;
    await db.update(
      'registros',
      registro.toJson(),
      where: 'id = ?',
      whereArgs: [registro.id],
    );
  }

  Future<void> marcarRegistroComoSincronizado(String registroId) async {
    final db = await database;
    await db.update(
      'registros',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [registroId],
    );
  }

  Future<void> validarRegistro(String registroId, String validadorId) async {
    final db = await database;
    await db.update(
      'registros',
      {
        'status': StatusValidacao.validado.toString(),
        'validadoPorUsuarioId': validadorId,
        'dataValidacao': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [registroId],
    );
  }

  Future<void> deleteRegistro(String id) async {
    final db = await database;
    await db.delete(
      'registros',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
