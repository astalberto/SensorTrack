// Streams de acelerómetro y giroscopio (sensors_plus).
// Responsable: Alberto

import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  Stream<AccelerometerEvent> acelerometro({
    Duration intervalo = SensorInterval.normalInterval,
  }) =>
      accelerometerEventStream(samplingPeriod: intervalo);

  Stream<GyroscopeEvent> giroscopio({
    Duration intervalo = SensorInterval.normalInterval,
  }) =>
      gyroscopeEventStream(samplingPeriod: intervalo);
}
