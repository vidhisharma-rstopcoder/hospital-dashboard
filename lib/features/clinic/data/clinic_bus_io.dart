import 'dart:async';

import 'package:hospital_dashboard/features/clinic/data/clinic_bus.dart';

ClinicBus createClinicBus() => _LocalBus();

class _LocalBus implements ClinicBus {
  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get events => _controller.stream;

  @override
  void publish(String topic) {
    if (!_controller.isClosed) _controller.add(topic);
  }

  @override
  void close() {
    _controller.close();
  }
}
