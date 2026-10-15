import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_session.dart';
import 'auth_callback_storage.dart';

enum CallbackFlow { invite, recovery }

enum CallbackStatus { valid, expired, invalid, unavailable }

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
    if (client == null) return CallbackStatus.unavailable;
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
    if (client == null) return const CallbackResult(CallbackStatus.unavailable);

    final params = _parameters(uri);
    if (params == null) return const CallbackResult(CallbackStatus.invalid);

    final hasPayload =
        params.containsKey('code') ||
        params.containsKey('token_hash') ||
        params.containsKey('access_token') ||
        params.containsKey('error') ||
        params.containsKey('error_code') ||
        params.containsKey('error_description');
    if (!hasPayload) return _restore();

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
      if (flow == null) return const CallbackResult(CallbackStatus.invalid);
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
    if (raw == null) return const CallbackResult(CallbackStatus.invalid);
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

Map<String, String>? _parameters(Uri uri) {
  final all = <String, List<String>>{};
  void add(Map<String, List<String>> source) {
    for (final entry in source.entries) {
      all.putIfAbsent(entry.key, () => []).addAll(entry.value);
    }
  }

  add(uri.queryParametersAll);
  final fragment = uri.fragment;
  if (fragment.startsWith('/auth/callback')) {
    final route = Uri.tryParse(fragment);
    if (route == null || route.path != '/auth/callback') return null;
    add(route.queryParametersAll);
  } else if (fragment.contains('=')) {
    try {
      add(
        Uri.splitQueryString(
          fragment,
        ).map((key, value) => MapEntry(key, [value])),
      );
    } on FormatException {
      return null;
    }
  }
  if (all.values.any((values) => values.length != 1)) return null;
  return all.map((key, values) => MapEntry(key, values.single));
}
