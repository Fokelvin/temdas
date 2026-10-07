import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_session.dart';
import '../view/auth_pages.dart';

enum AuthGateState {
  loading,
  signedOut,
  enroll,
  challenge,
  authenticated,
  error,
}

AuthGateState resolveAuthGateState({
  required bool hasSession,
  required AuthenticatorAssuranceLevels? aal,
  required bool hasVerifiedTotp,
}) {
  if (!hasSession) return AuthGateState.signedOut;
  if (aal == AuthenticatorAssuranceLevels.aal2) {
    return AuthGateState.authenticated;
  }
  return hasVerifiedTotp ? AuthGateState.challenge : AuthGateState.enroll;
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child, this.session});
  final Widget child;
  final SupabaseSession? session;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthGateState _state = AuthGateState.loading;
  List<Factor> _factors = const [];
  StreamSubscription<AuthState>? _subscription;
  bool _evaluating = false;
  bool _reevaluate = false;
  String? _error;

  SupabaseSession? get _session => widget.session ?? supabaseSession;

  @override
  void initState() {
    super.initState();
    final session = _session;
    if (session != null) {
      _subscription = session.authChanges.listen(_onAuthChange);
    }
    unawaited(_evaluate());
  }

  void _onAuthChange(AuthState change) {
    if (change.event == AuthChangeEvent.tokenRefreshed && _evaluating) return;
    if (_evaluating) {
      _reevaluate = true;
      return;
    }
    unawaited(_evaluate());
  }

  Future<void> _evaluate() async {
    if (_evaluating) {
      _reevaluate = true;
      return;
    }
    _evaluating = true;
    do {
      _reevaluate = false;
      final session = _session;
      if (session == null || session.currentSession == null) {
        _publish(AuthGateState.signedOut, const []);
        continue;
      }
      try {
        if (session.currentSession!.isExpired) {
          await session.client.auth.refreshSession();
        }
        var aal = session.client.auth.mfa.getAuthenticatorAssuranceLevel();
        if (aal.currentLevel == AuthenticatorAssuranceLevels.aal2) {
          _publish(AuthGateState.authenticated, const []);
          continue;
        }
        // listFactors refreshes the token and includes pending factors in all.
        final factors = await session.client.auth.mfa.listFactors();
        aal = session.client.auth.mfa.getAuthenticatorAssuranceLevel();
        final totp = factors.all
            .where((factor) => factor.factorType == FactorType.totp)
            .toList();
        final state = resolveAuthGateState(
          hasSession: session.currentSession != null,
          aal: aal.currentLevel,
          hasVerifiedTotp: factors.totp.isNotEmpty,
        );
        _publish(state, totp);
      } catch (error) {
        if (session.currentSession == null) {
          _publish(AuthGateState.signedOut, const []);
        } else {
          _error = _friendlyAuthError(error);
          _publish(AuthGateState.error, const []);
        }
      }
    } while (_reevaluate && mounted);
    _evaluating = false;
  }

  void _publish(AuthGateState state, List<Factor> factors) {
    if (!mounted) return;
    setState(() {
      _state = state;
      _factors = factors;
      if (state != AuthGateState.error) _error = null;
    });
  }

  Future<void> _signOut() async {
    await _session?.signOut();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (_state) {
    AuthGateState.loading => const _GateLoading(),
    AuthGateState.signedOut => LoginPage(session: _session),
    AuthGateState.enroll => MfaEnrollPage(
      session: _session!,
      factors: _factors,
      onSignOut: _signOut,
    ),
    AuthGateState.challenge => MfaChallengePage(
      session: _session!,
      factors: _factors,
      onSignOut: _signOut,
    ),
    AuthGateState.authenticated => widget.child,
    AuthGateState.error => _GateError(
      message: _error ?? 'Não foi possível validar a sessão.',
      onRetry: _evaluate,
      onSignOut: _signOut,
    ),
  };
}

String _friendlyAuthError(Object error) {
  if (error is AuthException) return error.message;
  return 'Não foi possível validar sua sessão. Verifique a conexão e tente novamente.';
}

class _GateLoading extends StatelessWidget {
  const _GateLoading();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Verificando sessão…'),
        ],
      ),
    ),
  );
}

class _GateError extends StatelessWidget {
  const _GateError({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível validar a sessão',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
              TextButton(onPressed: onSignOut, child: const Text('Sair')),
            ],
          ),
        ),
      ),
    ),
  );
}
