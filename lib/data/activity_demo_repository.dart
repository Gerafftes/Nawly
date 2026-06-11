import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/activity_models.dart';
import 'activity_repository.dart';

class ActivityDemoRepository extends ActivityRepository {
  const ActivityDemoRepository({
    this.assetPath = 'assets/data/activity_demo_sections.json',
  }) : super();

  final String assetPath;

  @override
  Future<List<ActivitySectionData>> loadSections() async {
    final String payload = await rootBundle.loadString(assetPath);
    final Object? decoded = jsonDecode(payload);

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Activity demo data must be a JSON object');
    }

    final List<Object?> rawSections = decoded['sections'] as List<Object?>;
    return rawSections
        .cast<Map<String, Object?>>()
        .map(ActivitySectionData.fromJson)
        .toList(growable: false);
  }
}
