import 'package:sembast_web/sembast_web.dart';

Future<Database> openPlatformDatabase() {
  return databaseFactoryWeb.openDatabase('rounds_clinic');
}
