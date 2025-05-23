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
    String path = join(documentsDirectory.path, 'avisai.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
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
  CREATE TABLE IF NOT EXISTS registros (
    id TEXT PRIMARY KEY,
    usuarioId TEXT,
    usuarioNome TEXT,
    categoria TEXT,
    dataHora TEXT,
    latitude REAL,
    longitude REAL,
    endereco TEXT,
    rua TEXT,
    bairro TEXT,
    cidade TEXT,
    base64Foto TEXT,
    observation TEXT,
    status TEXT,
    sincronizado INTEGER,
    validadoPorUsuarioId TEXT,
    dataValidacao TEXT
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
  Future<List<Registro>> getRegistros() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('registros');
    List<Registro> registros = List.generate(maps.length, (i) {
      return Registro.fromJson(maps[i]);
    });
    print(
      "LocalStorageService: Total de registros locais: ${registros.length}",
    );
    for (var reg in registros) {
      print(
        "LocalStorageService: Registro local - ID: ${reg.id}, usuarioId: ${reg.usuarioId}, sincronizado: ${reg.sincronizado}",
      );
    }

    return registros;
  }

  // Métodos para Registro
  Future<List<Registro>> getRegistrosNaoSincronizados() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'registros',
      where: 'sincronizado = 0',
    );

    return List.generate(maps.length, (i) {
      return Registro.fromJson(maps[i]);
    });
  }

  Future<void> insertRegistro(Registro registro) async {
    final db = await database;

    // Verificar se o registro já existe
    final existingRecords = await db.query(
      'registros',
      where: 'id = ?',
      whereArgs: [registro.id],
    );

    if (existingRecords.isNotEmpty) {
      print("Registro com ID ${registro.id} já existe, atualizando...");
      await db.update(
        'registros',
        registro.toJson(),
        where: 'id = ?',
        whereArgs: [registro.id],
      );
    } else {
      print("Inserindo novo registro com ID ${registro.id}");
      await db.insert(
        'registros',
        registro.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
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

  // Na classe LocalStorageService
  Future<void> marcarRegistroComoSincronizado(String registroId) async {
    final db = await database;
    await db.update(
      'registros',
      {'sincronizado': 1}, // Usar 1 em vez de true
      where: 'id = ?',
      whereArgs: [registroId],
    );
    print("Registro ID $registroId marcado como sincronizado");
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
    await db.delete('registros', where: 'id = ?', whereArgs: [id]);
  }
}
