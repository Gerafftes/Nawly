import 'package:flutter/foundation.dart' show kDebugMode;

enum AppDataSource { demo, supabase }

class AppEnvironment {
  const AppEnvironment._({
    required this.dataSource,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppEnvironment.fromEnvironment() {
    return AppEnvironment.fromValues(
      dataSource: const String.fromEnvironment(
        'NAWLY_DATA_SOURCE',
        defaultValue: 'demo',
      ),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      ),
    );
  }

  factory AppEnvironment.fromValues({
    String dataSource = 'demo',
    String supabaseUrl = '',
    String supabasePublishableKey = '',
  }) {
    final AppDataSource resolvedDataSource = switch (dataSource) {
      'demo' => AppDataSource.demo,
      'supabase' => AppDataSource.supabase,
      _ => throw FormatException(
        'NAWLY_DATA_SOURCE must be either "demo" or "supabase".',
      ),
    };

    if (resolvedDataSource == AppDataSource.supabase) {
      final Uri? url = Uri.tryParse(supabaseUrl);
      if (url == null || !url.hasScheme || url.host.isEmpty) {
        throw const FormatException(
          'SUPABASE_URL must be a complete URL when Supabase is enabled.',
        );
      }
      if (!_usesSecureSupabaseTransport(url, allowLocalHttp: kDebugMode)) {
        throw const FormatException(
          'SUPABASE_URL must use HTTPS unless this is a Debug build targeting '
          'a numeric loopback address for local development.',
        );
      }
      if (supabasePublishableKey.trim().isEmpty) {
        throw const FormatException(
          'SUPABASE_PUBLISHABLE_KEY is required when Supabase is enabled.',
        );
      }
    }

    return AppEnvironment._(
      dataSource: resolvedDataSource,
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
    );
  }

  final AppDataSource dataSource;
  final String supabaseUrl;
  final String supabasePublishableKey;

  bool get usesSupabase => dataSource == AppDataSource.supabase;
}

bool _usesSecureSupabaseTransport(Uri url, {required bool allowLocalHttp}) {
  final String scheme = url.scheme.toLowerCase();
  return scheme == 'https' ||
      (allowLocalHttp && scheme == 'http' && _isNumericLoopbackHost(url.host));
}

bool _isNumericLoopbackHost(String host) {
  if (host == '::1') {
    return true;
  }

  final List<String> octets = host.split('.');
  if (octets.length != 4 || octets.first != '127') {
    return false;
  }

  return octets.every((String octet) {
    final int? value = int.tryParse(octet);
    return value != null &&
        value >= 0 &&
        value <= 255 &&
        value.toString() == octet;
  });
}
