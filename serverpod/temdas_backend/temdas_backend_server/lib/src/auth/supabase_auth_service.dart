import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

AuthException _failure(String code) => AuthException(codigo: code);

class AuthenticatedUsuario {
  final Usuario usuario;
  final String supabaseUserId;
  final String aal;

  AuthenticatedUsuario(this.usuario, this.supabaseUserId, this.aal);
}

/// One instance per server process. Never trusts key URLs from JWT headers.
class SupabaseAuthService {
  final String issuer;
  final Uri jwksUri;
  final http.Client _http;
  final DateTime Function() _now;
  final Duration cacheTtl;
  final Duration refreshCooldown;
  final Expando<({String? token, Future<({String sub, String aal})> claims})>
  _sessionClaims = Expando();
  Map<String, JsonWebKey> _keys = {};
  DateTime? _expiresAt;
  DateTime? _lastAttempt;
  Future<void>? _pending;

  SupabaseAuthService({
    required String supabaseUrl,
    http.Client? httpClient,
    DateTime Function()? now,
    this.cacheTtl = const Duration(minutes: 10),
    this.refreshCooldown = const Duration(seconds: 30),
  }) : issuer = '${supabaseUrl.replaceFirst(RegExp(r'/+$'), '')}/auth/v1',
       jwksUri = Uri.parse(
         '${supabaseUrl.replaceFirst(RegExp(r'/+$'), '')}/auth/v1/.well-known/jwks.json',
       ),
       _http = httpClient ?? http.Client(),
       _now = now ?? DateTime.now {
    final uri = Uri.parse(supabaseUrl);
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path != '' && uri.path != '/')) {
      throw ArgumentError('SUPABASE_URL must be an HTTPS project origin.');
    }
  }

  Future<void> _refresh() async {
    final pending = _pending;
    if (pending != null) return pending;
    if (_lastAttempt != null &&
        _now().difference(_lastAttempt!) < refreshCooldown) {
      return;
    }
    _lastAttempt = _now();
    final future = _fetch();
    _pending = future;
    try {
      await future;
    } finally {
      _pending = null;
    }
  }

  Future<void> _fetch() async {
    try {
      // Redirects cannot move trust to another origin.
      final request = http.Request('GET', jwksUri)..followRedirects = false;
      final response = await _http
          .send(request)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) throw StateError('JWKS unavailable');
      final body = await (() async {
        final bytes = <int>[];
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > 262144) {
            throw StateError('JWKS too large');
          }
          bytes.addAll(chunk);
        }
        return utf8.decode(bytes);
      })().timeout(const Duration(seconds: 5));
      final json = jsonDecode(body) as Map<String, dynamic>;
      final keys = <String, JsonWebKey>{};
      for (final raw in json['keys'] as List) {
        final key = Map<String, dynamic>.from(raw as Map);
        final kid = key['kid'];
        if (kid is! String || kid.isEmpty) continue;
        if (key['kty'] != 'RSA' && key['kty'] != 'EC') continue;
        if (key.containsKey('d') || key.containsKey('k')) {
          throw StateError('Private JWKS key');
        }
        if (keys.containsKey(kid)) throw StateError('Duplicate kid');
        keys[kid] = JsonWebKey.fromJson(key);
      }
      _keys = keys;
      _expiresAt = _now().add(cacheTtl);
    } catch (_) {
      // Never expose a token, HTTP response, or crypto exception to the client.
      throw _failure('jwksUnavailable');
    }
  }

  Future<({String sub, String aal})> validateToken(String? token) async {
    if (token == null || token.isEmpty) throw _failure('tokenMissing');
    try {
      if (token.length > 16384) throw _failure('tokenInvalid');
      final jws = JsonWebSignature.fromCompactSerialization(token);
      final header = jws.unverifiedPayload.protectedHeader!;
      final alg = header['alg'];
      final kid = header['kid'];
      if (!const {'ES256', 'RS256'}.contains(alg) ||
          kid is! String ||
          kid.isEmpty ||
          header['crit'] != null ||
          header['b64'] != null) {
        throw _failure('tokenInvalid');
      }
      if (_expiresAt == null || !_expiresAt!.isAfter(_now())) await _refresh();
      if (!_keys.containsKey(kid)) await _refresh();
      // Do not use expired cached keys, including during outages/cooldown.
      if (_expiresAt == null || !_expiresAt!.isAfter(_now())) {
        throw _failure('jwksUnavailable');
      }
      final key = _keys[kid];
      if (key == null ||
          (key['use'] != null && key['use'] != 'sig') ||
          (alg == 'ES256' && (key['kty'] != 'EC' || key['crv'] != 'P-256')) ||
          (alg == 'RS256' && key['kty'] != 'RSA')) {
        throw _failure('tokenInvalid');
      }
      if (!await jws.verify(JsonWebKeyStore()..addKey(key))) {
        throw _failure('tokenInvalid');
      }
      final claims = jws.unverifiedPayload.jsonContent as Map<String, dynamic>;
      if (claims['iss'] != issuer) throw _failure('tokenInvalid');
      final exp = claims['exp'];
      if (exp is! int) throw _failure('tokenInvalid');
      final seconds = _now().millisecondsSinceEpoch / 1000;
      if (exp <= seconds) throw _failure('tokenExpired');
      final nbf = claims['nbf'];
      if (nbf != null && (nbf is! int || nbf > seconds)) {
        throw _failure('tokenInvalid');
      }
      final sub = claims['sub'];
      final aal = claims['aal'];
      if (sub is! String ||
          sub.trim().isEmpty ||
          (aal != 'aal1' && aal != 'aal2')) {
        throw _failure('tokenInvalid');
      }
      // Supabase access tokens are for authenticated users, not API keys.
      if (claims['aud'] != 'authenticated' &&
          !(claims['aud'] is List &&
              (claims['aud'] as List).contains('authenticated'))) {
        throw _failure('tokenInvalid');
      }
      return (sub: sub, aal: aal as String);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw _failure('tokenInvalid');
    }
  }

  Future<AuthenticatedUsuario> authenticate(
    String? token, {
    required Future<Usuario?> Function(String sub) findUsuario,
    bool requireAal2 = false,
  }) async {
    final claims = await validateToken(token);
    final usuario = await findUsuario(claims.sub);
    if (usuario == null) throw _failure('usuarioNotFound');
    if (requireAal2 && claims.aal != 'aal2') throw _failure('aal2Required');
    return AuthenticatedUsuario(usuario, claims.sub, claims.aal);
  }

  Future<({String sub, String aal})> claimsForSession(Session session) {
    final token = session.authenticationKey;
    final cached = _sessionClaims[session];
    if (cached != null && cached.token == token) return cached.claims;
    final claims = validateToken(token);
    _sessionClaims[session] = (token: token, claims: claims);
    return claims;
  }

  Future<AuthenticatedUsuario> usuarioForSession(Session session) async {
    final claims = await claimsForSession(session);
    final usuario = await Usuario.db.findFirstRow(
      session,
      where: (t) => t.supabaseUserId.equals(claims.sub),
    );
    if (usuario == null) throw _failure('usuarioNotFound');
    return AuthenticatedUsuario(usuario, claims.sub, claims.aal);
  }
}

SupabaseAuthService? _service;

SupabaseAuthService _configuredService() {
  final url = Platform.environment['SUPABASE_URL'];
  if (url == null || url.isEmpty) throw _failure('authNotConfigured');
  return _service ??= SupabaseAuthService(supabaseUrl: url);
}

/// Serverpod initializes authentication before dispatch, even on public RPCs.
/// Invalid credentials stay unauthenticated; guards expose typed error codes.
/// Internal provisioning and mandatory AAL2 are enforced by the guards below.
Future<AuthenticationInfo?> supabaseAuthenticationHandler(
  Session session,
  String token,
) async {
  try {
    final claims = await _configuredService().claimsForSession(session);
    return AuthenticationInfo(
      claims.sub,
      {if (claims.aal == 'aal2') Scope('supabase.aal2')},
      authId: claims.sub,
    );
  } on AuthException {
    return null;
  }
}

/// Serverpod 3.4.11 unwraps Authorization: Bearer into authenticationKey.
Future<AuthenticatedUsuario> requireAuthenticatedUsuario(
  Session session, {
  SupabaseAuthService? authService,
}) {
  final token = session.authenticationKey;
  if (token == null || token.isEmpty) throw _failure('tokenMissing');
  return (authService ?? _configuredService()).usuarioForSession(session);
}

Future<AuthenticatedUsuario> requireAal2Usuario(
  Session session, {
  SupabaseAuthService? authService,
}) async {
  final usuario = await requireAuthenticatedUsuario(
    session,
    authService: authService,
  );
  if (usuario.aal != 'aal2') throw _failure('aal2Required');
  return usuario;
}
