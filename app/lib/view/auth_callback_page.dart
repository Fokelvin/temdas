import 'dart:async';

import 'package:flutter/material.dart';

import 'widgets/theme_toggle_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/app_routes.dart';
import '../data/auth_callback.dart';
import '../data/auth_callback_storage.dart';
import '../data/supabase_session.dart';

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({
    super.key,
    required this.uri,
    this.session,
    this.storage,
  }) : requireConfirmation = false;

  const AuthCallbackPage.confirm({
    super.key,
    required this.uri,
    this.session,
    this.storage,
  }) : requireConfirmation = true;

  final Uri uri;
  final SupabaseSession? session;
  final CallbackStorage? storage;
  final bool requireConfirmation;

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  final _totp = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  CallbackResult? _result;
  String? _error;
  bool _submitting = false;
  bool _passwordUpdated = false;
  bool _passwordAccessReady = false;
  bool _checkingAccess = false;
  bool _requireAal2 = false;
  Factor? _totpFactor;
  bool _showPassword = false;
  bool _showConfirmation = false;
  AuthConfirmationIntent? _pendingConfirmation;

  SupabaseSession? get _session => widget.session ?? supabaseSession;
  CallbackStorage get _storage => widget.storage ?? browserCallbackStorage;
  AuthCallbackProcessor get _processor =>
      AuthCallbackProcessor(_session, storage: _storage);

  @override
  void initState() {
    super.initState();
    if (widget.requireConfirmation) {
      _storage.clearUrl();
      _processor.clear();
      _pendingConfirmation = AuthConfirmationIntent.parse(widget.uri);
      if (_pendingConfirmation == null) {
        _result = const CallbackResult(CallbackStatus.invalid);
      }
    } else {
      unawaited(_process());
    }
  }

  @override
  void dispose() {
    _totp.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    // Keep the original URI in memory for the SDK, but remove credentials and
    // one-time codes from the browser address bar and history immediately.
    _storage.clearUrl();
    final result = await _processor.process(widget.uri);

    await _acceptResult(result);
  }

  Future<void> _confirm() async {
    final intent = _pendingConfirmation;
    if (_submitting || intent == null) return;
    setState(() {
      _submitting = true;
      _pendingConfirmation = null;
    });
    CallbackResult result;
    try {
      result = await intent.confirm(_processor);
    } catch (_) {
      result = const CallbackResult(CallbackStatus.unavailable);
    }

    await _acceptResult(result);
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _acceptResult(CallbackResult result) async {
    if (!mounted) return;
    setState(() => _result = result);
    if (result.status != CallbackStatus.valid) return;
    await _preparePasswordAccess();
  }

  Future<bool> _checkPasswordAccess() async {
    final expected = _result?.userId;
    final session = _session;
    if (expected == null || session?.currentSession?.user.id != expected) {
      _expire(_result?.flow);
      return false;
    }
    final user = (await session!.client.auth.getUser()).user;
    if (!mounted) return false;
    if (user?.id != expected || session.currentSession?.user.id != expected) {
      _expire(_result?.flow);
      return false;
    }
    // Read factors from Auth, not just a potentially stale local user snapshot.
    // Once MFA is known to be required it remains required for this callback.
    final verified = [
      ...?user?.factors,
      ...?session.currentSession?.user.factors,
    ].where((factor) => factor.status == FactorStatus.verified).toList();
    _requireAal2 = _requireAal2 || verified.isNotEmpty;
    _totpFactor = verified
        .where((f) => f.factorType == FactorType.totp)
        .firstOrNull;
    final allowed =
        !_requireAal2 ||
        session.client.auth.mfa.getAuthenticatorAssuranceLevel().currentLevel ==
            AuthenticatorAssuranceLevels.aal2;
    setState(() {
      _passwordAccessReady = allowed;
      if (!allowed) {
        _password.clear();
        _confirmation.clear();
      }
    });

    return allowed;
  }

  Future<void> _preparePasswordAccess() async {
    if (_checkingAccess || !mounted) return;
    setState(() {
      _checkingAccess = true;
      _passwordAccessReady = false;
      _error = null;
    });
    try {
      await _checkPasswordAccess();
    } on AuthException catch (error) {
      if (mounted) {
        if (_expiredSessionError(error)) {
          _expire(_result?.flow);
        } else {
          setState(
            () => _error =
                'Não foi possível verificar sua sessão. Tente novamente.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível verificar sua sessão. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _checkingAccess = false);
    }
  }

  Future<void> _confirmTotp() async {
    if (_submitting ||
        _checkingAccess ||
        _result?.status != CallbackStatus.valid) {
      return;
    }
    final code = _totp.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Informe um código válido de 6 dígitos.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (await _checkPasswordAccess()) return;
      if (_result?.status != CallbackStatus.valid) return;
      final factor = _totpFactor;
      if (factor == null) {
        setState(
          () => _error =
              'Não há fator TOTP disponível para confirmar esta sessão.',
        );
        return;
      }
      await _session!.verifyTotp(factorId: factor.id, code: code);
      if (!mounted) return;
      _totp.clear();
      if (!await _checkPasswordAccess() &&
          _result?.status == CallbackStatus.valid) {
        setState(
          () => _error =
              'Não foi possível elevar a sessão para AAL2. Tente novamente.',
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      if (_expiredSessionError(error)) {
        _expire(_result?.flow);
      } else {
        setState(
          () => _error = switch (error.code) {
            'mfa_verification_failed' =>
              'Código inválido. Confira o aplicativo autenticador e tente novamente.',
            'mfa_challenge_expired' || 'mfa_challenge_not_found' =>
              'Confirmação expirada. Tente novamente com um novo código.',
            _ => 'Não foi possível confirmar sua identidade. Tente novamente.',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível confirmar sua identidade. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        _totp.clear();
        setState(() => _submitting = false);
      }
    }
  }

  void _expire(CallbackFlow? flow) {
    _processor.clear();
    _totp.clear();
    _passwordAccessReady = false;
    _password.clear();
    _confirmation.clear();
    setState(() => _result = CallbackResult(CallbackStatus.expired, flow));
  }

  Future<void> _submit() async {
    final result = _result;
    if (_submitting ||
        _checkingAccess ||
        (!_passwordUpdated && !_passwordAccessReady) ||
        result?.status != CallbackStatus.valid ||
        result?.userId == null) {
      return;
    }
    if (!_passwordUpdated) {
      final password = _password.text;
      if (password.trim().isEmpty) {
        setState(() => _error = 'Informe uma senha.');
        return;
      }
      if (password.length < 8) {
        setState(() => _error = 'Use pelo menos 8 caracteres.');
        return;
      }
      if (password != _confirmation.text) {
        setState(() => _error = 'As senhas não coincidem.');
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = _session;
      if (session == null) {
        setState(() => _error = 'A autenticação não está configurada.');
        return;
      }
      if (!_passwordUpdated) {
        final newPassword = _password.text;
        if (!await _checkPasswordAccess()) return;
        if (!mounted) return;
        await session.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        _passwordUpdated = true;
        _processor.clear();
        if (mounted) {
          _password.clear();
          _confirmation.clear();
        }
      }

      try {
        await session.signOut();
      } catch (_) {
        // GoTrue clears the local session before attempting remote sign-out.
        if (session.currentSession != null) {
          if (mounted) {
            setState(
              () => _error =
                  'Senha salva, mas não foi possível encerrar a sessão. Tente novamente.',
            );
          }
          return;
        }
      }
      if (!mounted) return;
      _storage.leaveCallback();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.demandas,
        (_) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.code == 'insufficient_aal') {
        _requireAal2 = true;
        await _preparePasswordAccess();
        if (mounted && _result?.status == CallbackStatus.valid) {
          setState(() => _error = 'Confirme o MFA antes de salvar a senha.');
        }
      } else if (_expiredSessionError(error)) {
        _expire(result?.flow);
      } else {
        setState(() => _error = _passwordError(error));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível salvar a senha. Verifique a conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _goToLogin() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await _session?.signOut();
    } catch (_) {
      if (_session?.currentSession != null) {
        if (mounted) {
          setState(() {
            _submitting = false;
            _error = 'Não foi possível encerrar a sessão. Tente novamente.';
          });
        }
        return;
      }
    }
    if (!mounted) return;
    _storage.leaveCallback();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.demandas,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final valid = result?.status == CallbackStatus.valid;
    final needsMfa =
        valid && !_checkingAccess && !_passwordAccessReady && _requireAal2;
    final pending = _pendingConfirmation;
    final invite = (pending?.flow ?? result?.flow) == CallbackFlow.invite;
    final title = _checkingAccess
        ? 'Verificando segurança da sessão…'
        : needsMfa
        ? 'Confirme o MFA para definir a senha'
        : pending != null
        ? (invite ? 'Confirmar convite' : 'Confirmar recuperação de senha')
        : switch (result?.status) {
            null => 'Validando link…',
            CallbackStatus.valid when invite => 'Definir senha',
            CallbackStatus.valid => 'Redefinir senha',
            CallbackStatus.expired => 'Link ou sessão expirados',
            CallbackStatus.invalid => 'Link inválido',
            CallbackStatus.unavailable => 'Não foi possível validar o link',
          };
    final description = needsMfa
        ? 'Informe o código do seu aplicativo autenticador para continuar.'
        : pending != null
        ? (invite
              ? 'Confirme que deseja aceitar este convite e definir sua senha.'
              : 'Confirme que deseja continuar e escolher uma nova senha.')
        : switch (result?.status) {
            null => 'Aguarde enquanto verificamos o link com o Supabase.',
            CallbackStatus.valid when invite =>
              'Crie uma senha para concluir o acesso pelo convite.',
            CallbackStatus.valid => 'Crie uma nova senha para sua conta.',
            CallbackStatus.expired =>
              'Solicite um novo link e abra o mais recente recebido por e-mail.',
            CallbackStatus.invalid =>
              'Confira se o link está completo ou solicite um novo link.',
            CallbackStatus.unavailable =>
              'Verifique a conexão e abra novamente o link recebido por e-mail.',
          };
    return Scaffold(
      appBar: const ThemeToolbar(),
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
                      if (result == null && pending == null) ...[
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(description),
                      if (pending != null) ...[
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _submitting ? null : _confirm,
                          child: Text(
                            invite
                                ? 'Aceitar convite'
                                : 'Continuar recuperação',
                          ),
                        ),
                      ],
                      if (valid &&
                          !_passwordAccessReady &&
                          !_passwordUpdated) ...[
                        const SizedBox(height: 24),
                        if (_checkingAccess)
                          const Center(child: CircularProgressIndicator())
                        else if (needsMfa && _totpFactor != null) ...[
                          TextField(
                            controller: _totp,
                            enabled: !_submitting,
                            keyboardType: TextInputType.number,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            decoration: const InputDecoration(
                              labelText: 'Código de 6 dígitos',
                            ),
                            onSubmitted: (_) => _confirmTotp(),
                          ),
                          FilledButton(
                            onPressed: _submitting ? null : _confirmTotp,
                            child: const Text('Confirmar MFA'),
                          ),
                        ] else
                          FilledButton(
                            onPressed: _submitting
                                ? null
                                : _preparePasswordAccess,
                            child: const Text('Verificar sessão novamente'),
                          ),
                        if (_error != null)
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ] else if (valid) ...[
                        const SizedBox(height: 24),
                        if (!_passwordUpdated) ...[
                          TextField(
                            controller: _password,
                            enabled: !_submitting,
                            obscureText: !_showPassword,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              helperText: 'Pelo menos 8 caracteres',
                              suffixIcon: IconButton(
                                tooltip: _showPassword
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                onPressed: _submitting
                                    ? null
                                    : () => setState(
                                        () => _showPassword = !_showPassword,
                                      ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmation,
                            enabled: !_submitting,
                            obscureText: !_showConfirmation,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Confirmar senha',
                              suffixIcon: IconButton(
                                tooltip: _showConfirmation
                                    ? 'Ocultar confirmação'
                                    : 'Mostrar confirmação',
                                onPressed: _submitting
                                    ? null
                                    : () => setState(
                                        () => _showConfirmation =
                                            !_showConfirmation,
                                      ),
                                icon: Icon(
                                  _showConfirmation
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                        ] else
                          const Text('Senha salva. Encerrando a sessão…'),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _passwordUpdated
                                      ? 'Tentar encerrar sessão'
                                      : 'Salvar senha',
                                ),
                        ),
                      ] else if (result != null) ...[
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _submitting ? null : _goToLogin,
                          child: const Text('Voltar ao login'),
                        ),
                      ],
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
}

bool _expiredSessionError(AuthException error) {
  final code = error.code?.toLowerCase();
  return error is AuthSessionMissingException ||
      code == 'session_not_found' ||
      code == 'jwt_expired' ||
      code == 'bad_jwt';
}

String _passwordError(AuthException error) => switch (error.code) {
  'weak_password' =>
    'A senha não atende aos requisitos de segurança. Escolha outra.',
  'same_password' => 'Escolha uma senha diferente da anterior.',
  'reauthentication_needed' => 'Solicite um novo link para alterar a senha.',
  _ => 'Não foi possível salvar a senha. Tente novamente.',
};
