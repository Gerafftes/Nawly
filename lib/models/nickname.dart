abstract final class NicknameRules {
  static const int maxLength = 10;

  static String normalize(String value) => value.trim();

  static String? validationError(String value) {
    final String nickname = normalize(value);
    if (nickname.isEmpty) {
      return 'Nickname darf nicht leer sein';
    }
    if (nickname.runes.length > maxLength) {
      return 'Nickname darf höchstens $maxLength Zeichen haben';
    }
    return null;
  }

  static String requireValid(Object? value) {
    if (value is! String) {
      throw const FormatException('Nickname must be a string');
    }

    final String nickname = normalize(value);
    final String? error = validationError(nickname);
    if (error != null) {
      throw FormatException(error);
    }
    return nickname;
  }

  static String initial(String nickname) {
    final String normalizedNickname = requireValid(nickname);
    return String.fromCharCode(normalizedNickname.runes.first).toUpperCase();
  }

  static String avatarSystemImage(String nickname) {
    final String normalizedInitial = _normalizedSymbolInitial(
      initial(nickname),
    );
    return '$normalizedInitial.circle.fill';
  }

  static void validateUnique(Iterable<NicknameIdentity> identities) {
    final Map<String, String> ownerByNickname = <String, String>{};
    final Map<String, String> nicknameByOwner = <String, String>{};

    for (final NicknameIdentity identity in identities) {
      final String name = identity.name.trim();
      if (name.isEmpty) {
        throw const FormatException('Name must not be empty');
      }

      final String nickname = requireValid(identity.nickname);
      final String ownerKey = name.toLowerCase();
      final String nicknameKey = nickname.toLowerCase();
      final String? existingOwner = ownerByNickname[nicknameKey];
      if (existingOwner != null && existingOwner != ownerKey) {
        throw FormatException('Nickname "$nickname" is already assigned');
      }

      final String? existingNickname = nicknameByOwner[ownerKey];
      if (existingNickname != null && existingNickname != nicknameKey) {
        throw FormatException(
          '$name cannot use both "$existingNickname" and "$nickname"',
        );
      }

      ownerByNickname[nicknameKey] = ownerKey;
      nicknameByOwner[ownerKey] = nicknameKey;
    }
  }

  static String _normalizedSymbolInitial(String initial) {
    const Map<String, String> replacements = <String, String>{
      'Ä': 'a',
      'Ö': 'o',
      'Ü': 'u',
      'ẞ': 's',
    };
    final String symbolInitial = replacements[initial] ?? initial.toLowerCase();
    if (RegExp(r'^[a-z0-9]$').hasMatch(symbolInitial)) {
      return symbolInitial;
    }
    return 'person';
  }
}

class NicknameIdentity {
  const NicknameIdentity({required this.name, required this.nickname});

  final String name;
  final String nickname;
}
