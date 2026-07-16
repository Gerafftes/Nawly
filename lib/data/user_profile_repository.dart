import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/user_profile_models.dart';

abstract class UserProfileRepository {
  const UserProfileRepository();

  Future<UserProfileData> loadProfile();
}

class UserProfileDemoRepository extends UserProfileRepository {
  const UserProfileDemoRepository({
    this.assetPath = 'assets/data/user_profile_demo.json',
  });

  final String assetPath;

  @override
  Future<UserProfileData> loadProfile() async {
    final String payload = await rootBundle.loadString(assetPath);
    final Object? decoded = jsonDecode(payload);

    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'User profile demo data must be a JSON object',
      );
    }

    return UserProfileData.fromJson(decoded);
  }
}
