import 'package:hospital_dashboard/features/clinic/data/clinic_bus_io.dart'
    if (dart.library.js_interop) 'package:hospital_dashboard/features/clinic/data/clinic_bus_web.dart';

abstract class ClinicBus {
  Stream<String> get events;
  void publish(String topic);
  void close();
}

ClinicBus openClinicBus() => createClinicBus();
