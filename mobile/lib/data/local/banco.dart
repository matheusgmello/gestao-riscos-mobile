import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Banco local (sqflite) usado como cache offline do domínio de riscos.
class Banco {
  Banco._();
  static final Banco instance = Banco._();

  /// Injetado pelos testes (sqflite_common_ffi, em memória).
  static Database? testDb;

  Database? _db;

  Future<Database> get db async => testDb ?? (_db ??= await _abrir());

  Future<Database> _abrir() async {
    final caminho = p.join(await getDatabasesPath(), 'gestao_risco.db');
    return openDatabase(
      caminho,
      version: 2,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, _) => criarSchema(d),
      onUpgrade: (d, de, _) async {
        if (de < 2) await d.execute(_sqlCacheEstatico);
      },
    );
  }

  static const _sqlCacheEstatico =
      'CREATE TABLE cache_estatico (chave TEXT PRIMARY KEY, json TEXT NOT NULL)';

  static Future<void> criarSchema(Database d) async {
    for (final tabela in ['riscos', 'acoes', 'monitoramentos']) {
      final chave = tabela == 'riscos' ? 'uuid TEXT' : 'id INTEGER';
      await d.execute('''
        CREATE TABLE cache_$tabela (
          $chave PRIMARY KEY,
          risco_uuid TEXT,
          json TEXT NOT NULL,
          atualizado_em TEXT,
          ativo INTEGER NOT NULL DEFAULT 1,
          pendente INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    await d.execute('''
      CREATE TABLE fila_sync (
        seq INTEGER PRIMARY KEY AUTOINCREMENT,
        recurso TEXT NOT NULL,
        operacao TEXT NOT NULL,
        chave TEXT NOT NULL,
        payload TEXT,
        base_atualizado_em TEXT,
        tentativas INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await d.execute(_sqlCacheEstatico);
  }

  /// Apaga tudo — chamado no logout.
  Future<void> limpar() async {
    final d = await db;
    await d.delete('cache_riscos');
    await d.delete('cache_acoes');
    await d.delete('cache_monitoramentos');
    await d.delete('fila_sync');
    await d.delete('cache_estatico');
  }

  /// Guarda/lê listas estáticas (unidades, objetivos PDI, macroprocessos)
  /// para os selects dos formulários funcionarem offline.
  Future<void> guardarEstatico(String chave, String json) async {
    final d = await db;
    await d.insert('cache_estatico', {
      'chave': chave,
      'json': json,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> lerEstatico(String chave) async {
    final d = await db;
    final rows = await d.query(
      'cache_estatico',
      where: 'chave = ?',
      whereArgs: [chave],
    );
    return rows.isEmpty ? null : rows.first['json'] as String;
  }
}
