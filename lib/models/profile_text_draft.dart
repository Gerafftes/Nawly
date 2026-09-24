import 'nickname.dart';

/// Local editing state shared by profile input paths, independent of widgets.
/// Committing changes only this page's value; it does not persist to a backend.
class ProfileTextDraft {
  ProfileTextDraft.nickname(String value)
    : this._(value, NicknameRules.validationError);

  ProfileTextDraft.skills(String value) : this._(value, _validateSkills);

  ProfileTextDraft._(this._savedValue, this._validator) : _value = _savedValue;

  final String? Function(String) _validator;
  String _savedValue;
  String _value;
  String? error;

  String get savedValue => _savedValue;
  String get value => _value;
  String? validate(String value) => _validator(value.trim());

  void begin() {
    _value = _savedValue;
    error = null;
  }

  void update(String value) {
    _value = value;
    error = null;
  }

  String? commit() {
    final String value = _value.trim();
    error = validate(value);
    if (error != null) return null;
    _savedValue = value;
    _value = value;
    return value;
  }

  void cancel() => begin();

  static String? _validateSkills(String value) =>
      value.length < 4 ? 'Skills müssen mindestens 4 Zeichen lang sein' : null;
}
