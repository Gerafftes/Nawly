import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/services/ui_scale.dart';

void main() {
  testWidgets('UiScale preserves design proportions across phone widths', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final double width in <double>[320, 360, 402, 430]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 874);

      late UiScale ui;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              ui = UiScale.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(ui.s(402), closeTo(width, 0.001));
      expect(ui.s(20) / ui.s(10), closeTo(2, 0.001));
    }
  });
}
