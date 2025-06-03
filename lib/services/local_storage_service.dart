import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import '../data/models/registro.dart';

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

  // Inicializa database local que salva os registros localmente
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'avisai.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  //Cria tabela para usuários e registros localmente
  Future<void> _onCreate(Database db, int version) async {
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
    photoPath TEXT,
    observation TEXT,
    status TEXT,
    sincronizado INTEGER,
    validadoPorUsuarioId TEXT,
    dataValidacao TEXT,
    resposta TEXT
  )
''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adiciona a nova coluna "resposta"
      await db.execute('ALTER TABLE registros ADD COLUMN resposta TEXT');
    }

    // Para futuras versões, adicione mais condições:
    // if (oldVersion < 3) {
    //   await db.execute('ALTER TABLE registros ADD COLUMN outraColuna TEXT');
    // }
  }

  // Método para obter registros salvos localmente
  Future<List<Registro>> getRegistros() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('registros');
    List<Registro> registros = List.generate(maps.length, (i) {
      return Registro.fromJson(maps[i]);
    });

    return registros;
  }

  // Méotod para obter os registros locais qu enãoe stão no banco
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

  // Método para inserir registro no banco local
  Future<void> insertRegistro(Registro registro) async {
    final db = await database;
    final existingRecords = await db.query(
      'registros',
      where: 'id = ?',
      whereArgs: [registro.id],
    );

    if (existingRecords.isNotEmpty) {
      await db.update(
        'registros',
        registro.toJson(),
        where: 'id = ?',
        whereArgs: [registro.id],
      );
    } else {
      await db.insert(
        'registros',
        registro.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Método que altera um registro localmente
  Future<void> updateRegistro(Registro registro) async {
    final db = await database;
    await db.update(
      'registros',
      registro.toJson(),
      where: 'id = ?',
      whereArgs: [registro.id],
    );
  }

  // Méotodo que marca registros que foram sincronizados recentemente
  Future<void> marcarRegistroComoSincronizado(String registroId) async {
    final db = await database;
    await db.update(
      'registros',
      {'sincronizado': 1}, // Usar 1 em vez de true
      where: 'id = ?',
      whereArgs: [registroId],
    );
  }

  // Método que remove registro do banco local
  Future<void> deleteRegistro(String id) async {
    final db = await database;
    await db.delete('registros', where: 'id = ?', whereArgs: [id]);
  }
}
