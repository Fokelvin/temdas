import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/data/supabase_session.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

void main() {
  test(
    'session changes reach Serverpod as Bearer; logout removes token',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final baseUrl = 'http://127.0.0.1:${server.port}';
      final headers = <String?>[];
      late String first;
      late String refreshed;
      server.listen((request) async {
        if (request.uri.path.contains('logout')) {
          request.response.statusCode = 204;
        } else if (request.uri.path.endsWith('/token')) {
          final isRefresh =
              request.uri.queryParameters['grant_type'] == 'refresh_token';
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'access_token': isRefresh ? refreshed : first,
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'test-user',
                'app_metadata': {},
                'user_metadata': {},
                'aud': 'authenticated',
                'created_at': '2026-01-01T00:00:00Z',
              },
            }),
          );
        } else {
          headers.add(request.headers.value(HttpHeaders.authorizationHeader));
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({'className': 'AuthMe', 'usuarioId': 42, 'aal': 'aal2'}),
          );
        }
        await request.response.close();
      });
      final supabase = SupabaseClient(
        baseUrl,
        'sb_publishable_test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final session = SupabaseSession(supabase);
      final client = backend.Client('$baseUrl/')..authKeyProvider = session;
      final events = <AuthChangeEvent>[];
      final subscription = session.authChanges.listen(
        (state) => events.add(state.event),
      );
      addTearDown(() async {
        await subscription.cancel();
        client.close();
        await supabase.dispose();
        await server.close(force: true);
      });

      String jwt(String id) {
        String encode(Object value) => base64Url
            .encode(utf8.encode(jsonEncode(value)))
            .replaceAll('=', '');
        return '${encode({'alg': 'ES256'})}.${encode({'sub': id, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.test-signature';
      }

      expect(session.currentSession, isNull);
      expect(await session.authHeaderValue, isNull);
      first = jwt('first');
      refreshed = jwt('refreshed');
      await session.signInWithPassword('test@example.com', 'test-password');
      expect(session.accessToken, first);
      expect((await client.auth.me()).usuarioId, 42);
      await supabase.auth.refreshSession();
      await client.auth.me();
      await session.signOut();
      expect(session.currentSession, isNull);
      await client.auth.me();
      expect(headers, ['Bearer $first', 'Bearer $refreshed', null]);
      expect(
        events,
        containsAll([
          AuthChangeEvent.signedIn,
          AuthChangeEvent.tokenRefreshed,
          AuthChangeEvent.signedOut,
        ]),
      );
    },
  );
}
