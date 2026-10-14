import 'package:hospital_dashboard/features/clinic/data/open_database_io.dart'
    if (dart.library.js_interop) 'package:hospital_dashboard/features/clinic/data/open_database_web.dart';
import 'package:sembast/sembast.dart';

Future<Database> openClinicDatabase() => openPlatformDatabase();
