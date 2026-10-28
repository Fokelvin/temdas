import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/app_routes.dart';
import '../data/supabase_session.dart';
import 'totp_enrollment_qr.dart';
import 'totp_factor_selection.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session, this.currentUri});
  final SupabaseSession? session;
  final Uri? currentUri;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _recovering = false;
  bool _recoveryLoading = false;
  bool _recoverySent = false;
  bool _recoveryCooldown = false;
  Timer? _recoveryTimer;
  String? _error;

  @override
  void dispose() {
    _recoveryTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;
    final session = widget.session;
    if (session == null) {
      setState(() => _error = 'A autenticação ainda não está configurada.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await session.signInWithPassword(
        _email.text.trim(),
        _password.text,
      );
      _password.clear();
      if (response.session == null) {
        throw const AuthException('O login não criou uma sessão.');
      }
    } on AuthException catch (error) {
      setState(() => _error = _loginError(error));
    } catch (_) {
      setState(
        () => _error =
            'Não foi possível entrar. Verifique sua conexão e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRecovery(bool recovering) {
    if (_recoveryLoading) return;
    setState(() {
      _recovering = recovering;
      _error = null;
    });
  }

  Future<void> _sendRecovery() async {
    if (_recoveryLoading || _recoveryCooldown) return;
    final email = _email.text.trim();
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = 'Informe um e-mail válido.');
      return;
    }
    final session = widget.session;
    if (session == null) {
      setState(() => _error = 'A autenticação ainda não está configurada.');
      return;
    }
    final location = widget.currentUri ?? Uri.base;
    if ((location.scheme != 'https' && location.scheme != 'http') ||
        location.host.isEmpty) {
      setState(
        () => _error = 'Não foi possível identificar o endereço do app.',
      );
      return;
    }

    setState(() {
      _recoveryLoading = true;
      _recoverySent = false;
      _error = null;
    });
    try {
      await session.client.auth.resetPasswordForEmail(
        email,
        redirectTo: '${location.origin}${AppRoutes.authCallback}',
      );
      if (mounted) _showRecoverySent();
    } on AuthException catch (error) {
      if (!mounted) return;
      final message = _recoveryError(error);
      if (message == null) {
        _showRecoverySent();
      } else {
        setState(() => _error = message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = _recoveryUnavailable);
    } finally {
      if (mounted) setState(() => _recoveryLoading = false);
    }
  }

  void _showRecoverySent() {
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer(const Duration(minutes: 1), () {
      if (mounted) setState(() => _recoveryCooldown = false);
    });
    setState(() {
      _recoverySent = true;
      _recoveryCooldown = true;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => _recovering
      ? _AuthLayout(
          title: 'Esqueci minha senha',
          subtitle:
              'Informe seu e-mail para receber instruções de recuperação.',
          children: [
            if (!_recoverySent || !_recoveryCooldown) ...[
              TextField(
                controller: _email,
                enabled: !_recoveryLoading,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'E-mail'),
                onSubmitted: (_) => _sendRecovery(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _recoveryLoading ? null : _sendRecovery,
                  child: _recoveryLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar instruções'),
                ),
              ),
            ],
            if (_recoverySent) ...[
              const SizedBox(height: 12),
              const Text(_recoveryConfirmation),
              if (_recoveryCooldown)
                const Text('Aguarde um minuto antes de solicitar novamente.'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: _recoveryLoading ? null : () => _showRecovery(false),
              child: const Text('Voltar ao login'),
            ),
          ],
        )
      : _AuthLayout(
          title: 'Entrar no TEMDAS',
          subtitle: 'Use sua conta para continuar.',
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Senha'),
              onSubmitted: (_) => _login(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Entrar'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => _showRecovery(true),
              child: const Text('Esqueci minha senha'),
            ),
          ],
        );
}

const _recoveryConfirmation =
    'Se houver uma conta para este e-mail, você receberá instruções para redefinir sua senha.';
const _recoveryUnavailable =
    'Não foi possível solicitar a recuperação. Verifique a conexão e tente novamente.';
const _recoveryRejected =
    'A solicitação de recuperação foi recusada. Tente novamente ou contate o suporte.';
const _recoveryUnauthorized =
    'A recuperação não está disponível nesta configuração. Contate o suporte.';
const _recoveryRateLimited =
    'Limite de tentativas atingido. Aguarde antes de solicitar novamente.';

/// Returns null only when a generic confirmation protects account existence.
String? _recoveryError(AuthException error) {
  if (error is AuthRetryableFetchException || error is AuthUnknownException) {
    return _recoveryUnavailable;
  }
  final status = int.tryParse(error.statusCode ?? '');
  if (status != null && status >= 500) return _recoveryUnavailable;
  if (status == 429) return _recoveryRateLimited;
  if (status == 401 || status == 403) return _recoveryUnauthorized;
  switch (error.code) {
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return _recoveryRateLimited;
    case 'request_timeout':
    case 'hook_timeout':
    case 'hook_timeout_after_retry':
    case 'unexpected_failure':
      return _recoveryUnavailable;
  }
  if (error.code == 'user_not_found' || error.code == 'email_not_confirmed') {
    return null;
  }
  if (status == 400) return _recoveryRejected;
  if (status == 404) return null;
  return _recoveryUnavailable;
}

String _loginError(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('invalid login credentials')) {
    return 'E-mail ou senha incorretos.';
  }
  if (message.contains('email not confirmed')) {
    return 'Confirme seu e-mail antes de entrar.';
  }
  return 'Não foi possível entrar. Confira seus dados e tente novamente.';
}

class MfaEnrollPage extends StatefulWidget {
  const MfaEnrollPage({
    super.key,
    required this.session,
    required this.factors,
    required this.onSignOut,
  });
  final SupabaseSession session;
  final List<Factor> factors;
  final Future<void> Function() onSignOut;
  @override
  State<MfaEnrollPage> createState() => _MfaEnrollPageState();
}

class _MfaEnrollPageState extends State<MfaEnrollPage> {
  TOTPEnrollment? _enrollment;
  String? _factorId;
  String? _challengeId;
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;
  bool get _hasPending => hasUnverifiedTotpFactor(widget.factors);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = _mfaError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enroll() async {
    final pending = preferredTotpFactor(widget.factors);
    if (pending?.status == FactorStatus.unverified) {
      setState(() => _factorId = pending!.id);
      return;
    }
    final response = await widget.session.client.auth.mfa.enroll(
      factorType: FactorType.totp,
      friendlyName: 'TEMDAS',
    );
    if (response.totp == null) {
      throw StateError('Supabase não retornou os dados do autenticador.');
    }
    setState(() {
      _enrollment = response.totp;
      _factorId = response.id;
      _challengeId = null;
    });
  }

  Future<void> _restart() async {
    final pending = widget.factors
        .where(
          (factor) =>
              factor.factorType == FactorType.totp &&
              factor.status == FactorStatus.unverified,
        )
        .toList();
    if (pending.isEmpty) {
      throw StateError('Não há cadastro pendente para reiniciar.');
    }
    for (final factor in pending) {
      await widget.session.client.auth.mfa.unenroll(factor.id);
    }
    setState(() {
      _enrollment = null;
      _factorId = null;
      _challengeId = null;
    });
    await _createEnrollment();
  }

  Future<void> _createEnrollment() async {
    final response = await widget.session.client.auth.mfa.enroll(
      factorType: FactorType.totp,
      friendlyName: 'TEMDAS',
    );
    if (response.totp == null) {
      throw StateError('Supabase não retornou os dados do autenticador.');
    }
    setState(() {
      _enrollment = response.totp;
      _factorId = response.id;
      _challengeId = null;
    });
  }

  Future<void> _challenge() async {
    final factorId = _factorId ?? preferredTotpFactor(widget.factors)?.id;
    if (factorId == null) {
      throw StateError('Cadastre ou selecione um fator TOTP.');
    }
    final result = await widget.session.client.auth.mfa.challenge(
      factorId: factorId,
    );
    setState(() {
      _factorId = factorId;
      _challengeId = result.id;
    });
  }

  Future<void> _verify() async {
    final factorId = _factorId;
    final challengeId = _challengeId;
    if (factorId == null || challengeId == null) {
      throw StateError('Inicie o challenge antes de verificar.');
    }
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const FormatException('Informe o código de 6 dígitos.');
    }
    await widget.session.client.auth.mfa.verify(
      factorId: factorId,
      challengeId: challengeId,
      code: code,
    );
    _code.clear();
  }

  @override
  Widget build(BuildContext context) => _AuthLayout(
    title: 'Configure a verificação em duas etapas',
    subtitle: _hasPending
        ? 'Há um cadastro TOTP pendente. Continue com o fator existente.'
        : 'Cadastre um autenticador para proteger sua conta.',
    children: [
      if (_hasPending)
        const ListTile(
          leading: Icon(Icons.pending_outlined),
          title: Text('Cadastro TOTP pendente'),
          subtitle: Text('O fator existente será reutilizado.'),
        ),
      if (_enrollment == null && !_hasPending)
        FilledButton.tonal(
          onPressed: _loading ? null : () => _run(_enroll),
          child: const Text('Cadastrar TOTP'),
        ),
      if (_hasPending && _enrollment == null)
        OutlinedButton(
          onPressed: _loading ? null : () => _run(_restart),
          child: const Text('Reiniciar cadastro TOTP'),
        ),
      if (_enrollment case final enrollment?) ...[
        TotpEnrollmentQr(uri: enrollment.uri, secret: enrollment.secret),
      ],
      if (_enrollment != null || _hasPending) ...[
        FilledButton.tonal(
          onPressed: _loading ? null : () => _run(_challenge),
          child: const Text('Iniciar challenge'),
        ),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: const InputDecoration(labelText: 'Código TOTP'),
          onSubmitted: (_) => _run(_verify),
        ),
        FilledButton(
          onPressed: _loading || _challengeId == null
              ? null
              : () => _run(_verify),
          child: const Text('Verificar'),
        ),
      ],
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (_loading) const LinearProgressIndicator(),
      TextButton(
        onPressed: _loading ? null : widget.onSignOut,
        child: const Text('Sair'),
      ),
    ],
  );
}

class MfaChallengePage extends StatefulWidget {
  const MfaChallengePage({
    super.key,
    required this.session,
    required this.factors,
    required this.onSignOut,
  });
  final SupabaseSession session;
  final List<Factor> factors;
  final Future<void> Function() onSignOut;
  @override
  State<MfaChallengePage> createState() => _MfaChallengePageState();
}

class _MfaChallengePageState extends State<MfaChallengePage> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = _challengeError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const _InvalidTotpCode();
    }

    final factor = preferredTotpFactor(widget.factors);
    if (factor == null || factor.status != FactorStatus.verified) {
      throw StateError('Não há fator TOTP verificado.');
    }

    await widget.session.verifyTotp(factorId: factor.id, code: code);
    _code.clear();
  }

  @override
  Widget build(BuildContext context) => _AuthLayout(
    title: 'Confirme sua identidade',
    subtitle: 'Informe o código gerado pelo seu aplicativo autenticador.',
    children: [
      TextField(
        controller: _code,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
        onSubmitted: (_) => _run(_confirm),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _loading ? null : () => _run(_confirm),
        child: const Text('Confirmar'),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (_loading)
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: LinearProgressIndicator(),
        ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: _loading ? null : widget.onSignOut,
        child: const Text('Sair'),
      ),
    ],
  );
}

String _challengeError(Object error) {
  if (error is _InvalidTotpCode) {
    return 'Informe um código válido de 6 dígitos.';
  }
  if (error is AuthException && error.code == 'mfa_verification_failed') {
    return 'Código inválido. Confira o aplicativo autenticador e tente novamente.';
  }
  return 'Não foi possível confirmar sua identidade. Tente novamente.';
}

class _InvalidTotpCode implements Exception {
  const _InvalidTotpCode();
}

String _mfaError(Object error) {
  if (error is FormatException) return error.message;
  if (error is AuthException) return error.message;
  return 'Não foi possível concluir a verificação. Tente novamente.';
}

class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(subtitle),
                    const SizedBox(height: 24),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
