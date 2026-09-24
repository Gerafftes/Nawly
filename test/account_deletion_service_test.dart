import 'package:flutter_test/flutter_test.dart';
import 'package:nawly/services/account_deletion_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('demo account deletion is unavailable and non-destructive', () async {
    const DemoAccountDeletionService service = DemoAccountDeletionService();

    final AccountDeletionResult result = await service.deleteAccount(
      idempotencyKey: 'not-used-in-demo',
    );

    expect(service.isAvailable, isFalse);
    expect(result.outcome, AccountDeletionOutcome.unavailable);
  });

  test(
    'Supabase account deletion rejects an invalid idempotency key',
    () async {
      final SupabaseAccountDeletionService service =
          SupabaseAccountDeletionService(
            SupabaseClient('https://example.supabase.co', 'publishable-key'),
            enabled: true,
          );

      expect(
        () => service.deleteAccount(idempotencyKey: 'not-a-uuid'),
        throwsA(
          isA<AccountDeletionException>().having(
            (AccountDeletionException error) => error.code,
            'code',
            'invalid_idempotency_key',
          ),
        ),
      );
    },
  );

  test('Supabase account deletion requires an authenticated session', () async {
    final SupabaseAccountDeletionService service =
        SupabaseAccountDeletionService(
          SupabaseClient('https://example.supabase.co', 'publishable-key'),
          enabled: true,
        );

    expect(service.isAvailable, isFalse);
    expect(
      () => service.deleteAccount(
        idempotencyKey: '31b4b7c5-a11e-4ec1-b20c-74e584e19528',
      ),
      throwsA(
        isA<AccountDeletionException>().having(
          (AccountDeletionException error) => error.code,
          'code',
          'authentication_required',
        ),
      ),
    );
  });

  test(
    'Supabase account deletion stays disabled until explicitly enabled',
    () async {
      final SupabaseAccountDeletionService service =
          SupabaseAccountDeletionService(
            SupabaseClient('https://example.supabase.co', 'publishable-key'),
          );

      final AccountDeletionResult result = await service.deleteAccount(
        idempotencyKey: '31b4b7c5-a11e-4ec1-b20c-74e584e19528',
      );

      expect(service.isAvailable, isFalse);
      expect(result.outcome, AccountDeletionOutcome.unavailable);
    },
  );
}
