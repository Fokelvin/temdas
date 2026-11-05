import 'dart:async';

import 'package:flutter/material.dart';

import 'widgets/theme_toggle_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/app_routes.dart';
import '../data/supabase_session.dart';
import 'totp_enrollment_qr.dart';

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
  final _passwordFocus = FocusNode();
  bool _passwordVisible = false;
  bool _loading = false;
  bool _recovering = false;
  bool _activationRecovery = false;
  late final _recovery = PasswordRecoveryController(
    session: widget.session,
    currentUri: widget.currentUri,
  );
  String? _error;

  @override
  void dispose() {
    _recovery.dispose();
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
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
      if (!mounted) return;
      _password.clear();
      if (response.session == null) {
        throw const AuthException('O login não criou uma sessão.');
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = _loginError(error));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Não foi possível entrar. Verifique sua conexão e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRecovery(bool recovering, {bool activation = false}) {
    if (_recovery.loading) return;
    if (recovering && !_recovery.cooldown) _recovery.email.text = _email.text;
    setState(() {
      _recovering = recovering;
      _activationRecovery = activation;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => _recovering
      ? _AuthLayout(
          title: _activationRecovery
              ? 'Continue a ativação da conta'
              : 'Esqueci minha senha',
          subtitle:
              'Informe seu e-mail para receber instruções de recuperação.',
          children: [
            PasswordRecoveryForm(
              controller: _recovery,
              activation: _activationRecovery,
              onBack: () => _showRecovery(false),
            ),
          ],
        )
      : _AuthLayout(
          title: 'Entrar no TEMDAS',
          subtitle: 'Use sua conta para continuar.',
          children: [
            TextField(
              controller: _email,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              enabled: !_loading,
              focusNode: _passwordFocus,
              obscureText: !_passwordVisible,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  tooltip: _passwordVisible ? 'Ocultar senha' : 'Mostrar senha',
                  isSelected: _passwordVisible,
                  onPressed: () {
                    setState(() => _passwordVisible = !_passwordVisible);
                    _passwordFocus.requestFocus();
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  selectedIcon: const Icon(Icons.visibility_off_outlined),
                ),
              ),
              onSubmitted: (_) => _login(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              AuthFeedback(message: _error!, error: true),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const AuthProgress(label: 'Entrando…')
                    : const Text('Entrar'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => _showRecovery(true),
              child: const Text('Esqueci minha senha'),
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => _showRecovery(true, activation: true),
              child: const Text('Problemas para ativar sua conta?'),
            ),
          ],
        );
}

/// Shared recovery request, validation and cooldown for login and activation.
class PasswordRecoveryController extends ChangeNotifier {
  PasswordRecoveryController({required this.session, this.currentUri});
  final SupabaseSession? session;
  final Uri? currentUri;
  final email = TextEditingController();
  bool loading = false;
  bool sent = false;
  bool cooldown = false;
  String? error;
  Timer? _timer;
  bool _disposed = false;

  void _update(VoidCallback update) {
    if (_disposed) return;
    update();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    email.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (loading || cooldown) return;
    final address = email.text.trim();
    if (address.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      _update(() => error = 'Informe um e-mail válido.');
      return;
    }
    final auth = session;
    if (auth == null) {
      _update(() => error = 'A autenticação ainda não está configurada.');
      return;
    }
    final location = currentUri ?? Uri.base;
    if ((location.scheme != 'https' && location.scheme != 'http') ||
        location.host.isEmpty) {
      _update(() => error = 'Não foi possível identificar o endereço do app.');
      return;
    }

    _update(() {
      loading = true;
      sent = false;
      error = null;
    });
    try {
      await auth.client.auth.resetPasswordForEmail(
        address,
        redirectTo: '${location.origin}${AppRoutes.authCallback}',
      );
      if (!_disposed) _showRecoverySent();
    } on AuthException catch (failure) {
      if (_disposed) return;
      final message = _recoveryError(failure);
      if (message == null) {
        _showRecoverySent();
      } else {
        _update(() => error = message);
        if (message == _recoveryRateLimited) _startCooldown();
      }
    } catch (_) {
      if (!_disposed) _update(() => error = _recoveryUnavailable);
    } finally {
      if (!_disposed) _update(() => loading = false);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    _timer = Timer(
      const Duration(minutes: 1),
      () => _update(() => cooldown = false),
    );
    _update(() => cooldown = true);
  }

  void _showRecoverySent() {
    _startCooldown();
    _update(() {
      sent = true;
      cooldown = true;
      error = null;
    });
  }
}

class PasswordRecoveryForm extends StatelessWidget {
  const PasswordRecoveryForm({
    super.key,
    required this.controller,
    required this.onBack,
    this.activation = false,
    this.busy = false,
  });
  final PasswordRecoveryController controller;
  final VoidCallback onBack;
  final bool activation;
  final bool busy;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (activation) ...[
          const Text(
            'Se você já aceitou seu convite, pode continuar a configuração da conta solicitando um link de recuperação de senha por e-mail.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Se o convite nunca foi aceito ou a recuperação não for aplicável, procure o administrador para obter um novo convite.',
          ),
          const SizedBox(height: 20),
        ],
        if (!controller.sent || !controller.cooldown) ...[
          TextField(
            controller: controller.email,
            enabled: !controller.loading && !busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'E-mail'),
            onSubmitted: (_) => controller.send(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: controller.loading || controller.cooldown || busy
                ? null
                : controller.send,
            child: controller.loading
                ? const AuthProgress(label: 'Enviando instruções…')
                : Text(
                    activation
                        ? 'Enviar link para continuar'
                        : 'Enviar instruções',
                  ),
          ),
        ],
        if (controller.sent) ...[
          const SizedBox(height: 12),
          const AuthFeedback(message: _recoveryConfirmation),
        ],
        if (controller.cooldown)
          const Text('Aguarde um minuto antes de solicitar novamente.'),
        if (controller.error != null) ...[
          const SizedBox(height: 12),
          AuthFeedback(message: controller.error!, error: true),
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: controller.loading || busy ? null : onBack,
          child: const Text('Voltar ao login'),
        ),
      ],
    ),
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
  if (error.statusCode == '429' || error.code == 'over_request_rate_limit') {
    return 'Limite de tentativas atingido. Aguarde e tente novamente.';
  }
  if (error is AuthRetryableFetchException ||
      (int.tryParse(error.statusCode ?? '') ?? 0) >= 500) {
    return 'Não foi possível entrar. Verifique sua conexão e tente novamente.';
  }
  // The same response covers unknown accounts, wrong passwords and accounts
  // that cannot sign in yet. Never display the provider's account details.
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
  late List<Factor> _factors = List.of(widget.factors);
  final _code = TextEditingController();
  bool _loading = false;
  bool _completed = false;
  bool _creationUncertain = false;
  String? _error;
  String? get _pendingId =>
      _factorId ??
      _factors
          .where(
            (f) =>
                f.factorType == FactorType.totp &&
                f.status == FactorStatus.unverified,
          )
          .firstOrNull
          ?.id;
  bool get _hasPending => _pendingId != null;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading || _completed) return;
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

  Future<void> _refreshFactors() async {
    final response = await widget.session.client.auth.mfa.listFactors();
    if (!mounted) return;
    setState(() => _factors = List.of(response.all));
    if (_factors.any(
      (f) =>
          f.factorType == FactorType.totp && f.status == FactorStatus.verified,
    )) {
      throw const _ExistingAuthenticator();
    }
  }

  Future<void> _enroll() async {
    // A lost response may already have created a factor. Inspect before retrying.
    if (_creationUncertain) await _refreshFactors();
    if (!mounted || _hasPending) return;
    await _createEnrollment();
  }

  Future<void> _restart() async {
    // Re-read statuses before deletion; never remove a verified authenticator.
    await _refreshFactors();
    if (!mounted) return;
    final pending = _factors
        .where(
          (f) =>
              f.factorType == FactorType.totp &&
              f.status == FactorStatus.unverified,
        )
        .toList();
    for (final factor in pending) {
      await widget.session.client.auth.mfa.unenroll(factor.id);
      if (!mounted) return;
      setState(() {
        _factors.removeWhere((f) => f.id == factor.id);
        if (_factorId == factor.id) _factorId = null;
        _enrollment = null;
        _code.clear();
      });
    }
    if (!mounted) return;
    setState(() {
      _enrollment = null;
      _factorId = null;
      _code.clear();
    });
    await _createEnrollment();
  }

  Future<void> _createEnrollment() async {
    _creationUncertain = true;
    final AuthMFAEnrollResponse response;
    try {
      response = await widget.session.client.auth.mfa.enroll(
        factorType: FactorType.totp,
        friendlyName: 'TEMDAS',
      );
    } on AuthException catch (error) {
      if (error is! AuthRetryableFetchException &&
          error is! AuthUnknownException &&
          (int.tryParse(error.statusCode ?? '') ?? 500) < 500) {
        _creationUncertain = false;
      }
      rethrow;
    }
    if (!mounted) return;
    setState(() {
      _enrollment = response.totp;
      _factorId = response.id;
      _creationUncertain = false;
    });
  }

  Future<void> _verify() async {
    final factorId = _pendingId;
    final code = _code.text.trim();
    if (factorId == null || !RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const _InvalidTotpCode();
    }
    await widget.session.verifyTotp(factorId: factorId, code: code);
    if (!mounted) return;
    _code.clear();
    setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) => _AuthLayout(
    title: 'Configure a verificação em duas etapas',
    subtitle:
        'Abra um aplicativo autenticador, como Google Authenticator ou Microsoft Authenticator, e adicione uma conta usando o QR Code ou a chave manual.',
    children: [
      if (_completed)
        const AuthFeedback(
          message: 'Autenticador confirmado. Verificando acesso…',
        )
      else ...[
        if (!_hasPending)
          FilledButton.tonal(
            onPressed: _loading ? null : () => _run(_enroll),
            child: const Text('Configurar autenticador'),
          ),
        if (_hasPending && _enrollment == null) ...[
          const AuthFeedback(
            message:
                'Há uma configuração pendente. Se você já adicionou a conta ao aplicativo autenticador, informe o código. Se não tem mais o QR Code ou a chave, reinicie a configuração.',
          ),
        ],
        if (_hasPending)
          OutlinedButton(
            onPressed: _loading ? null : () => _run(_restart),
            child: const Text('Reiniciar configuração'),
          ),
        if (_enrollment case final enrollment?)
          TotpEnrollmentQr(uri: enrollment.uri, secret: enrollment.secret),
        if (_hasPending) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
            onSubmitted: (_) => _run(_verify),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : () => _run(_verify),
            child: const Text('Confirmar'),
          ),
        ],
      ],
      if (_error != null) AuthFeedback(message: _error!, error: true),
      if (_loading) const AuthProgress(label: 'Verificando identidade…'),
      TextButton(
        onPressed: _loading ? null : widget.onSignOut,
        child: const Text('Sair'),
      ),
    ],
  );
}

class _ExistingAuthenticator implements Exception {
  const _ExistingAuthenticator();
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
    if (_loading) return;
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

    final factor = widget.factors
        .where(
          (factor) =>
              factor.factorType == FactorType.totp &&
              factor.status == FactorStatus.verified,
        )
        .firstOrNull;
    if (factor == null || factor.status != FactorStatus.verified) {
      throw StateError('Não há fator TOTP verificado.');
    }

    await widget.session.verifyTotp(factorId: factor.id, code: code);
    if (mounted) _code.clear();
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
          child: AuthFeedback(message: _error!, error: true),
        ),
      if (_loading)
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: AuthProgress(label: 'Verificando identidade…'),
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
  if (error is _ExistingAuthenticator) {
    return 'Já existe um autenticador configurado. Saia e entre novamente para continuar.';
  }
  return _challengeError(error);
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
    appBar: const ThemeToolbar(),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
                ),
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

/// Accessible feedback shared by login, recovery and MFA.
class AuthFeedback extends StatelessWidget {
  const AuthFeedback({super.key, required this.message, this.error = false});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: error
          ? TextStyle(color: Theme.of(context).colorScheme.error)
          : null,
    ),
  );
}

class AuthProgress extends StatelessWidget {
  const AuthProgress({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Text(label),
      ],
    ),
  );
}
