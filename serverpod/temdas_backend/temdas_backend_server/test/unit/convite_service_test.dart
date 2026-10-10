import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serverpod/serverpod.dart' show Session;
import 'package:temdas_backend_server/src/admin/convite_endpoint.dart';
import 'package:temdas_backend_server/src/admin/convite_service.dart';
import 'package:temdas_backend_server/src/auth/supabase_auth_service.dart';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  late DateTime now;
  late _MemoryStore store;
  late _FakeSender sender;
  late ConviteService service;
  late ConviteEndpoint endpoint;
  final session = _StubSession();

  setUp(() {
    now = DateTime.utc(2026, 10, 8);
    store = _MemoryStore();
    sender = _FakeSender();
    service = ConviteService(
      store: store,
      sender: sender,
      rateLimiter: ConviteRateLimiter(now: () => now),
    );
    endpoint = ConviteEndpoint(service: service);
  });
  tearDown(() => setUsuarioResolverForTesting(null));

  Matcher conviteError(String code) => throwsA(
    isA<ConviteException>().having((error) => error.codigo, 'codigo', code),
  );
  Matcher authError(String code) => throwsA(
    isA<AuthException>().having((error) => error.codigo, 'codigo', code),
  );

  void asUser({required bool admin, required String aal}) {
    final usuario = Usuario(
      id: 7,
      supabaseUserId: 'test-user',
      isAdmin: admin,
      createdAt: now,
    );
    setUsuarioResolverForTesting(
      (_) async => AuthenticatedUsuario(usuario, usuario.supabaseUserId, aal),
    );
  }

  test('normalizes valid email and rejects malformed input', () {
    expect(normalizarEmail('  Pessoa@Exemplo.COM  '), 'pessoa@exemplo.com');
    for (final email in [
      'a@@b.com',
      'a b@b.com',
      'a@-b.com',
      'a@b',
      'a..b@b.com',
    ]) {
      expect(() => normalizarEmail(email), conviteError('emailInvalido'));
    }
  });

  test('endpoint requires AAL2 and an internal admin', () async {
    await expectLater(
      endpoint.convidar(session, 'a@b.com'),
      authError('tokenMissing'),
    );
    asUser(admin: true, aal: 'aal1');
    await expectLater(
      endpoint.convidar(session, 'a@b.com'),
      authError('aal2Required'),
    );
    asUser(admin: false, aal: 'aal2');
    await expectLater(
      endpoint.convidar(session, 'a@b.com'),
      authError('adminRequired'),
    );
    await expectLater(
      endpoint.consultar(session, 'a@b.com'),
      authError('adminRequired'),
    );
    await expectLater(
      endpoint.reenviar(session, 'a@b.com'),
      authError('adminRequired'),
    );
    expect(sender.calls, isEmpty);
    expect(store.rows, isEmpty);
  });

  test('invite, duplicate, resend and provisioned status', () async {
    asUser(admin: true, aal: 'aal2');
    expect(await endpoint.consultar(session, ' A@B.COM '), 'ausente');
    expect(await endpoint.convidar(session, ' A@B.COM '), 'enviado');
    expect(store.rows.keys, ['a@b.com']);
    expect(store.rows['a@b.com']!.utilizadoEm, isNull);
    expect(store.rows['a@b.com']!.ultimoConviteEm, now);
    final createdAt = store.rows['a@b.com']!.createdAt;
    expect(await endpoint.consultar(session, 'a@b.com'), 'pendente');
    await expectLater(
      endpoint.convidar(session, 'a@b.com'),
      conviteError('jaConvidado'),
    );
    await expectLater(
      endpoint.reenviar(session, 'a@b.com'),
      conviteError('aguardeReenvio'),
    );
    now = now.add(const Duration(minutes: 16));
    expect(await endpoint.reenviar(session, 'a@b.com'), 'reenviado');
    expect(store.rows.length, 1);
    expect(store.rows['a@b.com']!.createdAt, createdAt);
    expect(store.rows['a@b.com']!.ultimoConviteEm, now);
    expect(sender.calls, ['a@b.com', 'a@b.com']);
    store.rows['a@b.com']!.utilizadoEm = now;
    expect(await endpoint.consultar(session, 'a@b.com'), 'provisionado');
    await expectLater(
      endpoint.reenviar(session, 'a@b.com'),
      conviteError('jaProvisionado'),
    );
  });

  test('failed delivery rolls back new whitelist row and backs off', () async {
    asUser(admin: true, aal: 'aal2');
    sender.failure = ConviteException(codigo: 'conviteIndisponivel');
    await expectLater(
      endpoint.convidar(session, 'a@b.com'),
      conviteError('conviteIndisponivel'),
    );
    expect(store.rows, isEmpty);
    sender.failure = null;
    await expectLater(
      endpoint.convidar(session, 'a@b.com'),
      conviteError('aguardeReenvio'),
    );
    now = now.add(const Duration(minutes: 1, seconds: 1));
    expect(await endpoint.convidar(session, 'a@b.com'), 'enviado');
  });

  test('failed resend keeps the pending whitelist row unchanged', () async {
    asUser(admin: true, aal: 'aal2');
    final row = EmailWhitelist(
      emailNormalizado: 'a@b.com',
      createdAt: now.subtract(const Duration(hours: 1)),
    );
    store.rows['a@b.com'] = row;
    sender.failure = ConviteException(codigo: 'conviteRecusado');
    await expectLater(
      endpoint.reenviar(session, 'a@b.com'),
      conviteError('conviteRecusado'),
    );
    expect(store.rows['a@b.com'], same(row));
    expect(row.utilizadoEm, isNull);
    expect(row.ultimoConviteEm, isNull);
  });

  test('failed new invite does not remove a provisioned row', () async {
    asUser(admin: true, aal: 'aal2');
    sender.onSend = (_) async {
      store.rows['a@b.com']!.utilizadoEm = now;
      throw ConviteException(codigo: 'conviteIndisponivel');
    };
    await expectLater(
      endpoint.convidar(session, 'a@b.com'),
      conviteError('conviteIndisponivel'),
    );
    expect(store.rows['a@b.com']!.utilizadoEm, now);
    expect(store.rows['a@b.com']!.ultimoConviteEm, isNull);
    expect(store.rows['a@b.com']!.conviteReservaId, isNull);
  });

  test('concurrent invites for one email cause one delivery', () async {
    asUser(admin: true, aal: 'aal2');
    final started = Completer<void>();
    final release = Completer<void>();
    sender.onSend = (_) async {
      expect(store.transactionOpen, isFalse);
      expect(store.rows['a@b.com']!.ultimoConviteEm, isNull);
      started.complete();
      await release.future;
    };
    final first = endpoint.convidar(session, 'A@B.COM');
    await started.future;
    final second = expectLater(
      endpoint.convidar(session, ' a@b.com '),
      conviteError('jaConvidado'),
    );
    release.complete();
    expect(await first, 'enviado');
    await second;
    expect(sender.calls, ['a@b.com']);
    expect(store.rows.length, 1);
  });

  test('concurrent resends for a pending email cause one delivery', () async {
    asUser(admin: true, aal: 'aal2');
    await expectLater(
      endpoint.reenviar(session, 'a@b.com'),
      conviteError('conviteNaoEncontrado'),
    );
    store.rows['a@b.com'] = EmailWhitelist(
      emailNormalizado: 'a@b.com',
      createdAt: now.subtract(const Duration(hours: 1)),
    );
    final started = Completer<void>();
    final release = Completer<void>();
    sender.onSend = (_) async {
      expect(store.transactionOpen, isFalse);
      expect(store.rows['a@b.com']!.ultimoConviteEm, isNull);
      started.complete();
      await release.future;
    };
    final first = endpoint.reenviar(session, 'a@b.com');
    await started.future;
    final second = expectLater(
      endpoint.reenviar(session, 'A@B.COM'),
      conviteError('aguardeReenvio'),
    );
    release.complete();
    expect(await first, 'reenviado');
    await second;
    expect(sender.calls, ['a@b.com']);
    expect(store.rows.length, 1);
  });

  test(
    'persisted send timestamp blocks resend across limiter instances',
    () async {
      asUser(admin: true, aal: 'aal2');
      store.rows['a@b.com'] = EmailWhitelist(
        emailNormalizado: 'a@b.com',
        createdAt: now.subtract(const Duration(days: 1)),
        ultimoConviteEm: now.subtract(const Duration(minutes: 2)),
      );
      final anotherProcess = ConviteService(
        store: store,
        sender: sender,
        rateLimiter: ConviteRateLimiter(now: () => now),
      );
      await expectLater(
        anotherProcess.enviar(session, 7, 'a@b.com', reenviar: true),
        conviteError('aguardeReenvio'),
      );
      expect(sender.calls, isEmpty);
    },
  );

  test('createdAt does not control resend cooldown', () async {
    asUser(admin: true, aal: 'aal2');
    store.rows['a@b.com'] = EmailWhitelist(
      emailNormalizado: 'a@b.com',
      createdAt: now,
    );
    expect(await endpoint.reenviar(session, 'a@b.com'), 'reenviado');
    expect(store.rows['a@b.com']!.createdAt, now);
    expect(store.rows['a@b.com']!.ultimoConviteEm, now);
  });

  test('reservation blocks a second service during HTTP', () async {
    asUser(admin: true, aal: 'aal2');
    store.rows['a@b.com'] = EmailWhitelist(
      emailNormalizado: 'a@b.com',
      createdAt: now.subtract(const Duration(hours: 1)),
    );
    final started = Completer<void>();
    final release = Completer<void>();
    sender.onSend = (_) async {
      started.complete();
      await release.future;
    };
    final first = endpoint.reenviar(session, 'a@b.com');
    await started.future;
    final other = ConviteService(
      store: store,
      sender: sender,
      rateLimiter: ConviteRateLimiter(now: () => now),
    );
    await expectLater(
      other.enviar(session, 8, 'a@b.com', reenviar: true),
      conviteError('aguardeReenvio'),
    );
    release.complete();
    expect(await first, 'reenviado');
    expect(sender.calls, ['a@b.com']);
  });

  test('expired reservation for unsent invite can be recovered', () async {
    asUser(admin: true, aal: 'aal2');
    store.rows['a@b.com'] = EmailWhitelist(
      emailNormalizado: 'a@b.com',
      createdAt: now.subtract(const Duration(minutes: 3)),
      conviteReservaId: 'abandoned',
      conviteReservadoAte: now.subtract(const Duration(minutes: 1)),
    );
    expect(await endpoint.convidar(session, 'a@b.com'), 'enviado');
    expect(store.rows['a@b.com']!.ultimoConviteEm, now);
  });

  test('per-admin limit blocks excessive distinct invites', () async {
    asUser(admin: true, aal: 'aal2');
    for (var i = 0; i < 20; i++) {
      expect(
        await endpoint.convidar(session, 'person$i@example.com'),
        'enviado',
      );
    }
    await expectLater(
      endpoint.convidar(session, 'person20@example.com'),
      conviteError('limiteEnvios'),
    );
    expect(sender.calls.length, 20);
    expect(store.rows.length, 20);
  });

  test(
    'Supabase sender uses secret only in apikey and configured redirect',
    () async {
      final sender = SupabaseConviteSender(
        environment: {
          'SUPABASE_URL': 'https://project.supabase.co',
          'SUPABASE_SECRET_KEY': 'sb_secret_test',
          'SUPABASE_INVITE_REDIRECT_URL': 'https://app.example.com/accept',
        },
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/auth/v1/invite');
          expect(
            request.url.queryParameters['redirect_to'],
            'https://app.example.com/accept',
          );
          expect(request.headers['apikey'], 'sb_secret_test');
          expect(request.headers.containsKey('authorization'), isFalse);
          expect(jsonDecode(request.body), {'email': 'a@b.com'});
          return http.Response('{}', 200);
        }),
      );
      await sender.enviar('a@b.com');
    },
  );

  test(
    'Supabase sender classifies failures without leaking response',
    () async {
      for (final (status, code) in [
        (429, 'limiteSupabase'),
        (401, 'conviteNaoConfigurado'),
        (422, 'conviteRecusado'),
        (503, 'conviteIndisponivel'),
      ]) {
        final sender = SupabaseConviteSender(
          environment: {
            'SUPABASE_URL': 'https://project.supabase.co',
            'SUPABASE_SECRET_KEY': 'sb_secret_test',
            'SUPABASE_INVITE_REDIRECT_URL': 'https://app.example.com/accept',
          },
          client: MockClient((_) async => http.Response('sensitive', status)),
        );
        await expectLater(sender.enviar('a@b.com'), conviteError(code));
      }
      final missing = SupabaseConviteSender(environment: {});
      await expectLater(
        missing.enviar('a@b.com'),
        conviteError('conviteNaoConfigurado'),
      );
      final networkFailure = SupabaseConviteSender(
        environment: {
          'SUPABASE_URL': 'https://project.supabase.co',
          'SUPABASE_SECRET_KEY': 'sb_secret_test',
          'SUPABASE_INVITE_REDIRECT_URL': 'https://app.example.com/accept',
        },
        client: MockClient((_) async => throw StateError('transport error')),
      );
      await expectLater(
        networkFailure.enviar('a@b.com'),
        conviteError('conviteIndisponivel'),
      );
    },
  );
}

class _StubSession implements Session {
  @override
  String? get authenticationKey => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSender implements ConviteSender {
  final List<String> calls = [];
  Object? failure;
  Future<void> Function(String)? onSend;

  @override
  Future<void> enviar(String email) async {
    calls.add(email);
    if (onSend != null) await onSend!(email);
    if (failure != null) throw failure!;
  }
}

class _MemoryStore implements ConviteStore {
  final Map<String, EmailWhitelist> rows = {};
  int nextReservation = 0;
  bool transactionOpen = false;

  @override
  Future<EmailWhitelist?> buscar(Session session, String email) async =>
      rows[email];

  @override
  Future<ReservaConvite> reservar(
    Session session,
    String email,
    bool reenviar,
    DateTime agora,
  ) async {
    transactionOpen = true;
    try {
      final row = rows[email];
      if (row?.utilizadoEm != null) {
        throw ConviteException(codigo: 'jaProvisionado');
      }
      final recover =
          row != null &&
          row.ultimoConviteEm == null &&
          row.conviteReservaId != null &&
          row.conviteReservadoAte?.isAfter(agora) != true;
      if (!reenviar && row != null && !recover) {
        throw ConviteException(codigo: 'jaConvidado');
      }
      if (reenviar && row == null) {
        throw ConviteException(codigo: 'conviteNaoEncontrado');
      }
      if (row?.conviteReservadoAte?.isAfter(agora) == true ||
          (row?.ultimoConviteEm != null &&
              agora.difference(row!.ultimoConviteEm!) <
                  const Duration(minutes: 15))) {
        throw ConviteException(codigo: 'aguardeReenvio');
      }
      final id = '${++nextReservation}';
      final reserved =
          row ?? EmailWhitelist(emailNormalizado: email, createdAt: agora);
      reserved.conviteReservaId = id;
      reserved.conviteReservadoAte = agora.add(const Duration(minutes: 2));
      rows[email] = reserved;
      return ReservaConvite(id, row == null || recover);
    } finally {
      transactionOpen = false;
    }
  }

  @override
  Future<void> concluir(
    Session session,
    String email,
    ReservaConvite reserva,
    DateTime enviadoEm,
  ) async {
    transactionOpen = true;
    try {
      final row = rows[email];
      if (row?.conviteReservaId != reserva.id) {
        throw ConviteException(codigo: 'conviteIndisponivel');
      }
      row!.ultimoConviteEm = enviadoEm;
      row.conviteReservaId = null;
      row.conviteReservadoAte = null;
    } finally {
      transactionOpen = false;
    }
  }

  @override
  Future<void> liberar(
    Session session,
    String email,
    ReservaConvite reserva,
  ) async {
    transactionOpen = true;
    try {
      final row = rows[email];
      if (row?.conviteReservaId != reserva.id) return;
      if (reserva.nova && row!.utilizadoEm == null) {
        rows.remove(email);
      } else {
        row!.conviteReservaId = null;
        row.conviteReservadoAte = null;
      }
    } finally {
      transactionOpen = false;
    }
  }
}
