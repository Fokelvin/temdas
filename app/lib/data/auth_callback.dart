import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_session.dart';
import 'auth_callback_storage.dart';

enum CallbackFlow { invite, recovery }

enum CallbackStatus { valid, expired, invalid, unavailable }

/// A new email link is only inspected here. Verification is a separate action.
/// The credential stays in memory, never in callback/session storage or logs.
class AuthConfirmationIntent {
  AuthConfirmationIntent._(this._tokenHash, this.flow);

  final String _tokenHash;
  final CallbackFlow flow;

  bool _submitted = false;

  static AuthConfirmationIntent? parse(Uri uri) {
    final fragmentRoute = Uri.tryParse(uri.fragment);
    final validLocation =
        uri.path == '/auth/confirm' ||
        ((uri.path == '/' || uri.path.isEmpty) &&
            fragmentRoute?.path == '/auth/confirm');
    if (!validLocation ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    // A direct email entry takes precedence over Flutter's default hash route.
    // Ignore only that exact, parameter-free navigation marker: credentials or
    // any other fragment still go through the strict parser unchanged.
    final parameterUri =
        uri.path == '/auth/confirm' && uri.fragment == '/demandas'
        ? uri.replace(fragment: '')
        : uri;
    final params = _parameters(parameterUri, fragmentPath: '/auth/confirm');
    if (params == null) return null;
    final tokenHash = params['token_hash'];
    final type = params['type'];
    // Supabase Auth generates a SHA-224 hex hash, with an optional PKCE prefix.
    if (params.length != 2 ||
        !params.keys.every(const {'token_hash', 'type'}.contains) ||
        tokenHash == null ||
        !RegExp(r'^(?:pkce_)?[0-9a-f]{56}$').hasMatch(tokenHash) ||
        (type != 'invite' && type != 'recovery')) {
      return null;
    }

    return AuthConfirmationIntent._(
      tokenHash,
      type == 'invite' ? CallbackFlow.invite : CallbackFlow.recovery,
    );
  }

  /// Called only by the explicit confirmation button. No automatic retry.
  Future<CallbackResult> confirm(AuthCallbackProcessor processor) async {
    if (_submitted) {
      return const CallbackResult(CallbackStatus.invalid);
    }
    _submitted = true;

    return processor.process(
      Uri(
        path: '/auth/callback',
        queryParameters: {'token_hash': _tokenHash, 'type': flow.name},
      ),
    );
  }
}

class CallbackResult {
  const CallbackResult(this.status, [this.flow, this.userId]);

  final CallbackStatus status;
  final CallbackFlow? flow;
  final String? userId;
}

/// Only the flow label and user ID are stored. Supabase owns session storage.
class AuthCallbackProcessor {
  AuthCallbackProcessor(this.session, {CallbackStorage? storage})
    : storage = storage ?? browserCallbackStorage;

  final SupabaseSession? session;
  final CallbackStorage storage;

  static const _key = 'temdas.auth.callback.v1';

  void clear() => storage.remove(_key);

  /// Confirms the callback still belongs to the active Supabase user.
  Future<CallbackStatus> verifyActiveSession(String userId) async {
    final client = session?.client;
    if (client == null) {
      return CallbackStatus.unavailable;
    }
    try {
      var current = session?.currentSession;
      if (current == null || current.user.id != userId) {
        return CallbackStatus.expired;
      }
      if (current.isExpired) {
        await client.auth.refreshSession();
        current = session?.currentSession;
      }
      if (current == null || current.user.id != userId) {
        return CallbackStatus.expired;
      }
      final user = (await client.auth.getUser()).user;

      return user?.id == userId && session?.currentSession?.user.id == userId
          ? CallbackStatus.valid
          : CallbackStatus.expired;
    } on AuthRetryableFetchException {
      return CallbackStatus.unavailable;
    } on AuthException catch (error) {
      final statusCode = int.tryParse(error.statusCode ?? '');

      return statusCode != null && statusCode >= 500
          ? CallbackStatus.unavailable
          : CallbackStatus.expired;
    } catch (_) {
      return CallbackStatus.unavailable;
    }
  }

  Future<CallbackResult> process(Uri uri) async {
    final client = session?.client;
    if (client == null) {
      return const CallbackResult(CallbackStatus.unavailable);
    }

    final params = _parameters(uri);
    if (params == null) return const CallbackResult(CallbackStatus.invalid);

    final hasPayload =
        params.containsKey('code') ||
        params.containsKey('token_hash') ||
        params.containsKey('access_token') ||
        params.containsKey('error') ||
        params.containsKey('error_code') ||
        params.containsKey('error_description');
    if (!hasPayload) {
      return _restore();
    }
    // A new link supersedes a previous callback, even when it fails.
    storage.remove(_key);
    final requestedFlow = _flow(params['type']);
    if (params.containsKey('token_hash') && requestedFlow == null) {
      return const CallbackResult(CallbackStatus.invalid);
    }
    if (params.containsKey('access_token') && requestedFlow == null) {
      return const CallbackResult(CallbackStatus.invalid);
    }

    try {
      AuthResponse? otpResponse;
      AuthSessionUrlResponse? urlResponse;
      if (params.containsKey('token_hash') &&
          !params.containsKey('code') &&
          !params.containsKey('access_token')) {
        final tokenHash = params['token_hash'];
        if (tokenHash == null || tokenHash.isEmpty) {
          return const CallbackResult(CallbackStatus.invalid);
        }
        otpResponse = await client.auth.verifyOTP(
          tokenHash: tokenHash,
          type: requestedFlow == CallbackFlow.invite
              ? OtpType.invite
              : OtpType.recovery,
        );
      } else {
        urlResponse = await client.auth.getSessionFromUrl(
          uri.replace(
            path: '/auth/callback',
            queryParameters: params,
            fragment: '',
          ),
        );
      }
      final callbackSession = otpResponse?.session ?? urlResponse?.session;
      final returnedFlow = _flow(urlResponse?.redirectType);
      if (callbackSession == null ||
          callbackSession.user.id.isEmpty ||
          session?.currentSession?.user.id != callbackSession.user.id ||
          (returnedFlow != null &&
              requestedFlow != null &&
              returnedFlow != requestedFlow)) {
        return const CallbackResult(CallbackStatus.invalid);
      }
      final flow = returnedFlow ?? requestedFlow;
      if (flow == null) {
        return const CallbackResult(CallbackStatus.invalid);
      }
      storage.write(
        _key,
        jsonEncode({
          'flow': flow.name,
          'userId': callbackSession.user.id,
          'createdAt': DateTime.now().toUtc().millisecondsSinceEpoch,
        }),
      );

      return CallbackResult(
        CallbackStatus.valid,
        flow,
        callbackSession.user.id,
      );
    } on AuthException catch (error) {
      return CallbackResult(
        _isExpired(error) ? CallbackStatus.expired : CallbackStatus.invalid,
        requestedFlow,
      );
    } catch (_) {
      return CallbackResult(CallbackStatus.unavailable, requestedFlow);
    }
  }

  Future<CallbackResult> _restore() async {
    final raw = storage.read(_key);
    if (raw == null) {
      return const CallbackResult(CallbackStatus.invalid);
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final flow = _flow(data['flow'] as String?);
      final userId = data['userId'] as String?;
      final createdAt = data['createdAt'] as int?;
      if (flow == null ||
          userId == null ||
          createdAt == null ||
          DateTime.now().toUtc().millisecondsSinceEpoch - createdAt >
              const Duration(minutes: 15).inMilliseconds) {
        storage.remove(_key);

        return const CallbackResult(CallbackStatus.invalid);
      }
      final status = await verifyActiveSession(userId);
      if (status != CallbackStatus.valid) {
        if (status == CallbackStatus.unavailable) {
          return CallbackResult(status, flow);
        }
        storage.remove(_key);
        return CallbackResult(CallbackStatus.expired, flow);
      }

      return CallbackResult(CallbackStatus.valid, flow, userId);
    } catch (_) {
      storage.remove(_key);

      return const CallbackResult(CallbackStatus.invalid);
    }
  }
}

CallbackFlow? _flow(String? value) => switch (value) {
  'invite' => CallbackFlow.invite,
  'recovery' || 'passwordRecovery' => CallbackFlow.recovery,
  _ => null,
};

bool _isExpired(AuthException error) {
  final detail = '${error.code} ${error.statusCode} ${error.message}'
      .toLowerCase();
  return detail.contains('otp_expired') ||
      detail.contains('token_expired') ||
      detail.contains('expired') ||
      detail.contains('expirado');
}

Map<String, String>? _parameters(
  Uri uri, {
  String fragmentPath = '/auth/callback',
}) {
  Map<String, List<String>> decodeSource(String query) {
    // Validate encoding and UTF-8 before collecting decoded values. Retain
    // every occurrence of each key, without decoding the resulting values again.
    Uri.decodeQueryComponent(query);
    return Uri(query: query).queryParametersAll;
  }

  final Map<String, List<String>> query;
  var fragmentParameters = <String, List<String>>{};
  try {
    query = decodeSource(uri.query);
    final fragment = uri.fragment;
    if (fragment.startsWith(fragmentPath)) {
      final route = Uri.tryParse(fragment);
      if (route == null || route.path != fragmentPath || route.hasFragment) {
        throw const FormatException();
      }
      // Inspect the original query before parsing can normalize its escapes.
      final separator = fragment.indexOf('?');
      fragmentParameters = decodeSource(
        separator < 0 ? '' : fragment.substring(separator + 1),
      );
    } else if (fragment.isNotEmpty) {
      if (!fragment.contains('=') ||
          fragment.startsWith('/') ||
          fragment.startsWith('?') ||
          fragment.contains('#') ||
          Uri.tryParse(fragment)?.hasScheme == true) {
        throw const FormatException();
      }
      fragmentParameters = decodeSource(fragment);
    }
    if ([query, fragmentParameters].any((source) => source.containsKey(''))) {
      throw const FormatException();
    }
  } on FormatException {
    return null;
  }

  // Repetitions within either source are invalid even if their values match.
  if ([
    query,
    fragmentParameters,
  ].any((source) => source.values.any((values) => values.length != 1))) {
    return null;
  }

  final merged = query.map((key, values) => MapEntry(key, values.single));
  for (final entry in fragmentParameters.entries) {
    final value = entry.value.single;
    if (merged.containsKey(entry.key) && merged[entry.key] != value) {
      return null;
    }
    // Flutter Web can mirror the main query into its hash route. Equal decoded
    // values represent one parameter, not two independent credential sources.
    merged[entry.key] = value;
  }

  final credentialCount = [
    'code',
    'token_hash',
    'access_token',
  ].where(merged.containsKey).length;
  final hasProviderError = [
    'error',
    'error_code',
    'error_description',
  ].any(merged.containsKey);
  final hasSessionParameters = [
    'access_token',
    'refresh_token',
    'expires_in',
    'expires_at',
    'token_type',
    'provider_token',
    'provider_refresh_token',
  ].any(merged.containsKey);
  final mixesSessionAndExchange =
      hasSessionParameters &&
      (merged.containsKey('code') || merged.containsKey('token_hash'));
  if (credentialCount > 1 ||
      mixesSessionAndExchange ||
      ((credentialCount > 0 || hasSessionParameters) && hasProviderError)) {
    return null;
  }
  return merged;
}
