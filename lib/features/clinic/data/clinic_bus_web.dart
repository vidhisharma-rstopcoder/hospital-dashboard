import 'dart:async';
import 'dart:js_interop';

import 'package:hospital_dashboard/features/clinic/data/clinic_bus.dart';
import 'package:web/web.dart';

ClinicBus createClinicBus() => _WebBus();

class _WebBus implements ClinicBus {
  _WebBus() {
    _channel = BroadcastChannel('rounds-clinic');
    _channel.onmessage = ((MessageEvent event) {
      final data = event.data;
      if (data.isA<JSString>()) {
        _controller.add((data as JSString).toDart);
      }
    }).toJS;
  }

  late final BroadcastChannel _channel;
  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get events => _controller.stream;

  @override
  void publish(String topic) {
    if (!_controller.isClosed) _controller.add(topic);
    _channel.postMessage(topic.toJS);
  }

  @override
  void close() {
    _channel.close();
    _controller.close();
  }
}
