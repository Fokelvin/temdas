import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../data/auth_provisioning.dart';
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
  const AuthGate({
    super.key,
    required this.child,
    this.session,
    this.provisioning,
  });
  final Widget child;
  final SupabaseSession? session;
  final AuthProvisioning? provisioning;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthGateState _state = AuthGateState.loading;
  List<Factor> _factors = const [];
  StreamSubscription<AuthState>? _subscription;
  bool _evaluating = false;
  bool _reevaluate = false;
  int _revision = 0;
  String? _lastSeenAccessToken;
  String? _error;

  SupabaseSession? get _session => widget.session ?? supabaseSession;
  AuthProvisioning get _provisioning => widget.provisioning ?? authProvisioning;

  @override
  void initState() {
    super.initState();
    final session = _session;
    _lastSeenAccessToken = session?.accessToken;
    if (session != null) {
      _subscription = session.authChanges.listen(_onAuthChange);
    }
    unawaited(_evaluate());
  }

  void _onAuthChange(AuthState change) {
    final token = _session?.accessToken;
    if (change.event == AuthChangeEvent.signedOut && token != null) return;
    if ((change.event == AuthChangeEvent.signedIn ||
            change.event == AuthChangeEvent.tokenRefreshed ||
            change.event == AuthChangeEvent.initialSession) &&
        change.session?.accessToken != token) {
      return;
    }
    if ((change.event == AuthChangeEvent.signedIn ||
            change.event == AuthChangeEvent.signedOut ||
            change.event == AuthChangeEvent.tokenRefreshed ||
            change.event == AuthChangeEvent.initialSession) &&
        token == _lastSeenAccessToken) {
      return;
    }
    _lastSeenAccessToken = token;
    _provisioning.observeAuthChange(_session, change);
    if (change.event == AuthChangeEvent.tokenRefreshed && _evaluating) return;
    _revision++;
    if (_evaluating) {
      _reevaluate = true;
      return;
    }
    if (_session?.currentSession != null) {
      _publish(AuthGateState.loading, const []);
    }
    unawaited(_evaluate());
  }

  @override
  void didUpdateWidget(covariant AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session == widget.session &&
        oldWidget.provisioning == widget.provisioning) {
      return;
    }
    _subscription?.cancel();
    (oldWidget.provisioning ?? authProvisioning).clearFor(
      oldWidget.session ?? supabaseSession,
    );
    _revision++;
    _lastSeenAccessToken = _session?.accessToken;
    _subscription = _session?.authChanges.listen(_onAuthChange);
    _publish(AuthGateState.loading, const []);
    unawaited(_evaluate());
  }

  bool _isCurrent(SupabaseSession session, String userId, int revision) =>
      mounted &&
      _revision == revision &&
      identical(_session, session) &&
      session.currentSession?.user.id == userId;

  Future<void> _evaluate() async {
    if (_evaluating) {
      _reevaluate = true;
      return;
    }
    _evaluating = true;
    try {
      do {
        _reevaluate = false;
        final session = _session;
        final revision = _revision;
        final current = session?.currentSession;
        if (session == null || current == null) {
          _provisioning.clearFor(session);
          _publish(AuthGateState.signedOut, const []);
          continue;
        }
        final userId = current.user.id;
        _publish(AuthGateState.loading, const []);
        try {
          if (current.isExpired) await session.client.auth.refreshSession();
          if (!_isCurrent(session, userId, revision)) {
            _reevaluate = true;
            continue;
          }

          final provisioned = await _provisioning.provisionFor(session, userId);
          if (!_isCurrent(session, userId, revision)) {
            _reevaluate = true;
            continue;
          }
          if (provisioned.usuarioId <= 0 ||
              (provisioned.aal != 'aal1' && provisioned.aal != 'aal2')) {
            throw StateError('Resposta de provisioning inválida.');
          }

          var aal = session.client.auth.mfa.getAuthenticatorAssuranceLevel();
          if (aal.currentLevel == AuthenticatorAssuranceLevels.aal2) {
            final token = session.accessToken;
            if (token == null) {
              _reevaluate = true;
              continue;
            }
            final confirmed = await _provisioning.confirmAal2For(
              session,
              userId,
              token,
            );
            if (!_isCurrent(session, userId, revision) ||
                session.accessToken != token ||
                session.client.auth.mfa
                        .getAuthenticatorAssuranceLevel()
                        .currentLevel !=
                    AuthenticatorAssuranceLevels.aal2) {
              _reevaluate = true;
              continue;
            }
            if (confirmed.usuarioId != provisioned.usuarioId ||
                confirmed.aal != 'aal2') {
              throw StateError('Usuário interno não confirmado.');
            }
            _publish(AuthGateState.authenticated, const []);
            continue;
          }

          // listFactors refreshes the token and includes pending factors in all.
          final factors = await session.client.auth.mfa.listFactors();
          if (!_isCurrent(session, userId, revision)) {
            _reevaluate = true;
            continue;
          }
          aal = session.client.auth.mfa.getAuthenticatorAssuranceLevel();
          if (aal.currentLevel == AuthenticatorAssuranceLevels.aal2) {
            _reevaluate = true;
            continue;
          }
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
          if (!_isCurrent(session, userId, revision)) {
            _reevaluate = true;
          } else {
            _error = _friendlyAuthError(error);
            _publish(AuthGateState.error, const []);
          }
        }
      } while (_reevaluate && mounted);
    } finally {
      _evaluating = false;
    }
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
  if (error is backend.AuthException) {
    return switch (error.codigo) {
      'emailNaoAutorizado' => 'Este e-mail não está autorizado para o TEMDAS.',
      'emailNaoConfirmado' => 'Confirme seu e-mail antes de continuar.',
      'conviteJaUtilizado' => 'Este convite já foi utilizado por outra conta.',
      'usuarioSupabaseNaoEncontrado' || 'emailInvalido' =>
        'Não foi possível confirmar sua conta. Solicite um novo convite.',
      'authIndisponivel' || 'jwksUnavailable' =>
        'O serviço de autenticação está indisponível. Tente novamente.',
      'authNaoConfigurado' ||
      'authNotConfigured' => 'A autenticação não está configurada.',
      'tokenMissing' ||
      'tokenInvalid' ||
      'tokenExpired' => 'Sua sessão expirou. Entre novamente.',
      _ => 'Não foi possível confirmar seu acesso. Tente novamente.',
    };
  }
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
