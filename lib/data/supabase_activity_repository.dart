import '../models/activity_models.dart';
import '../models/nickname.dart';
import 'activity_repository.dart';
import 'supabase_data_gateway.dart';

class SupabaseActivityRepository extends ActivityRepository {
  const SupabaseActivityRepository(this.gateway);

  final SupabasePrivateDataGateway gateway;

  @override
  Future<List<ActivitySectionData>> loadSections() async {
    _requireAuthenticatedUser(gateway.isAuthenticated);
    final List<Map<String, Object?>> activityRows = await gateway
        .loadActivities();
    final List<String> activityIds = activityRows
        .map((Map<String, Object?> row) => row['id'] as String)
        .toList(growable: false);
    final List<Map<String, Object?>> historyRows = await gateway
        .loadActivityStatusHistory(activityIds);
    final Map<String, List<Map<String, Object?>>> historyByActivity =
        _groupHistoryByActivity(historyRows);
    final Map<ActivitySectionType, List<ActivityCardData>> cardsBySection = {
      for (final ActivitySectionType type in ActivitySectionType.values)
        type: <ActivityCardData>[],
    };

    for (final Map<String, Object?> row in activityRows) {
      final ActivitySectionType sectionType =
          ActivitySectionTypeContent.fromJson(row['section_type'] as String);
      final Object? rawContact = row['contact'];
      final List<Map<String, Object?>> statusHistory =
          historyByActivity[row['id'] as String] ??
          const <Map<String, Object?>>[];

      cardsBySection[sectionType]!.add(
        ActivityCardData.fromJson(<String, Object?>{
          'id': row['id'],
          'title': row['title'],
          'chip': row['chip'],
          'scheduleText': row['schedule_text'],
          'compensationText': row['compensation_text'],
          'locationText': row['location_text'],
          'description': row['description'],
          'status': row['status'],
          'statusHistory': statusHistory,
          'iconPath': row['icon_path'],
          if (rawContact != null)
            'contact': Map<String, Object?>.from(
              rawContact as Map<String, Object?>,
            ),
          'showsVisibilityBadge': row['shows_visibility_badge'],
        }, sectionType: sectionType),
      );
    }

    final List<ActivitySectionData> sections = [
      for (final ActivitySectionType type in ActivitySectionType.values)
        ActivitySectionData(type: type, cards: cardsBySection[type]!),
    ];
    NicknameRules.validateUnique(
      sections
          .expand((ActivitySectionData section) => section.cards)
          .map((ActivityCardData card) => card.contact)
          .whereType<ActivityContactData>()
          .map(
            (ActivityContactData contact) => NicknameIdentity(
              name: contact.name,
              nickname: contact.nickname,
            ),
          ),
    );
    return sections;
  }
}

void _requireAuthenticatedUser(bool isAuthenticated) {
  if (!isAuthenticated) {
    throw StateError(
      'Supabase authentication is required for private Nawly data.',
    );
  }
}

Map<String, List<Map<String, Object?>>> _groupHistoryByActivity(
  List<Map<String, Object?>> rows,
) {
  final Map<String, List<Map<String, Object?>>> historyByActivity =
      <String, List<Map<String, Object?>>>{};
  for (final Map<String, Object?> row in rows) {
    final String activityId = row['activity_id'] as String;
    historyByActivity
        .putIfAbsent(activityId, () => <Map<String, Object?>>[])
        .add(<String, Object?>{
          'status': row['status'],
          'timestampText': row['timestamp_text'],
        });
  }
  return historyByActivity;
}
