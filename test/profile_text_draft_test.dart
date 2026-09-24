import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/models/profile_text_draft.dart';

void main() {
  test('nickname editing validates, saves normalized text and reopens it', () {
    final draft = ProfileTextDraft.nickname('Alt');
    draft.begin();
    draft.update('  Neu  ');
    expect(draft.savedValue, 'Alt');
    expect(draft.commit(), 'Neu');
    draft.update('Nicht gespeichert');
    draft.cancel();
    expect(draft.value, 'Neu');
    expect(draft.savedValue, 'Neu');
    draft.begin();
    expect(draft.value, 'Neu');
  });

  test(
    'invalid input keeps the saved value and clears its error when edited',
    () {
      final draft = ProfileTextDraft.nickname('Alt');
      for (final value in <String>['  ', '😀' * 11]) {
        draft.update(value);
        expect(draft.commit(), isNull);
        expect(draft.error, isNotNull);
        expect(draft.savedValue, 'Alt');
      }
      draft.update('😀' * 10);
      expect(draft.error, isNull);
      expect(draft.commit(), '😀' * 10);
    },
  );

  test('skills keep the existing four-character trimmed rule', () {
    final draft = ProfileTextDraft.skills('Kochen');
    draft.update(' abc ');
    expect(draft.commit(), isNull);
    expect(draft.error, 'Skills müssen mindestens 4 Zeichen lang sein');
    draft.update('  Nähen  ');
    expect(draft.commit(), 'Nähen');
    draft.update('Malen');
    draft.cancel();
    expect(draft.value, 'Nähen');
  });
}
