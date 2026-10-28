import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/data/auth_callback.dart';
import 'package:temdas/data/auth_callback_storage.dart';
import 'package:temdas/data/supabase_session.dart';

const _stateKey = 'temdas.auth.callback.v1';
const _sensitive = 'DO_NOT_LOG_sensitive_value_927135';

void main() {
  for (final (name, suffix) in [
    ('main query', '?token_hash=$_sensitive&type=recovery'),
    ('route fragment', '#/auth/callback?token_hash=$_sensitive&type=recovery'),
    ('raw fragment', '#token_hash=$_sensitive&type=recovery'),
    (
      'mirrored sources',
      '?token_hash=$_sensitive&type=recovery#/auth/callback?token_hash=$_sensitive&type=recovery',
    ),
    (
      'mirrored raw fragment',
      '?token_hash=$_sensitive&type=recovery#token_hash=$_sensitive&type=recovery',
    ),
    (
      'complementary sources',
      '?token_hash=$_sensitive#/auth/callback?type=recovery',
    ),
  ]) {
    test('recovery OTP accepts $name exactly once', () async {
      final h = _Harness();
      final result = await h.process(suffix);
      expect(result.status, CallbackStatus.valid);
      expect(result.flow, CallbackFlow.recovery);
      expect(h.requests.single.url.path, '/auth/v1/verify');
    });
  }

  test('mirrored PKCE recovery exchanges the code exactly once', () async {
    final h = _Harness();
    await h.requestRecovery();
    final result = await h.process(
      '?code=$_sensitive#/auth/callback?code=$_sensitive',
    );
    expect(result.status, CallbackStatus.valid);
    expect(result.flow, CallbackFlow.recovery);
    expect(h.requests.where((r) => r.url.path.endsWith('/token')).length, 1);
    expect(h.pkce.values, isEmpty);
  });

  test('PKCE query with a clean hash callback route remains valid', () async {
    final h = _Harness();
    await h.requestRecovery();
    expect(
      (await h.process('?code=$_sensitive#/auth/callback')).status,
      CallbackStatus.valid,
    );
    expect(h.requests.where((r) => r.url.path.endsWith('/token')).length, 1);
  });

  test('mirrored invite fragment validates the session exactly once', () async {
    final h = _Harness();
    const payload =
        'access_token=$_sensitive&refresh_token=$_sensitive&expires_in=3600&token_type=bearer&type=invite';
    final result = await h.process('?$payload#/auth/callback?$payload');
    expect(result.status, CallbackStatus.valid);
    expect(result.flow, CallbackFlow.invite);
    expect(h.requests.single.url.path, '/auth/v1/user');
  });

  test(
    'mirrors compare decoded values once without normalizing them',
    () async {
      final h = _Harness();
      await h.requestRecovery();
      expect(
        (await h.process('?code=%41#/auth/callback?code=A')).status,
        CallbackStatus.valid,
      );
      expect(jsonDecode(h.requests.last.body)['auth_code'], 'A');
    },
  );

  for (final (name, suffix, _) in [
    (
      'conflicting codes',
      '?code=$_sensitive#/auth/callback?code=different',
      'parametersConflicting',
    ),
    (
      'conflicting types',
      '?token_hash=$_sensitive&type=recovery#/auth/callback?type=invite',
      'parametersConflicting',
    ),
    (
      'plus versus space',
      '?code=%2B#/auth/callback?code=+',
      'parametersConflicting',
    ),
    (
      'no double decoding',
      '?code=%2541#/auth/callback?code=A',
      'parametersConflicting',
    ),
    (
      'query duplicates',
      '?code=$_sensitive&code=$_sensitive',
      'parametersDuplicate',
    ),
    (
      'encoded key duplicates',
      '?code=$_sensitive&c%6Fde=$_sensitive',
      'parametersDuplicate',
    ),
    (
      'route fragment duplicates',
      '#/auth/callback?code=$_sensitive&code=$_sensitive',
      'parametersDuplicate',
    ),
    (
      'raw fragment duplicates',
      '#code=$_sensitive&code=$_sensitive',
      'parametersDuplicate',
    ),
    (
      'duplicate inside mirrored source',
      '?code=$_sensitive#/auth/callback?code=$_sensitive&code=$_sensitive',
      'parametersDuplicate',
    ),
    (
      'split credentials',
      '?code=$_sensitive#/auth/callback?token_hash=$_sensitive&type=recovery',
      'parametersAmbiguous',
    ),
    (
      'combined credentials',
      '?code=$_sensitive&access_token=$_sensitive',
      'parametersAmbiguous',
    ),
    (
      'PKCE with refresh token',
      '?code=$_sensitive#refresh_token=$_sensitive',
      'parametersAmbiguous',
    ),
    (
      'OTP with session fields',
      '?token_hash=$_sensitive&type=recovery#token_type=bearer',
      'parametersAmbiguous',
    ),
    (
      'OTP and session credentials',
      '?token_hash=$_sensitive&type=recovery#access_token=$_sensitive',
      'parametersAmbiguous',
    ),
    (
      'provider error with code',
      '?code=$_sensitive#/auth/callback?error=access_denied',
      'parametersAmbiguous',
    ),
    (
      'invalid callback route suffix',
      '#/auth/callback/extra?code=$_sensitive',
      'parametersInvalid',
    ),
    (
      'unrelated route fragment',
      '#/other?code=$_sensitive',
      'parametersInvalid',
    ),
    ('malformed query UTF8', '?code=%FF', 'parametersInvalid'),
    ('malformed fragment UTF8', '#code=%FF', 'parametersInvalid'),
    ('empty parameter name', '?=value&code=$_sensitive', 'parametersInvalid'),
  ]) {
    test('rejects $name before any token request', () async {
      final h = _Harness();
      expect((await h.process(suffix)).status, CallbackStatus.invalid);
      expect(h.requests, isEmpty);
    });
  }

  test(
    'mirrored provider expiration remains expired without an exchange',
    () async {
      final h = _Harness();
      const payload = 'error=access_denied&error_code=otp_expired';
      expect(
        (await h.process('?$payload#/auth/callback?$payload')).status,
        CallbackStatus.expired,
      );

      expect(h.requests, isEmpty);
    },
  );

  test('mirrored expired recovery OTP is verified only once', () async {
    final h = _Harness(
      errorCode: 'otp_expired',
      errorMessage: 'Token expired $_sensitive',
    );
    const payload = 'token_hash=$_sensitive&type=recovery';
    expect(
      (await h.process('?$payload#/auth/callback?$payload')).status,
      CallbackStatus.expired,
    );
    expect(h.requests.single.url.path, '/auth/v1/verify');
  });

  for (final (suffix, reason) in [
    ('?code=$_sensitive&code=other', 'parametersDuplicate'),
    ('#/auth/callback/extra?code=$_sensitive', 'parametersInvalid'),
    ('?token_hash=$_sensitive&type=other', 'requestedFlowUnknown'),
    ('#access_token=$_sensitive&type=other', 'requestedFlowUnknown'),
    ('?token_hash=&type=recovery', 'parameterEmpty'),
    ('', 'callbackStateMissing'),
  ]) {
    test(
      'rejects safely with $reason (${suffix.startsWith('#') ? 'fragment' : 'query'})',
      () async {
        final h = _Harness();
        final result = await h.process(suffix);
        expect(result.status, CallbackStatus.invalid);
      },
    );
  }

  test(
    'recovery request and successful PKCE exchange use the real SDK',
    () async {
      final h = _Harness();
      await h.requestRecovery();
      final result = await h.process('?code=$_sensitive');
      expect(result.status, CallbackStatus.valid);
      expect(result.flow, CallbackFlow.recovery);
      expect(h.requests.map((r) => r.url.path), [
        '/auth/v1/recover',
        '/auth/v1/token',
      ]);
      expect(h.requests.last.url.queryParameters['grant_type'], 'pkce');
      expect(h.pkce.values, isEmpty);
    },
  );

  test('missing PKCE verifier is distinct and makes no HTTP request', () async {
    final h = _Harness();
    expect(
      (await h.process('?code=$_sensitive')).status,
      CallbackStatus.invalid,
    );
    expect(h.requests, isEmpty);
  });

  for (final (code, message, reason, status) in [
    (
      'bad_code_verifier',
      _sensitive,
      'pkceVerifierRejected',
      CallbackStatus.invalid,
    ),
    (
      'flow_state_not_found',
      'Flow state not found $_sensitive',
      'pkceFlowStateMissing',
      CallbackStatus.invalid,
    ),
    (
      'otp_expired',
      'Token expired $_sensitive',
      'authExceptionExpired',
      CallbackStatus.expired,
    ),
    (
      'untrusted_$_sensitive',
      _sensitive,
      'authExceptionInvalid',
      CallbackStatus.invalid,
    ),
  ]) {
    test('classifies $reason without logging SDK strings', () async {
      final h = _Harness(errorCode: code, errorMessage: message);
      await h.requestRecovery();
      expect((await h.process('?code=$_sensitive')).status, status);
    });
  }

  test(
    'provider expiration is not mislabeled as a PKCE exchange failure',
    () async {
      final h = _Harness();
      final result = await h.process(
        '#error=access_denied&error_code=otp_expired&error_description=expired_$_sensitive',
      );
      expect(result.status, CallbackStatus.expired);

      expect(h.requests, isEmpty);
    },
  );

  test('no session returned by OTP is distinct from a wrong user', () async {
    final h = _Harness(otpWithoutSession: true);
    expect(
      (await h.process('?token_hash=$_sensitive&type=recovery')).status,
      CallbackStatus.invalid,
    );
  });

  test('empty user is diagnosed without emitting its value', () async {
    final h = _Harness(userId: '');
    expect(
      (await h.process('?token_hash=$_sensitive&type=recovery')).status,
      CallbackStatus.invalid,
    );
  });

  test('current session belonging to another user is rejected', () async {
    final h = _Harness(divergentSession: true);
    expect(
      (await h.process('?token_hash=$_sensitive&type=recovery')).status,
      CallbackStatus.invalid,
    );
  });

  test(
    'session returned by SDK but absent from client is identified',
    () async {
      final h = _Harness(missingCurrentSession: true);
      expect(
        (await h.process('?token_hash=$_sensitive&type=recovery')).status,
        CallbackStatus.invalid,
      );
    },
  );

  test('unidentified flow after a successful exchange stays invalid', () async {
    final h = _Harness();
    await h.pkce.setItem(
      key: 'supabase.auth.token-code-verifier',
      value: _sensitive,
    );
    expect(
      (await h.process('?code=$_sensitive')).status,
      CallbackStatus.invalid,
    );
  });

  test(
    'requested invite and returned recovery flow remain incompatible',
    () async {
      final h = _Harness();
      await h.requestRecovery();
      expect(
        (await h.process('?code=$_sensitive&type=invite')).status,
        CallbackStatus.invalid,
      );
    },
  );

  test(
    'second invocation is observed without allowing a consumed code',
    () async {
      final h = _Harness();
      await h.requestRecovery();
      expect(
        (await h.process('?code=$_sensitive')).status,
        CallbackStatus.valid,
      );
      expect(
        (await h.process('?code=$_sensitive')).status,
        CallbackStatus.invalid,
      );
    },
  );

  for (final (saved, reason) in [
    ('not-json-$_sensitive', 'callbackStateMalformed'),
    (jsonEncode({'flow': 'recovery'}), 'callbackStateIncomplete'),
    (
      jsonEncode({'flow': 'recovery', 'userId': _sensitive, 'createdAt': 0}),
      'callbackStateTooOld',
    ),
  ]) {
    test('restored callback reports $reason', () async {
      final h = _Harness();
      h.storage.values[_stateKey] = saved;
      expect((await h.process('')).status, CallbackStatus.invalid);
    });
  }

  test('restoration without an active session stays expired', () async {
    final h = _Harness();
    h.storage.values[_stateKey] = jsonEncode({
      'flow': 'recovery',
      'userId': _sensitive,
      'createdAt': DateTime.now().toUtc().millisecondsSinceEpoch,
    });
    expect((await h.process('')).status, CallbackStatus.expired);
  });

  test(
    'active-session check reports a mismatched identity without its ID',
    () async {
      final h = _Harness();
      await h.requestRecovery();
      await h.process('?code=$_sensitive');
      expect(
        await h.processor.verifyActiveSession('another-$_sensitive'),
        CallbackStatus.expired,
      );
    },
  );

  test(
    'successful callback can still restore and validate its session',
    () async {
      final h = _Harness();
      await h.requestRecovery();
      await h.process('?code=$_sensitive');
      expect((await h.process('')).status, CallbackStatus.valid);
    },
  );
}

class _Harness {
  _Harness({
    String? errorCode,
    String errorMessage = _sensitive,
    bool otpWithoutSession = false,
    String userId = _sensitive,
    bool divergentSession = false,
    bool missingCurrentSession = false,
  }) {
    client = SupabaseClient(
      'https://test.invalid',
      'sb_publishable_test',
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: pkce,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        Map<String, dynamic> body;
        var status = 200;
        if (path.endsWith('/recover')) {
          body = {};
        } else if (errorCode != null &&
            (path.endsWith('/token') || path.endsWith('/verify'))) {
          body = {'code': errorCode, 'message': errorMessage};
          status = 400;
        } else if (path.endsWith('/user')) {
          body = _user(userId);
        } else {
          body = otpWithoutSession ? {'user': _user(userId)} : _session(userId);
        }
        return http.Response(
          jsonEncode(body),
          status,
          headers: {
            'content-type': 'application/json',
            'x-supabase-api-version': '2024-01-01',
          },
        );
      }),
    );
    addTearDown(client.dispose);
    processor = AuthCallbackProcessor(
      missingCurrentSession
          ? _MissingSession(client)
          : divergentSession
          ? _DivergentSession(client)
          : SupabaseSession(client),
      storage: storage,
    );
  }

  final pkce = _PkceStorage();
  final storage = _MemoryStorage();
  final requests = <http.Request>[];
  late final SupabaseClient client;
  late final AuthCallbackProcessor processor;

  Future<void> requestRecovery() => client.auth.resetPasswordForEmail(
    'sensitive@example.invalid',
    redirectTo: 'https://test.invalid/auth/callback',
  );

  Future<CallbackResult> process(String suffix) =>
      processor.process(Uri.parse('https://test.invalid/auth/callback$suffix'));
}

Map<String, dynamic> _user(String id) => {
  'id': id,
  'email': 'sensitive@example.invalid',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'aud': 'authenticated',
  'created_at': '2026-01-01T00:00:00Z',
};

Map<String, dynamic> _session(String id) => {
  'access_token': _sensitive,
  'refresh_token': _sensitive,
  'expires_in': 3600,
  'token_type': 'bearer',
  'user': _user(id),
};

class _DivergentSession extends SupabaseSession {
  _DivergentSession(super.client);
  @override
  Session? get currentSession =>
      Session.fromJson(_session('different-$_sensitive'));
}

class _MissingSession extends SupabaseSession {
  _MissingSession(super.client);
  @override
  Session? get currentSession => null;
}

class _PkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

class _MemoryStorage implements CallbackStorage {
  final values = <String, String>{};
  @override
  String? read(String key) => values[key];
  @override
  void write(String key, String value) {
    values[key] = value;
  }

  @override
  void remove(String key) {
    values.remove(key);
  }

  @override
  void clearUrl() {}
  @override
  void leaveCallback() {}
}
