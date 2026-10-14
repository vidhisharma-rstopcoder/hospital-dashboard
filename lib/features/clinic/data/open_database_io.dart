import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openPlatformDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  final path = p.join(directory.path, 'rounds_clinic.db');
  return databaseFactoryIo.openDatabase(path);
}
