import '../models/job_models.dart';
import 'jobs_find_repository.dart';
import 'supabase_data_gateway.dart';

class SupabaseJobsFindRepository extends JobsFindRepository {
  const SupabaseJobsFindRepository(this.gateway);

  final SupabaseDataGateway gateway;

  @override
  Future<List<JobFindData>> loadJobs() async {
    final List<Map<String, Object?>> rows = await gateway.loadJobs();
    return rows
        .map(
          (Map<String, Object?> row) => JobFindData.fromJson(<String, Object?>{
            'id': row['id'],
            'title': row['title'],
            'time': row['time_text'],
            'price': row['price_text'],
            'distance': row['distance_text'],
            'showVerified': row['show_verified'],
            if (row['public_latitude'] != null &&
                row['public_longitude'] != null)
              'approximateLocation': <String, Object?>{
                'latitude': row['public_latitude'],
                'longitude': row['public_longitude'],
              },
          }),
        )
        .toList(growable: false);
  }
}
