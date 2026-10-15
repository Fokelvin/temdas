import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/data/supabase_session.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

void main() {
  test('MFA verify sends the new aal2 session to Serverpod', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final baseUrl = 'http://127.0.0.1:${server.port}';

    String jwt(String aal) {
      String encode(Object value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      return '${encode({'alg': 'ES256'})}.${encode({'sub': 'test-user', 'aal': aal, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.test-signature';
    }

    final aal1Token = jwt('aal1');
    final aal2Token = jwt('aal2');
    final user = {
      'id': 'test-user',
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-01-01T00:00:00Z',
    };
    String? serverpodAuthorization;
    String? verifiedChallengeId;

    server.listen((request) async {
      try {
        final path = request.uri.path;
        request.response.headers.contentType = ContentType.json;
        if (path.endsWith('/token')) {
          final isRefresh =
              request.uri.queryParameters['grant_type'] == 'refresh_token';
          request.response.write(
            jsonEncode({
              'access_token': isRefresh && verifiedChallengeId != null
                  ? aal2Token
                  : aal1Token,
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': user,
            }),
          );
        } else if (path.endsWith('/factors/factor-1/challenge')) {
          request.response.write(
            jsonEncode({
              'id': 'challenge-1',
              'expires_at':
                  DateTime.now()
                      .add(const Duration(minutes: 5))
                      .millisecondsSinceEpoch ~/
                  1000,
            }),
          );
        } else if (path.endsWith('/factors/factor-1/verify')) {
          final body =
              jsonDecode(await utf8.decoder.bind(request).join())
                  as Map<String, dynamic>;
          verifiedChallengeId = body['challenge_id'] as String?;
          request.response.write(
            jsonEncode({
              'access_token': aal2Token,
              'refresh_token': 'test-refreshed',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': user,
            }),
          );
        } else {
          serverpodAuthorization = request.headers.value(
            HttpHeaders.authorizationHeader,
          );
          request.response.write(
            jsonEncode({
              'className': 'AuthMe',
              'usuarioId': 1,
              'aal': 'aal2',
              'isAdmin': false,
            }),
          );
        }
        await request.response.close();
      } catch (error, stackTrace) {
        stderr.writeln('Mock MFA server: $error\n$stackTrace');
        request.response.statusCode = 500;
        await request.response.close();
      }
    });

    final supabase = SupabaseClient(
      baseUrl,
      'sb_publishable_test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final session = SupabaseSession(supabase);
    final client = backend.Client('$baseUrl/')..authKeyProvider = session;
    addTearDown(() async {
      client.close();
      await supabase.dispose();
      await server.close(force: true);
    });

    await session.signInWithPassword('test@example.com', 'test-password');
    expect(
      supabase.auth.mfa.getAuthenticatorAssuranceLevel().currentLevel,
      AuthenticatorAssuranceLevels.aal1,
    );

    final challenge = await supabase.auth.mfa.challenge(factorId: 'factor-1');
    await supabase.auth.mfa.verify(
      factorId: 'factor-1',
      challengeId: challenge.id,
      code: '000000',
    );
    expect(verifiedChallengeId, challenge.id);
    expect(session.accessToken, aal2Token);
    expect(
      supabase.auth.mfa.getAuthenticatorAssuranceLevel().currentLevel,
      AuthenticatorAssuranceLevels.aal2,
    );

    await supabase.auth.refreshSession();
    final me = await client.auth.me();
    expect(me.usuarioId, 1);
    expect(me.aal, 'aal2');
    expect(me.isAdmin, isFalse);
    expect(serverpodAuthorization, 'Bearer $aal2Token');
  });
}
