import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import '../data/auth_provisioning.dart';
import '../data/convites_gateway.dart';
import '../data/supabase_session.dart';
import '../theme/app_theme.dart';
import 'widgets/app_drawer.dart';

class MeuPerfilPage extends StatefulWidget {
  const MeuPerfilPage({
    super.key,
    this.session,
    this.provisioning,
    this.loadMe,
    this.convitesGateway,
  });

  final SupabaseSession? session;
  final AuthProvisioning? provisioning;
  final Future<backend.AuthMe> Function()? loadMe;
  final ConvitesGateway? convitesGateway;

  @override
  State<MeuPerfilPage> createState() => _MeuPerfilPageState();
}

class _MeuPerfilPageState extends State<MeuPerfilPage> {
  SupabaseSession? get _session => widget.session ?? supabaseSession;
  AuthProvisioning get _provisioning => widget.provisioning ?? authProvisioning;

  StreamSubscription<AuthState>? _subscription;
  backend.AuthMe? _me;
  bool _loading = true;
  bool _expired = false;
  String? _error;
  int _revision = 0;
  String? _activeToken;

  @override
  void initState() {
    super.initState();
    _subscription = _session?.authChanges.listen(_onAuthChange);
    unawaited(_load());
  }

  void _onAuthChange(AuthState change) {
    final session = _session;
    final current = session?.currentSession;
    if (current == null) {
      if (change.event == AuthChangeEvent.signedOut || session == null) {
        _showExpired();
      }
      return;
    }
    if (change.event == AuthChangeEvent.signedOut) return;
    if (change.session != null &&
        change.session!.accessToken != current.accessToken) {
      return;
    }
    if (_activeToken == current.accessToken) return;
    if (change.event == AuthChangeEvent.initialSession ||
        change.event == AuthChangeEvent.signedIn ||
        change.event == AuthChangeEvent.tokenRefreshed ||
        change.event == AuthChangeEvent.userUpdated) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final session = _session;
    final current = session?.currentSession;
    if (session == null || current == null) {
      _showExpired();
      return;
    }

    final revision = ++_revision;
    final userId = current.user.id;
    final token = current.accessToken;
    _activeToken = token;
    setState(() {
      _loading = true;
      _expired = false;
      _error = null;
    });

    try {
      final me = widget.loadMe != null
          ? await widget.loadMe!()
          : await _provisioning.confirmAal2For(session, userId, token);
      if (!_isCurrent(session, userId, token, revision)) return;
      if (me.usuarioId <= 0 || (me.aal != 'aal1' && me.aal != 'aal2')) {
        throw StateError('Resposta de auth.me inválida.');
      }
      setState(() {
        _me = me;
        _loading = false;
      });
    } catch (error) {
      if (!_isCurrent(session, userId, token, revision)) return;
      if (_isExpiredError(error, session)) {
        _showExpired();
      } else {
        setState(() {
          _loading = false;
          _error = 'Não foi possível carregar seu perfil. Tente novamente.';
        });
      }
    }
  }

  bool _isCurrent(
    SupabaseSession session,
    String userId,
    String token,
    int revision,
  ) {
    if (!mounted ||
        _revision != revision ||
        !identical(_session, session) ||
        session.currentSession?.user.id != userId) {
      return false;
    }
    if (session.accessToken != token) {
      unawaited(_load());
      return false;
    }
    return true;
  }

  bool _isExpiredError(Object error, SupabaseSession session) {
    if (session.currentSession == null || session.currentSession!.isExpired) {
      return true;
    }
    if (error is backend.AuthException) {
      return const {
        'tokenMissing',
        'tokenInvalid',
        'tokenExpired',
      }.contains(error.codigo);
    }
    final message = error.toString().toLowerCase();
    return message.contains('tokenmissing') ||
        message.contains('tokeninvalid') ||
        message.contains('tokenexpired') ||
        message.contains('unauthorized') ||
        message.contains('statuscode = 401');
  }

  void _showExpired() {
    if (!mounted) return;
    _revision++;
    setState(() {
      _me = null;
      _loading = false;
      _expired = true;
      _error = null;
    });
  }

  Future<void> _voltarAoLogin() async {
    await _session?.signOut();
    if (!mounted) return;
    if (_session?.currentSession == null) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.demandas, (_) => false);
    }
  }

  @override
  void dispose() {
    _revision++;
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Meu Perfil',
    route: AppRoutes.perfil,
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(
              key: ValueKey('perfil-carregando'),
            ),
          )
        : _expired
        ? _EstadoPerfil(
            icon: Icons.lock_clock_outlined,
            title: 'Sessão expirada',
            message: 'Entre novamente para consultar seu perfil.',
            actionLabel: 'Voltar ao login',
            onAction: _voltarAoLogin,
          )
        : _error != null
        ? _EstadoPerfil(
            icon: Icons.cloud_off_outlined,
            title: 'Não foi possível carregar o perfil',
            message: _error!,
            actionLabel: 'Tentar novamente',
            onAction: _load,
          )
        : _conteudo(),
  );

  Widget _conteudo() {
    final session = _session;
    final me = _me;
    if (session == null || me == null) {
      return _EstadoPerfil(
        icon: Icons.lock_clock_outlined,
        title: 'Sessão expirada',
        message: 'Entre novamente para consultar seu perfil.',
        actionLabel: 'Voltar ao login',
        onAction: _voltarAoLogin,
      );
    }

    final email = session.currentSession?.user.email;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth < 960
            ? constraints.maxWidth
            : 960.0;
        final contentWidth = (maxWidth - TemdasTokens.pagePadding * 2)
            .clamp(0.0, 960.0)
            .toDouble();
        final wide = contentWidth >= 700;
        final cardWidth = wide ? (contentWidth - 16) / 2 : contentWidth;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(TemdasTokens.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Informações da conta',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: TemdasTokens.contentGap),
                    Wrap(
                      spacing: TemdasTokens.contentGap,
                      runSpacing: TemdasTokens.contentGap,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _InfoCard(
                            icon: Icons.email_outlined,
                            label: 'E-mail',
                            value: email?.isNotEmpty == true
                                ? email!
                                : 'E-mail indisponível',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _InfoCard(
                            icon: Icons.verified_user_outlined,
                            label: 'Verificação em duas etapas',
                            value: me.aal == 'aal2'
                                ? 'Ativa (AAL2)'
                                : 'Não ativa (AAL1)',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _InfoCard(
                            icon: me.isAdmin
                                ? Icons.admin_panel_settings_outlined
                                : Icons.person_outline,
                            label: 'Tipo de conta',
                            value: me.isAdmin ? 'Administrador' : 'Usuário',
                          ),
                        ),
                      ],
                    ),
                    if (me.isAdmin) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Convites',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: TemdasTokens.contentGap),
                      _FormularioConvites(
                        gateway:
                            widget.convitesGateway ??
                            ConvitesGateway.serverpod(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(TemdasTokens.contentGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: TemdasTokens.contentGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: TemdasTokens.smallGap),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FormularioConvites extends StatefulWidget {
  const _FormularioConvites({required this.gateway});

  final ConvitesGateway gateway;

  @override
  State<_FormularioConvites> createState() => _FormularioConvitesState();
}

class _FormularioConvitesState extends State<_FormularioConvites> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _busy = false;
  String? _status;
  String? _feedback;
  bool _feedbackIsError = false;

  String get _email => _emailController.text.trim().toLowerCase();

  Future<void> _consultar() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    await _run(() async {
      final status = await widget.gateway.consultar(_email);
      if (!const {'ausente', 'pendente', 'provisionado'}.contains(status)) {
        throw StateError('Resposta de consulta inválida.');
      }
      _status = status;
      _feedback = null;
    });
  }

  Future<void> _enviar({required bool reenviar}) async {
    if (_busy || !_formKey.currentState!.validate()) return;
    if (reenviar && _status != 'pendente') return;
    if (!reenviar && _status != 'ausente') return;
    await _run(() async {
      final result = reenviar
          ? await widget.gateway.reenviar(_email)
          : await widget.gateway.convidar(_email);
      if (result != (reenviar ? 'reenviado' : 'enviado')) {
        throw StateError('Resposta de envio inválida.');
      }
      _status = 'pendente';
      _feedback = reenviar
          ? 'Convite reenviado com sucesso.'
          : 'Convite enviado com sucesso.';
      _feedbackIsError = false;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      await action();
    } catch (error) {
      _feedback = _mensagemErroConvite(error);
      _feedbackIsError = true;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onEmailChanged(String _) {
    if (_status == null && _feedback == null) return;
    setState(() {
      _status = null;
      _feedback = null;
      _feedbackIsError = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(TemdasTokens.contentGap),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('convite-email'),
              controller: _emailController,
              enabled: !_busy,
              onChanged: _onEmailChanged,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'E-mail do convite',
                hintText: 'pessoa@exemplo.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty ||
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return 'Informe um e-mail válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: TemdasTokens.contentGap),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const ValueKey('consultar-convite'),
                onPressed: _busy ? null : _consultar,
                icon: const Icon(Icons.search),
                label: const Text('Consultar convite'),
              ),
            ),
            if (_status != null) ...[
              const SizedBox(height: TemdasTokens.contentGap),
              _statusView(context),
              if (_status == 'ausente' || _status == 'pendente') ...[
                const SizedBox(height: TemdasTokens.contentGap),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    key: ValueKey(
                      _status == 'ausente'
                          ? 'enviar-convite'
                          : 'reenviar-convite',
                    ),
                    onPressed: _busy
                        ? null
                        : () => _enviar(reenviar: _status == 'pendente'),
                    icon: const Icon(Icons.send_outlined),
                    label: Text(
                      _status == 'ausente'
                          ? 'Enviar convite'
                          : 'Reenviar convite',
                    ),
                  ),
                ),
              ],
            ],
            if (_feedback != null) ...[
              const SizedBox(height: TemdasTokens.contentGap),
              Semantics(
                liveRegion: true,
                child: Text(
                  _feedback!,
                  key: const ValueKey('convite-feedback'),
                  style: TextStyle(
                    color: _feedbackIsError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: TemdasTokens.contentGap),
              const LinearProgressIndicator(key: ValueKey('convite-loading')),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _statusView(BuildContext context) {
    final (title, message) = switch (_status) {
      'ausente' => ('Novo convite', 'Este e-mail ainda não tem convite.'),
      'pendente' => (
        'Convite pendente',
        'A conta ainda não foi provisionada. O backend verificará se o reenvio está liberado.',
      ),
      'provisionado' => (
        'Conta provisionada',
        'Este e-mail já está associado a uma conta ativa.',
      ),
      _ => ('Convite', 'Não foi possível identificar o estado do convite.'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TemdasTokens.smallGap),
        Text(message),
      ],
    );
  }
}

String _mensagemErroConvite(Object error) {
  if (error is backend.ConviteException) {
    return switch (error.codigo) {
      'emailInvalido' => 'Informe um e-mail válido.',
      'jaProvisionado' => 'Este e-mail já possui uma conta provisionada.',
      'jaConvidado' => 'Já existe um convite pendente para este e-mail.',
      'conviteNaoEncontrado' => 'Não há convite pendente para reenviar.',
      'aguardeReenvio' =>
        'O reenvio ainda está em cooldown. Tente novamente mais tarde.',
      'conviteIndisponivel' =>
        'O serviço de convites está indisponível. Tente novamente.',
      'conviteNaoConfigurado' => 'O serviço de convites não está configurado.',
      'limiteSupabase' => 'O serviço de convites atingiu o limite de envios.',
      'limiteEnvios' =>
        'Limite de envios atingido. Tente novamente mais tarde.',
      'conviteRecusado' =>
        'O serviço recusou o convite. Confira o e-mail e tente novamente.',
      _ => 'Não foi possível concluir a operação. Tente novamente.',
    };
  }
  if (error is backend.AuthException) {
    return switch (error.codigo) {
      'adminRequired' =>
        'Sua sessão não tem permissão para gerenciar convites.',
      'tokenMissing' ||
      'tokenInvalid' ||
      'tokenExpired' => 'Sua sessão expirou. Entre novamente para continuar.',
      _ => 'Não foi possível concluir a operação. Tente novamente.',
    };
  }
  return 'Não foi possível concluir a operação. Tente novamente.';
}

class _EstadoPerfil extends StatelessWidget {
  const _EstadoPerfil({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(TemdasTokens.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: TemdasTokens.contentGap),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: TemdasTokens.smallGap),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: TemdasTokens.contentGap),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    ),
  );
}
