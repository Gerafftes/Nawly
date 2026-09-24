import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/models/nickname.dart';
import 'package:nawly/models/activity_models.dart';
import 'package:nawly/models/user_profile_models.dart';

void main() {
  test('all model entry points use ten Unicode code points after trimming', () {
    for (final String nickname in <String>['Kurzname10', 'Äöü', '😀' * 10]) {
      final profileJson = <String, Object?>{
        'name': 'Test',
        'nickname': ' $nickname ',
        'rating': 5,
        'completedJobs': 0,
        'skillInputHint': '',
        'skills': <String>[],
      };
      final contactJson = <String, Object?>{
        'name': 'Test',
        'nickname': ' $nickname ',
        'role': '',
        'summary': '',
      };
      expect(UserProfileSummaryData.fromJson(profileJson).nickname, nickname);
      expect(ActivityContactData.fromJson(contactJson).nickname, nickname);
      expect(_profile(' $nickname ').nickname, nickname);
      expect(_contact(' $nickname ').nickname, nickname);
    }
    for (final String invalid in <String>['', '  ', '😀' * 11, 'a' * 11]) {
      expect(() => _profile(invalid), throwsFormatException);
      expect(() => _contact(invalid), throwsFormatException);
    }
  });
  test('normalizes and validates nicknames up to ten characters', () {
    expect(NicknameRules.requireValid(' Gerafftes '), 'Gerafftes');
    expect(NicknameRules.validationError('Kurzname10'), isNull);
    expect(
      NicknameRules.validationError('Kurzname100'),
      'Nickname darf höchstens 10 Zeichen haben',
    );
    expect(
      () => NicknameRules.requireValid('Kurzname100'),
      throwsFormatException,
    );
  });

  test('derives avatar initials from nicknames', () {
    expect(NicknameRules.initial('Gerafftes'), 'G');
    expect(NicknameRules.avatarSystemImage('Gerafftes'), 'g.circle.fill');
    expect(NicknameRules.avatarSystemImage('Äpfelchen'), 'a.circle.fill');
  });

  test('rejects one nickname assigned to different people', () {
    expect(
      () => NicknameRules.validateUnique(const <NicknameIdentity>[
        NicknameIdentity(name: 'Mara König', nickname: 'MaraK'),
        NicknameIdentity(name: 'Elias Hartmann', nickname: 'marak'),
      ]),
      throwsFormatException,
    );
  });

  test('allows repeated activities for the same person and nickname', () {
    expect(
      () => NicknameRules.validateUnique(const <NicknameIdentity>[
        NicknameIdentity(name: 'Mara König', nickname: 'MaraK'),
        NicknameIdentity(name: 'Mara König', nickname: 'MaraK'),
      ]),
      returnsNormally,
    );
  });

  test('rejects different nicknames assigned to the same person', () {
    expect(
      () => NicknameRules.validateUnique(const <NicknameIdentity>[
        NicknameIdentity(name: 'Mara König', nickname: 'MaraK'),
        NicknameIdentity(name: 'Mara König', nickname: 'MaraNeu'),
      ]),
      throwsFormatException,
    );
  });
}

UserProfileSummaryData _profile(String nickname) => UserProfileSummaryData(
  name: 'Test',
  nickname: nickname,
  rating: 5,
  completedJobs: 0,
  skillInputHint: '',
  skills: <String>[],
);

ActivityContactData _contact(String nickname) => ActivityContactData(
  name: 'Test',
  nickname: nickname,
  role: '',
  summary: '',
);
