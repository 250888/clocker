import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:clocker/core/utils/database_factory.dart' as app_db;

String? _suiteDir;

/// 测试夹具：让 sqflite_common_ffi 在 Windows/CI 上可用，并把库放到临时目录。
///
/// 每个测试文件（独立 isolate）用**自己的目录**：otherwise 并行跑时
/// 多个 suite 会共用同一个 sqlite 文件，互相 clearAllData 导致随机失败。
Future<void> initTestDatabase() async {
  _loadBundledSqlite3();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  _suiteDir ??= 'clocker_test_${DateTime.now().microsecondsSinceEpoch}';
  final tmp = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}$_suiteDir',
  );
  if (!tmp.existsSync()) tmp.createSync(recursive: true);
  await databaseFactory.setDatabasesPath(tmp.path);
}

/// 每个用例开始前清空全部表。
Future<void> resetTestDatabase() async {
  final db = app_db.DatabaseFactory.create();
  await db.clearAllData();
}

void _loadBundledSqlite3() {
  if (!Platform.isWindows) return;
  final candidate = File(
    '${Directory.current.path}${Platform.pathSeparator}windows'
    '${Platform.pathSeparator}sqlite3.dll',
  );
  if (candidate.existsSync()) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open(candidate.path),
    );
  }
}
