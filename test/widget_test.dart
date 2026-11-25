import 'package:flutter_test/flutter_test.dart';

import 'package:sensor_track/app/app.dart';

void main() {
  testWidgets('La app arranca en Home con el menú de módulos', (tester) async {
    await tester.pumpWidget(const SensorTrackApp());

    expect(find.text('SensorTrack'), findsOneWidget);
    expect(find.text('Sensores'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
  });
}
