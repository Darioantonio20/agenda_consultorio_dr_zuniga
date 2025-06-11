import 'package:sqflite/sqflite.dart' as sqflite_db;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

abstract class DatabaseService {
  Future<void> init();
  Future<int> insert(String table, Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> queryAll(String table);
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<Object?>? whereArgs, String? orderBy});
  Future<int> update(String table, Map<String, dynamic> data, String where,
      List<Object?> whereArgs);
  Future<int> delete(String table, String where, List<Object?> whereArgs);
}

class SqfliteDatabaseService implements DatabaseService {
  static sqflite_db.Database? _database;

  @override
  Future<void> init() async {
    if (_database != null) return;
    _database = await _initSqfliteDatabase();
  }

  Future<sqflite_db.Database> _initSqfliteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'agenda_dr_zuniga.db');

    return await sqflite_db.openDatabase(
      path,
      version: 1,
      onCreate: _onCreateSqflite,
    );
  }

  Future<void> _onCreateSqflite(sqflite_db.Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT,
        phoneNumber TEXT,
        paymentType TEXT,
        willInvoice INTEGER,
        address TEXT
      )
      ''');
    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER,
        startTime TEXT,
        endTime TEXT,
        isFirstAppointment INTEGER,
        status TEXT,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
      ''');
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = _database!;
    final id = await db.insert(table, data,
        conflictAlgorithm: sqflite_db.ConflictAlgorithm.replace);
    print('Sqflite Insert: Table: $table, Data: $data, ID: $id');
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = _database!;
    final result = await db.query(table);
    print('Sqflite QueryAll: Table: $table, Result Count: ${result.length}');
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final db = _database!;
    final result = await db.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
    print(
        'Sqflite Query: Table: $table, Where: $where, Args: $whereArgs, OrderBy: $orderBy, Result Count: ${result.length}');
    return result;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data, String where,
      List<Object?> whereArgs) async {
    final db = _database!;
    final rowsAffected =
        await db.update(table, data, where: where, whereArgs: whereArgs);
    print(
        'Sqflite Update: Table: $table, Data: $data, Where: $where, Args: $whereArgs, Rows Affected: $rowsAffected');
    return rowsAffected;
  }

  @override
  Future<int> delete(
      String table, String where, List<Object?> whereArgs) async {
    final db = _database!;
    final rowsAffected =
        await db.delete(table, where: where, whereArgs: whereArgs);
    print(
        'Sqflite Delete: Table: $table, Where: $where, Args: $whereArgs, Rows Affected: $rowsAffected');
    return rowsAffected;
  }
}

class SembastDatabaseService implements DatabaseService {
  static Database? _database;
  static final Map<String, StoreRef<int, Map<String, dynamic>>> _stores = {};

  @override
  Future<void> init() async {
    if (_database != null) return;
    final factory = databaseFactoryWeb;
    _database = await factory.openDatabase('agenda_dr_zuniga_sembast.db');
    print('Sembast Init: Database opened.');
  }

  StoreRef<int, Map<String, dynamic>> _getStore(String table) {
    if (!_stores.containsKey(table)) {
      _stores[table] = intMapStoreFactory.store(table);
    }
    return _stores[table]!;
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final store = _getStore(table);
    final key = await store.add(_database!, data);
    print('Sembast Insert: Table: $table, Data: $data, Key: $key');
    return key;
  }

  @override
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final store = _getStore(table);
    final records = await store.find(_database!);
    print('Sembast QueryAll: Table: $table, Result Count: ${records.length}');
    return records.map((e) => {...e.value, 'id': e.key}).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final store = _getStore(table);

    Filter? queryFilter;
    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      final field = where.split(' = ')[0];
      final value = whereArgs[0];
      queryFilter = Filter.equals(field, value);
    }

    List<SortOrder>? querySortOrders;
    if (orderBy != null) {
      final sortField = orderBy.split(' ')[0];
      final bool isAscending = orderBy.split(' ').length > 1 &&
              orderBy.split(' ')[1].toLowerCase() == 'desc'
          ? false
          : true;
      querySortOrders = [SortOrder(sortField, isAscending)];
    }

    final records = await store.find(_database!,
        finder: Finder(filter: queryFilter, sortOrders: querySortOrders));
    print(
        'Sembast Query: Table: $table, Where: $where, Args: $whereArgs, OrderBy: $orderBy, Result Count: ${records.length}');
    return records.map((e) => {...e.value, 'id': e.key}).toList();
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data, String where,
      List<Object?> whereArgs) async {
    final store = _getStore(table);
    int? id = data['id'] as int?; // Try to get ID from data

    if (id != null) {
      await store.record(id).update(_database!, data);
      print('Sembast Update (by ID): Table: $table, Data: $data, ID: $id');
      return 1; // Indicate one row updated
    } else if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      final field = where.split(' = ')[0];
      final value = whereArgs[0];
      final finder = Finder(filter: Filter.equals(field, value));
      final updatedCount = await store.update(_database!, data, finder: finder);
      print(
          'Sembast Update (by Finder): Table: $table, Data: $data, Where: $where, Args: $whereArgs, Rows Affected: $updatedCount');
      return updatedCount ?? 0;
    }
    print('Sembast Update: No record updated.');
    return 0;
  }

  @override
  Future<int> delete(
      String table, String where, List<Object?> whereArgs) async {
    final store = _getStore(table);
    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      final field = where.split(' = ')[0];
      final value = whereArgs[0];
      final finder = Finder(filter: Filter.equals(field, value));
      final deletedCount = await store.delete(_database!, finder: finder);
      print(
          'Sembast Delete: Table: $table, Where: $where, Args: $whereArgs, Rows Affected: $deletedCount');
      return deletedCount;
    }
    print('Sembast Delete: No record deleted.');
    return 0;
  }
}

class DatabaseHelper implements DatabaseService {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  late DatabaseService _platformSpecificDatabaseService;

  DatabaseHelper._internal() {
    if (kIsWeb) {
      _platformSpecificDatabaseService = SembastDatabaseService();
    } else {
      _platformSpecificDatabaseService = SqfliteDatabaseService();
    }
  }

  @override
  Future<void> init() {
    return _platformSpecificDatabaseService.init();
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data) {
    return _platformSpecificDatabaseService.insert(table, data);
  }

  @override
  Future<List<Map<String, dynamic>>> queryAll(String table) {
    return _platformSpecificDatabaseService.queryAll(table);
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<Object?>? whereArgs, String? orderBy}) {
    return _platformSpecificDatabaseService.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data, String where,
      List<Object?> whereArgs) {
    return _platformSpecificDatabaseService.update(
        table, data, where, whereArgs);
  }

  @override
  Future<int> delete(String table, String where, List<Object?> whereArgs) {
    return _platformSpecificDatabaseService.delete(table, where, whereArgs);
  }
}
