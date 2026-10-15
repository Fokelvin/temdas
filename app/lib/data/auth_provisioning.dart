import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'serverpod_client.dart';
import 'supabase_session.dart';

/// Deduplicates backend checks for one Supabase login across AuthGate routes.
class AuthProvisioning {
  AuthProvisioning({
    Future<backend.AuthMe> Function()? provisionar,
    Future<backend.AuthMe> Function()? me,
  }) : _provisionar = provisionar ?? (() => serverpodClient.auth.provisionar()),
       _me = me ?? (() => serverpodClient.auth.me());

  final Future<backend.AuthMe> Function() _provisionar;
  final Future<backend.AuthMe> Function() _me;

  SupabaseSession? _owner;
  String? _userId;
  String? _loginRefreshToken;
  Future<backend.AuthMe>? _provisioning;
  String? _confirmedToken;
  Future<backend.AuthMe>? _confirmation;
  int _generation = 0;
  final Expando<bool> _observedEvents = Expando<bool>();

  void observeAuthChange(SupabaseSession? session, AuthState change) {
    // GoTrue replays old AuthState objects to every new AuthGate route.
    if (_observedEvents[change] == true) return;
    _observedEvents[change] = true;
    if (change.event == AuthChangeEvent.signedOut) {
      clearFor(session);
    } else if (change.event == AuthChangeEvent.signedIn) {
      if (identical(_owner, session) &&
          _userId == change.session?.user.id &&
          _loginRefreshToken == change.session?.refreshToken) {
        return;
      }
      clearFor(session);
    }
  }

  void clearFor(SupabaseSession? session) {
    if (session == null || identical(_owner, session)) {
      _generation++;
      _owner = null;
      _userId = null;
      _loginRefreshToken = null;
      _provisioning = null;
      _confirmedToken = null;
      _confirmation = null;
    }
  }

  void _select(SupabaseSession session, String userId) {
    if (identical(_owner, session) && _userId == userId) return;
    clearFor(null);
    _owner = session;
    _userId = userId;
    _loginRefreshToken = session.currentSession?.refreshToken;
  }

  Future<backend.AuthMe> provisionFor(SupabaseSession session, String userId) {
    _select(session, userId);
    return _provisioning ??= _runProvision(_generation);
  }

  Future<backend.AuthMe> _runProvision(int generation) async {
    try {
      return await _provisionar();
    } catch (_) {
      if (_generation == generation) _provisioning = null;
      rethrow;
    }
  }

  Future<backend.AuthMe> confirmAal2For(
    SupabaseSession session,
    String userId,
    String accessToken,
  ) {
    _select(session, userId);
    if (_confirmedToken != accessToken) {
      _confirmedToken = accessToken;
      _confirmation = null;
    }
    return _confirmation ??= _runConfirmation(_generation, accessToken);
  }

  Future<backend.AuthMe> _runConfirmation(
    int generation,
    String accessToken,
  ) async {
    try {
      return await _me();
    } catch (_) {
      if (_generation == generation && _confirmedToken == accessToken) {
        _confirmation = null;
      }
      rethrow;
    }
  }
}

final authProvisioning = AuthProvisioning();
