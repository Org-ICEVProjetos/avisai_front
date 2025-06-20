import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<T> _executarEmTransacao<T>(
    Future<T> Function(Transaction txn) operacao,
  ) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await operacao(txn);
    });
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
      await db.execute('ALTER TABLE registros ADD COLUMN resposta TEXT');
    }
  }

  Future<bool> registroExiste(String registroId) async {
    final db = await database;
    final result = await db.query(
      'registros',
      where: 'id = ?',
      whereArgs: [registroId],
    );
    return result.isNotEmpty;
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

  // Método para validar registro
  Future<void> _validarRegistro(Registro registro) async {
    final File imagemFile = File(registro.photoPath);
    if (!await imagemFile.exists()) {
      throw Exception('Imagem não encontrada: ${registro.photoPath}');
    }

    final int tamanho = await imagemFile.length();
    if (tamanho < 1024) {
      throw Exception('Arquivo de imagem muito pequeno: ${tamanho} bytes');
    }

    if (kDebugMode) {
      print(
        'Registro validado - Imagem: ${registro.photoPath} (${tamanho} bytes)',
      );
    }
  }

  // Método para inserir registro no banco local
  Future<void> insertRegistro(Registro registro) async {
    await _validarRegistro(registro);

    await _executarEmTransacao((txn) async {
      final existingRecords = await txn.query(
        'registros',
        where: 'id = ?',
        whereArgs: [registro.id],
      );

      if (existingRecords.isNotEmpty) {
        await txn.update(
          'registros',
          registro.toJson(),
          where: 'id = ?',
          whereArgs: [registro.id],
        );
      } else {
        await txn.insert(
          'registros',
          registro.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
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
    await _executarEmTransacao((txn) async {
      // Verificar se o registro existe antes de atualizar
      final existingRecords = await txn.query(
        'registros',
        where: 'id = ?',
        whereArgs: [registroId],
      );

      if (existingRecords.isNotEmpty) {
        await txn.update(
          'registros',
          {'sincronizado': 1},
          where: 'id = ?',
          whereArgs: [registroId],
        );
      }
    });
  }

  // Método que remove registro do banco local
  Future<void> deleteRegistro(String id) async {
    final db = await database;
    await db.delete('registros', where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> exportarBanco({bool compartilhar = false}) async {
    try {
      List<Registro> registros = await getRegistros();

      final directory = await getExternalStorageDirectory();

      if (directory == null) {
        throw Exception('Diretório externo não encontrado.');
      }

      DateTime now = DateTime.now();
      String timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      String fileName = 'avisai_backup_$timestamp.json';

      String filePath = join(directory.path, fileName);

      Map<String, dynamic> exportData = {
        'metadata': {
          'appName': 'Avisaí',
          'exportDate': now.toIso8601String(),
          'version': '1.0',
          'totalRegistros': registros.length,
        },
        'registros': registros.map((registro) => registro.toJson()).toList(),
      };

      String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(exportData);

      File file = File(filePath);
      await file.writeAsString(jsonString, encoding: utf8);

      // Compartilha automaticamente, se solicitado
      if (compartilhar) {
        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Backup do app Avisaí');
      }

      return filePath;
    } catch (e) {
      throw Exception('Erro ao exportar dados: $e');
    }
  }

  // FUNÇÃO AUXILIAR: Verifica se o arquivo JSON de backup foi criado com sucesso
  Future<bool> verificarBackup(String caminhoBackup) async {
    try {
      File backupFile = File(caminhoBackup);
      if (!await backupFile.exists()) return false;

      // Verifica se é um JSON válido
      String content = await backupFile.readAsString();
      json.decode(content); // Tenta decodificar para validar

      return true;
    } catch (e) {
      return false;
    }
  }

  // FUNÇÃO AUXILIAR: Obtém informações do backup JSON
  Future<Map<String, dynamic>> obterInfoBackup(String caminhoBackup) async {
    try {
      File backupFile = File(caminhoBackup);
      FileStat stats = await backupFile.stat();

      // Lê o conteúdo para obter metadados
      String content = await backupFile.readAsString();
      Map<String, dynamic> jsonData = json.decode(content);

      return {
        'caminho': caminhoBackup,
        'tamanho': stats.size,
        'dataModificacao': stats.modified,
        'existe': await backupFile.exists(),
        'totalRegistros': jsonData['metadata']?['totalRegistros'] ?? 0,
        'dataExportacao': jsonData['metadata']?['exportDate'] ?? 'N/A',
        'versao': jsonData['metadata']?['version'] ?? 'N/A',
      };
    } catch (e) {
      return {'erro': e.toString()};
    }
  }
}
