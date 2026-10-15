import 'dart:async';

import 'package:flutter/material.dart';
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
  });

  final Uri uri;
  final SupabaseSession? session;
  final CallbackStorage? storage;

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  CallbackResult? _result;
  String? _error;
  bool _submitting = false;
  bool _passwordUpdated = false;
  bool _showPassword = false;
  bool _showConfirmation = false;

  SupabaseSession? get _session => widget.session ?? supabaseSession;
  CallbackStorage get _storage => widget.storage ?? browserCallbackStorage;
  AuthCallbackProcessor get _processor =>
      AuthCallbackProcessor(_session, storage: _storage);

  @override
  void initState() {
    super.initState();
    unawaited(_process());
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    // Keep the original URI in memory for the SDK, but remove credentials and
    // one-time codes from the browser address bar and history immediately.
    _storage.clearUrl();
    final result = await _processor.process(widget.uri);
    if (mounted) setState(() => _result = result);
  }

  void _expire(CallbackFlow? flow) {
    _processor.clear();
    _password.clear();
    _confirmation.clear();
    setState(() => _result = CallbackResult(CallbackStatus.expired, flow));
  }

  Future<void> _submit() async {
    final result = _result;
    if (_submitting ||
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
        final status = await _processor.verifyActiveSession(result!.userId!);
        if (!mounted) return;
        if (status == CallbackStatus.expired) {
          _expire(result.flow);
          return;
        }
        if (status != CallbackStatus.valid) {
          setState(
            () => _error =
                'Não foi possível verificar sua sessão. Tente novamente.',
          );
          return;
        }
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
      if (_expiredSessionError(error)) {
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
    final invite = result?.flow == CallbackFlow.invite;
    final title = switch (result?.status) {
      null => 'Validando link…',
      CallbackStatus.valid when invite => 'Definir senha',
      CallbackStatus.valid => 'Redefinir senha',
      CallbackStatus.expired => 'Link ou sessão expirados',
      CallbackStatus.invalid => 'Link inválido',
      CallbackStatus.unavailable => 'Não foi possível validar o link',
    };
    final description = switch (result?.status) {
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
                      if (result == null) ...[
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(description),
                      if (valid) ...[
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
      error.statusCode == '401' ||
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
