import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_session.dart';
import 'auth_callback_storage.dart';
import 'auth_callback_diagnostics.dart';

enum CallbackFlow { invite, recovery }

enum CallbackStatus { valid, expired, invalid, unavailable }

/// A new email link is only inspected here. Verification is a separate action.
/// The credential stays in memory, never in callback/session storage or logs.
class AuthConfirmationIntent {
  AuthConfirmationIntent._(this._tokenHash, this.flow, this._diagnostics);

  final String _tokenHash;
  final CallbackFlow flow;
  final CallbackDiagnostics _diagnostics;
  bool _submitted = false;

  static AuthConfirmationIntent? parse(
    Uri uri, {
    CallbackDiagnostics diagnostics = callbackDiagnostics,
  }) {
    final fragmentRoute = Uri.tryParse(uri.fragment);
    final validLocation =
        uri.path == '/auth/confirm' ||
        ((uri.path == '/' || uri.path.isEmpty) &&
            fragmentRoute?.path == '/auth/confirm');
    if (!validLocation ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      diagnostics.emit(
        CallbackDiagnosticStage.confirmation,
        CallbackDiagnosticReason.parametersInvalid,
      );
      return null;
    }
    final params = _parameters(uri, diagnostics, fragmentPath: '/auth/confirm');
    if (params == null) return null;
    final tokenHash = params['token_hash'];
    final type = params['type'];
    // Supabase Auth generates a SHA-224 hex hash, with an optional PKCE prefix.
    if (params.length != 2 ||
        !params.keys.every(const {'token_hash', 'type'}.contains) ||
        tokenHash == null ||
        !RegExp(r'^(?:pkce_)?[0-9a-f]{56}$').hasMatch(tokenHash) ||
        (type != 'invite' && type != 'recovery')) {
      diagnostics.emit(
        CallbackDiagnosticStage.confirmation,
        CallbackDiagnosticReason.parametersInvalid,
      );
      return null;
    }
    diagnostics.emit(
      CallbackDiagnosticStage.confirmation,
      CallbackDiagnosticReason.confirmationReady,
    );
    return AuthConfirmationIntent._(
      tokenHash,
      type == 'invite' ? CallbackFlow.invite : CallbackFlow.recovery,
      diagnostics,
    );
  }

  /// Called only by the explicit confirmation button. No automatic retry.
  Future<CallbackResult> confirm(AuthCallbackProcessor processor) async {
    if (_submitted) {
      _diagnostics.emit(
        CallbackDiagnosticStage.confirmation,
        CallbackDiagnosticReason.confirmationAlreadySubmitted,
      );
      return const CallbackResult(CallbackStatus.invalid);
    }
    _submitted = true;
    _diagnostics.emit(
      CallbackDiagnosticStage.confirmation,
      CallbackDiagnosticReason.confirmationSubmitted,
    );
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
  AuthCallbackProcessor(
    this.session, {
    CallbackStorage? storage,
    this.diagnostics = callbackDiagnostics,
  }) : storage = storage ?? browserCallbackStorage;

  final SupabaseSession? session;
  final CallbackStorage storage;
  final CallbackDiagnostics diagnostics;
  bool _hasProcessed = false;

  static const _key = 'temdas.auth.callback.v1';

  void clear() => storage.remove(_key);

  /// Confirms the callback still belongs to the active Supabase user.
  Future<CallbackStatus> verifyActiveSession(String userId) async {
    final client = session?.client;
    if (client == null) {
      diagnostics.emit(
        CallbackDiagnosticStage.session,
        CallbackDiagnosticReason.clientUnavailable,
      );
      return CallbackStatus.unavailable;
    }
    try {
      var current = session?.currentSession;
      if (current == null || current.user.id != userId) {
        diagnostics.emit(
          CallbackDiagnosticStage.session,
          current == null
              ? CallbackDiagnosticReason.sessionAbsent
              : CallbackDiagnosticReason.sessionUserMismatch,
          afterRefresh: false,
          hasSession: current != null,
          userMatches: false,
        );
        return CallbackStatus.expired;
      }
      if (current.isExpired) {
        await client.auth.refreshSession();
        current = session?.currentSession;
      }
      if (current == null || current.user.id != userId) {
        diagnostics.emit(
          CallbackDiagnosticStage.session,
          current == null
              ? CallbackDiagnosticReason.sessionAbsent
              : CallbackDiagnosticReason.sessionUserMismatch,
          afterRefresh: true,
          hasSession: current != null,
          userMatches: false,
        );
        return CallbackStatus.expired;
      }
      final user = (await client.auth.getUser()).user;
      diagnostics.emit(
        CallbackDiagnosticStage.session,
        user?.id == userId && session?.currentSession?.user.id == userId
            ? CallbackDiagnosticReason.sessionVerified
            : CallbackDiagnosticReason.sessionUserUnverified,
        hasUser: user != null,
        userMatches:
            user?.id == userId && session?.currentSession?.user.id == userId,
      );
      return user?.id == userId && session?.currentSession?.user.id == userId
          ? CallbackStatus.valid
          : CallbackStatus.expired;
    } on AuthRetryableFetchException {
      diagnostics.emit(
        CallbackDiagnosticStage.session,
        CallbackDiagnosticReason.operationUnavailable,
      );
      return CallbackStatus.unavailable;
    } on AuthException catch (error) {
      final statusCode = int.tryParse(error.statusCode ?? '');
      diagnostics.emit(
        CallbackDiagnosticStage.session,
        statusCode != null && statusCode >= 500
            ? CallbackDiagnosticReason.operationUnavailable
            : CallbackDiagnosticReason.authExceptionExpired,
      );
      return statusCode != null && statusCode >= 500
          ? CallbackStatus.unavailable
          : CallbackStatus.expired;
    } catch (_) {
      diagnostics.emit(
        CallbackDiagnosticStage.session,
        CallbackDiagnosticReason.operationUnavailable,
      );
      return CallbackStatus.unavailable;
    }
  }

  Future<CallbackResult> process(Uri uri) async {
    if (_hasProcessed) {
      // This proves a processor was invoked again, not that a token was reused.
      diagnostics.emit(
        CallbackDiagnosticStage.parameters,
        CallbackDiagnosticReason.processorReentered,
      );
    }
    _hasProcessed = true;
    final client = session?.client;
    if (client == null) {
      diagnostics.emit(
        CallbackDiagnosticStage.parameters,
        CallbackDiagnosticReason.clientUnavailable,
      );
      return const CallbackResult(CallbackStatus.unavailable);
    }

    final params = _parameters(uri, diagnostics);
    if (params == null) return const CallbackResult(CallbackStatus.invalid);

    final hasPayload =
        params.containsKey('code') ||
        params.containsKey('token_hash') ||
        params.containsKey('access_token') ||
        params.containsKey('error') ||
        params.containsKey('error_code') ||
        params.containsKey('error_description');
    if (!hasPayload) {
      diagnostics.emit(
        CallbackDiagnosticStage.parameters,
        CallbackDiagnosticReason.payloadAbsent,
      );
      return _restore();
    }
    if ([
      'code',
      'token_hash',
      'access_token',
    ].any((key) => params.containsKey(key) && params[key]!.isEmpty)) {
      diagnostics.emit(
        CallbackDiagnosticStage.parameters,
        CallbackDiagnosticReason.parameterEmpty,
      );
    }

    // A new link supersedes a previous callback, even when it fails.
    storage.remove(_key);
    final requestedFlow = _flow(params['type']);
    if (params.containsKey('token_hash') && requestedFlow == null) {
      diagnostics.emit(
        CallbackDiagnosticStage.parameters,
        CallbackDiagnosticReason.requestedFlowUnknown,
        hasTokenHash: true,
      );
      return const CallbackResult(CallbackStatus.invalid);
    }
    if (params.containsKey('access_token') && requestedFlow == null) {
      diagnostics.emit(
        CallbackDiagnosticStage.parameters,
        CallbackDiagnosticReason.requestedFlowUnknown,
        hasAccessToken: true,
      );
      return const CallbackResult(CallbackStatus.invalid);
    }

    try {
      diagnostics.emit(
        CallbackDiagnosticStage.exchange,
        CallbackDiagnosticReason.exchangeStarted,
        hasCode: params.containsKey('code'),
        hasTokenHash: params.containsKey('token_hash'),
        hasAccessToken: params.containsKey('access_token'),
        hasRequestedFlow: params.containsKey('type'),
        hasProviderError: [
          'error',
          'error_code',
          'error_description',
        ].any(params.containsKey),
      );
      AuthResponse? otpResponse;
      AuthSessionUrlResponse? urlResponse;
      if (params.containsKey('token_hash') &&
          !params.containsKey('code') &&
          !params.containsKey('access_token')) {
        final tokenHash = params['token_hash'];
        if (tokenHash == null || tokenHash.isEmpty) {
          diagnostics.emit(
            CallbackDiagnosticStage.parameters,
            CallbackDiagnosticReason.parameterEmpty,
            hasTokenHash: true,
          );
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
        diagnostics.emit(
          CallbackDiagnosticStage.exchange,
          callbackSession == null
              ? CallbackDiagnosticReason.sessionAbsentAfterExchange
              : callbackSession.user.id.isEmpty
              ? CallbackDiagnosticReason.sessionUserEmpty
              : session?.currentSession == null
              ? CallbackDiagnosticReason.sessionAbsentAfterExchange
              : session?.currentSession?.user.id != callbackSession.user.id
              ? CallbackDiagnosticReason.sessionUserMismatch
              : CallbackDiagnosticReason.flowsMismatch,
          hasSession: callbackSession != null,
          hasCurrentSession: session?.currentSession != null,
          userMatches:
              callbackSession != null &&
              session?.currentSession?.user.id == callbackSession.user.id,
        );
        return const CallbackResult(CallbackStatus.invalid);
      }
      final flow = returnedFlow ?? requestedFlow;
      if (flow == null) {
        diagnostics.emit(
          CallbackDiagnosticStage.exchange,
          CallbackDiagnosticReason.returnedFlowUnknown,
          hasRequestedFlow: params.containsKey('type'),
          hasReturnedFlow: urlResponse?.redirectType != null,
        );
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
      diagnostics.emit(
        CallbackDiagnosticStage.exchange,
        CallbackDiagnosticReason.callbackAccepted,
      );
      return CallbackResult(
        CallbackStatus.valid,
        flow,
        callbackSession.user.id,
      );
    } on AuthException catch (error) {
      if (params.containsKey('code') &&
          ![
            'error',
            'error_code',
            'error_description',
          ].any(params.containsKey)) {
        diagnostics.emit(
          CallbackDiagnosticStage.exchange,
          CallbackDiagnosticReason.pkceExchangeFailed,
        );
        final pkceReason = switch (error.code) {
          'bad_code_verifier' => CallbackDiagnosticReason.pkceVerifierRejected,
          'flow_state_not_found' =>
            CallbackDiagnosticReason.pkceFlowStateMissing,
          _
              when error.message ==
                  'Code verifier could not be found in local storage.' =>
            CallbackDiagnosticReason.pkceVerifierMissing,
          _ => null,
        };
        if (pkceReason != null) {
          diagnostics.emit(CallbackDiagnosticStage.exchange, pkceReason);
        }
      }
      // These codes can mean expiration or reuse. Never claim consumption is
      // proven, and never emit the SDK's arbitrary code/message values.
      if (const [
        'otp_expired',
        'flow_state_not_found',
        'flow_state_expired',
      ].contains(error.code)) {
        diagnostics.emit(
          CallbackDiagnosticStage.exchange,
          CallbackDiagnosticReason.callbackReuseOrExpiryReported,
        );
      }
      diagnostics.emit(
        CallbackDiagnosticStage.exchange,
        _isExpired(error)
            ? CallbackDiagnosticReason.authExceptionExpired
            : CallbackDiagnosticReason.authExceptionInvalid,
      );
      return CallbackResult(
        _isExpired(error) ? CallbackStatus.expired : CallbackStatus.invalid,
        requestedFlow,
      );
    } catch (_) {
      diagnostics.emit(
        CallbackDiagnosticStage.exchange,
        CallbackDiagnosticReason.operationUnavailable,
      );
      return CallbackResult(CallbackStatus.unavailable, requestedFlow);
    }
  }

  Future<CallbackResult> _restore() async {
    final raw = storage.read(_key);
    if (raw == null) {
      diagnostics.emit(
        CallbackDiagnosticStage.restore,
        CallbackDiagnosticReason.callbackStateMissing,
      );
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
        diagnostics.emit(
          CallbackDiagnosticStage.restore,
          flow == null || userId == null || createdAt == null
              ? CallbackDiagnosticReason.callbackStateIncomplete
              : CallbackDiagnosticReason.callbackStateTooOld,
        );
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
      diagnostics.emit(
        CallbackDiagnosticStage.restore,
        CallbackDiagnosticReason.callbackRestored,
      );
      return CallbackResult(CallbackStatus.valid, flow, userId);
    } catch (_) {
      storage.remove(_key);
      diagnostics.emit(
        CallbackDiagnosticStage.restore,
        CallbackDiagnosticReason.callbackStateMalformed,
      );
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
  Uri uri,
  CallbackDiagnostics diagnostics, {
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
    diagnostics.emit(
      CallbackDiagnosticStage.parameters,
      CallbackDiagnosticReason.parametersInvalid,
    );
    return null;
  }

  // Repetitions within either source are invalid even if their values match.
  if ([
    query,
    fragmentParameters,
  ].any((source) => source.values.any((values) => values.length != 1))) {
    diagnostics.emit(
      CallbackDiagnosticStage.parameters,
      CallbackDiagnosticReason.parametersDuplicate,
    );
    return null;
  }

  final merged = query.map((key, values) => MapEntry(key, values.single));
  for (final entry in fragmentParameters.entries) {
    final value = entry.value.single;
    if (merged.containsKey(entry.key) && merged[entry.key] != value) {
      diagnostics.emit(
        CallbackDiagnosticStage.parameters,
        CallbackDiagnosticReason.parametersConflicting,
      );
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
    diagnostics.emit(
      CallbackDiagnosticStage.parameters,
      CallbackDiagnosticReason.parametersAmbiguous,
    );
    return null;
  }
  return merged;
}
