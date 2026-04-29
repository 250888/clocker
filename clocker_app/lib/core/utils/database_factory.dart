import 'database_interface.dart';
import 'database_helper_stub.dart'
    if (dart.library.io) 'database_helper.dart'
    if (dart.library.html) 'web_database_helper.dart' as impl;

export 'database_interface.dart';

abstract class DatabaseFactory {
  static DatabaseHelperInterface create() {
    return impl.createDatabaseHelper();
  }
}
