import '../models/activity_models.dart';

abstract class ActivityRepository {
  const ActivityRepository();

  Future<List<ActivitySectionData>> loadSections();
}
