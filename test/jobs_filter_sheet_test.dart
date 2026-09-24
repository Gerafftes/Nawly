import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/pages/tabs/start/jobs_filter_sheet.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    ValueChanged<Set<String>> onChanged,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => JobsFilterSheet(
                  isDark: true,
                  selectedCategories: const <String>{'Alle'},
                  onCategoriesChanged: onChanged,
                  viewButtonTitle: 'Kartenansicht',
                  onToggleView: () {},
                ),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'categories update immediately and selecting none restores Alle',
    (tester) async {
      Set<String>? selection;
      await mount(tester, (value) => selection = value);
      await tester.tap(find.text('Alle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Haushalt & Reinigung').last);
      await tester.pump();
      expect(selection, <String>{'Haushalt & Reinigung'});
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.text('Haushalt & Reinigung').last);
      await tester.pump();
      expect(selection, <String>{'Alle'});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposing with an open dropdown removes its overlay and timer', (
    tester,
  ) async {
    await mount(tester, (_) {});
    await tester.tap(find.text('Alle'));
    await tester.pumpAndSettle();
    expect(find.text('Haushalt & Reinigung'), findsOneWidget);
    final BuildContext context = tester.element(find.byType(JobsFilterSheet));
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(find.text('Haushalt & Reinigung'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
