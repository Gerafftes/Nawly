import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/job_models.dart';

abstract class JobsFindRepository {
  const JobsFindRepository();

  Future<List<JobFindData>> loadJobs();
}

class JobsFindDemoRepository extends JobsFindRepository {
  const JobsFindDemoRepository({
    this.assetPath = 'assets/data/jobs_find_demo.json',
  });

  final String assetPath;

  @override
  Future<List<JobFindData>> loadJobs() async {
    final String payload = await rootBundle.loadString(assetPath);
    final Object? decoded = jsonDecode(payload);

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Jobs demo data must be a JSON object');
    }

    final List<Object?> rawJobs = decoded['jobs'] as List<Object?>;
    return rawJobs
        .cast<Map<String, Object?>>()
        .map(JobFindData.fromJson)
        .toList(growable: false);
  }
}
