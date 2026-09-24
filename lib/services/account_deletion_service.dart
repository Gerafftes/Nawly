import 'package:supabase_flutter/supabase_flutter.dart';

enum AccountDeletionOutcome { unavailable, pending, completed }

class AccountDeletionResult {
  const AccountDeletionResult._(this.outcome);

  const AccountDeletionResult.unavailable()
    : this._(AccountDeletionOutcome.unavailable);

  const AccountDeletionResult.pending()
    : this._(AccountDeletionOutcome.pending);

  const AccountDeletionResult.completed()
    : this._(AccountDeletionOutcome.completed);

  final AccountDeletionOutcome outcome;
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.code, {this.status});

  final String code;
  final int? status;

  @override
  String toString() => 'AccountDeletionException($code, status: $status)';
}

abstract interface class AccountDeletionService {
  bool get isAvailable;

  Future<AccountDeletionResult> deleteAccount({required String idempotencyKey});
}

class DemoAccountDeletionService implements AccountDeletionService {
  const DemoAccountDeletionService();

  @override
  bool get isAvailable => false;

  @override
  Future<AccountDeletionResult> deleteAccount({
    required String idempotencyKey,
  }) async {
    return const AccountDeletionResult.unavailable();
  }
}

class SupabaseAccountDeletionService implements AccountDeletionService {
  const SupabaseAccountDeletionService(this._client, {this.enabled = false});

  final SupabaseClient _client;
  final bool enabled;

  @override
  bool get isAvailable => enabled && _client.auth.currentSession != null;

  @override
  Future<AccountDeletionResult> deleteAccount({
    required String idempotencyKey,
  }) async {
    if (!enabled) {
      return const AccountDeletionResult.unavailable();
    }
    if (!_isUuid(idempotencyKey)) {
      throw const AccountDeletionException('invalid_idempotency_key');
    }
    if (_client.auth.currentSession == null) {
      throw const AccountDeletionException('authentication_required');
    }

    try {
      final FunctionResponse response = await _client.functions.invoke(
        'account-delete',
        body: <String, String>{
          'idempotencyKey': idempotencyKey,
          'confirmation': 'DELETE',
        },
      );
      final Object? responseData = response.data;
      final String? status = responseData is Map
          ? responseData['status'] as String?
          : null;

      if (status == 'completed') {
        await _client.auth.signOut(scope: SignOutScope.local);
        return const AccountDeletionResult.completed();
      }
      if (status == 'pending') {
        return const AccountDeletionResult.pending();
      }
      throw AccountDeletionException(
        'unexpected_function_response',
        status: response.status,
      );
    } on FunctionException catch (error) {
      final Object? details = error.details;
      final String? code = details is Map ? details['code'] as String? : null;
      throw AccountDeletionException(
        code ?? 'account_deletion_failed',
        status: error.status,
      );
    }
  }
}

bool _isUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
