import 'dart:async';
import 'dart:convert';

// Test adapter forwards Serverpod's generated repository calls.
// ignore_for_file: invalid_use_of_internal_member

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jose/jose.dart';
import 'package:serverpod/serverpod.dart';
// Serverpod's test authentication helper is internal in 3.4.11.
// ignore: implementation_imports
import 'package:serverpod/src/server/server.dart';
// ignore: implementation_imports
import 'package:serverpod/src/server/session.dart';
import 'package:temdas_backend_server/src/auth/auth_endpoint.dart';
import 'package:temdas_backend_server/src/auth/provisioning_service.dart';
import 'package:temdas_backend_server/src/auth/supabase_auth_service.dart';
import 'package:temdas_backend_server/src/demandas/demanda_endpoint.dart';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:temdas_backend_server/src/sprints/sprint_custom_schema.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  registerSprintCustomIndexes();
  var sequence = 0;

  withServerpod(
    'auth.provisionar with real PostgreSQL and simulated Supabase Auth',
    (builder, _) {
      late String marker;
      late SupabaseAuthService authService;
      late AuthEndpoint endpoint;
      late JsonWebKey signingKey;
      late Map<String, String> confirmedEmails;
      late List<String> createdSubs;
      late List<String> createdEmails;
      late List<int> createdDemandas;
      late List<String> authRequests;

      setUpAll(() async {
        final columns = await builder.build().db.unsafeQuery(
          "SELECT table_name, column_name FROM information_schema.columns "
          "WHERE table_schema = 'public' AND "
          "((table_name = 'usuarios' AND column_name = 'isAdmin') "
          "OR (table_name = 'emails_whitelist' "
          "AND column_name = 'ultimoConviteEm'))",
        );
        if (columns.length != 2) {
          throw StateError(
            'PostgreSQL de testes sem colunas de provisioning: '
            'usuarios.isAdmin e/ou emails_whitelist.ultimoConviteEm. '
            'Nenhuma migration é aplicada por este teste.',
          );
        }
      });

      String subject(String suffix) {
        final sub = 'provisioning-test-$marker-$suffix';
        createdSubs.add(sub);
        return sub;
      }

      String email(String suffix) {
        final value = 'provisioning-$marker-$suffix@example.com';
        createdEmails.add(value);
        return value;
      }

      String token(
        String sub,
        String aal, {
        Map<String, dynamic> extraClaims = const {},
      }) {
        final builder = JsonWebSignatureBuilder()
          ..jsonContent = {
            'iss': authService.issuer,
            'sub': sub,
            'aal': aal,
            'aud': 'authenticated',
            'exp':
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
            'email': 'untrusted@example.com',
            ...extraClaims,
          };
        builder.addRecipient(signingKey, algorithm: 'ES256');
        return builder.build().toCompactSerialization();
      }

      Future<Session> asUser(
        String sub,
        String aal, {
        Map<String, dynamic> extraClaims = const {},
      }) async {
        final session = builder.build();
        session.server.setAuthenticationHandlerForTesting((_, _) async => null);
        await session.updateAuthenticationKey(
          token(sub, aal, extraClaims: extraClaims),
        );
        return session;
      }

      Future<EmailWhitelist> allow(String value, {DateTime? usedAt}) async {
        final session = builder.build();
        return EmailWhitelist.db.insertRow(
          session,
          EmailWhitelist(
            emailNormalizado: value,
            utilizadoEm: usedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      }

      Future<Usuario?> userRow(String sub) => Usuario.db.findFirstRow(
        builder.build(),
        where: (t) => t.supabaseUserId.equals(sub),
      );

      Future<EmailWhitelist?> whitelistRow(String value) =>
          EmailWhitelist.db.findFirstRow(
            builder.build(),
            where: (t) => t.emailNormalizado.equals(value),
          );

      setUp(() {
        marker = '${DateTime.now().microsecondsSinceEpoch}-${sequence++}';
        createdSubs = [];
        createdEmails = [];
        createdDemandas = [];
        confirmedEmails = {};
        authRequests = [];
        signingKey = JsonWebKey.fromJson({
          ...JsonWebKey.generate('ES256').toJson(),
          'kid': 'provisioning-test-key',
          'alg': 'ES256',
        });
        final publicKey = Map<String, dynamic>.of(signingKey.toJson())
          ..remove('d');
        final client = MockClient((request) async {
          authRequests.add('${request.method} ${request.url.path}');
          if (request.method == 'GET' &&
              request.url.path == '/auth/v1/.well-known/jwks.json') {
            return http.Response(
              jsonEncode({
                'keys': [publicKey],
              }),
              200,
            );
          }
          if (request.method == 'GET' &&
              request.url.pathSegments.length == 5 &&
              request.url.pathSegments.take(4).join('/') ==
                  'auth/v1/admin/users') {
            final sub = request.url.pathSegments.last;
            final value = confirmedEmails[sub];
            if (value == null) return http.Response('{}', 404);
            expect(request.headers['apikey'], 'sb_secret_test');
            expect(request.headers.containsKey('authorization'), isFalse);
            return http.Response(
              jsonEncode({
                'id': sub,
                'email': value,
                'email_confirmed_at': '2026-10-08T00:00:00Z',
                'is_anonymous': false,
              }),
              200,
            );
          }
          throw StateError('Unexpected HTTP request: ${request.method}');
        });
        authService = SupabaseAuthService(
          supabaseUrl: 'https://supabase.invalid',
          httpClient: client,
        );
        setSupabaseAuthServiceForTesting(authService);
        endpoint = AuthEndpoint(
          authService: authService,
          provisioningService: ProvisioningService(
            emailSource: SupabaseConfirmedEmailSource(
              client: client,
              environment: {
                'SUPABASE_URL': 'https://supabase.invalid',
                'SUPABASE_SECRET_KEY': 'sb_secret_test',
              },
            ),
            store: const PostgresProvisioningStore(),
          ),
        );
      });

      tearDown(() async {
        setSupabaseAuthServiceForTesting(null);
        final session = builder.build();
        for (final id in createdDemandas) {
          final row = await Demanda.db.findById(session, id);
          if (row != null) await Demanda.db.deleteRow(session, row);
        }
        for (final sub in createdSubs) {
          final row = await Usuario.db.findFirstRow(
            session,
            where: (t) => t.supabaseUserId.equals(sub),
          );
          if (row != null) await Usuario.db.deleteRow(session, row);
        }
        for (final value in createdEmails) {
          final row = await EmailWhitelist.db.findFirstRow(
            session,
            where: (t) => t.emailNormalizado.equals(value),
          );
          if (row != null) await EmailWhitelist.db.deleteRow(session, row);
        }
      });

      test(
        'first AAL1 provisioning creates a non-admin and consumes whitelist',
        () async {
          final sub = subject('first');
          final value = email('first');
          confirmedEmails[sub] = '  ${value.toUpperCase()}  ';
          await allow(value);

          final result = await endpoint.provisionar(await asUser(sub, 'aal1'));
          final usuario = await userRow(sub);
          final whitelist = await whitelistRow(value);
          expect(result.aal, 'aal1');
          expect(result.usuarioId, usuario?.id);
          expect(result.isAdmin, isFalse);
          expect(usuario?.isAdmin, isFalse);
          final me = await endpoint.me(
            await asUser(sub, 'aal2', extraClaims: {'isAdmin': true}),
          );
          expect(me.usuarioId, usuario?.id);
          expect(me.aal, 'aal2');
          expect(me.isAdmin, isFalse);
          await expectLater(
            endpoint.me(await asUser(sub, 'aal1')),
            throwsA(
              isA<AuthException>().having(
                (error) => error.codigo,
                'codigo',
                'aal2Required',
              ),
            ),
          );
          expect(whitelist?.utilizadoEm, isNotNull);
          expect(authRequests, contains('GET /auth/v1/admin/users/$sub'));
          expect(
            authRequests.every((request) => request.startsWith('GET ')),
            isTrue,
          );
        },
      );

      test('auth.me rejects an unknown internal identity', () async {
        final sub = subject('unknown-me');
        await expectLater(
          endpoint.me(await asUser(sub, 'aal2')),
          throwsA(
            isA<AuthException>().having(
              (error) => error.codigo,
              'codigo',
              'usuarioNotFound',
            ),
          ),
        );
      });

      test('new user without whitelist is rejected without INSERT', () async {
        final sub = subject('not-allowed');
        confirmedEmails[sub] = email('not-allowed');

        await expectLater(
          endpoint.provisionar(await asUser(sub, 'aal1')),
          throwsA(
            isA<AuthException>().having(
              (error) => error.codigo,
              'codigo',
              'emailNaoAutorizado',
            ),
          ),
        );
        expect(await userRow(sub), isNull);
      });

      test('same sub is idempotent and retains consumed timestamp', () async {
        final sub = subject('repeat');
        final value = email('repeat');
        confirmedEmails[sub] = value;
        await allow(value);

        final first = await endpoint.provisionar(await asUser(sub, 'aal1'));
        final consumedAt = (await whitelistRow(value))!.utilizadoEm;
        final second = await endpoint.provisionar(await asUser(sub, 'aal2'));
        expect(second.usuarioId, first.usuarioId);
        expect(second.aal, 'aal2');
        expect((await whitelistRow(value))!.utilizadoEm, consumedAt);
        expect(
          await Usuario.db.count(
            builder.build(),
            where: (t) => t.supabaseUserId.equals(sub),
          ),
          1,
        );
      });

      test(
        'concurrent calls for the same sub and email create one user',
        () async {
          final sub = subject('concurrent');
          final value = email('concurrent');
          confirmedEmails[sub] = value;
          await allow(value);
          final sessions = await Future.wait(
            List.generate(6, (_) => asUser(sub, 'aal1')),
          );
          final results = await Future.wait(
            sessions.map(endpoint.provisionar),
          ).timeout(const Duration(seconds: 20));
          expect(
            results.map((result) => result.usuarioId).toSet(),
            hasLength(1),
          );
          expect(
            await Usuario.db.count(
              builder.build(),
              where: (t) => t.supabaseUserId.equals(sub),
            ),
            1,
          );
          expect((await whitelistRow(value))!.utilizadoEm, isNotNull);
        },
      );

      test('another sub cannot reuse a consumed whitelist row', () async {
        final firstSub = subject('owner');
        final secondSub = subject('other');
        final value = email('shared');
        confirmedEmails[firstSub] = value;
        confirmedEmails[secondSub] = value;
        await allow(value);

        final first = await endpoint.provisionar(
          await asUser(firstSub, 'aal1'),
        );
        final consumedAt = (await whitelistRow(value))!.utilizadoEm;
        await expectLater(
          endpoint.provisionar(await asUser(secondSub, 'aal1')),
          throwsA(
            isA<AuthException>().having(
              (error) => error.codigo,
              'codigo',
              'conviteJaUtilizado',
            ),
          ),
        );
        expect((await userRow(firstSub))!.id, first.usuarioId);
        expect(await userRow(secondSub), isNull);
        expect((await whitelistRow(value))!.utilizadoEm, consumedAt);
      });

      test(
        'concurrent different subs cannot share one whitelist row',
        () async {
          final firstSub = subject('race-first');
          final secondSub = subject('race-second');
          final value = email('race-shared');
          confirmedEmails[firstSub] = value;
          confirmedEmails[secondSub] = value;
          await allow(value);

          final first = await asUser(firstSub, 'aal1');
          final second = await asUser(secondSub, 'aal1');
          Future<Object> attempt(Session session) async {
            try {
              return await endpoint.provisionar(session);
            } on AuthException catch (error) {
              return error.codigo;
            }
          }

          final results = await Future.wait([
            attempt(first),
            attempt(second),
          ]).timeout(const Duration(seconds: 20));
          expect(results.whereType<AuthMe>(), hasLength(1));
          expect(results.whereType<String>(), ['conviteJaUtilizado']);
          expect((await whitelistRow(value))!.utilizadoEm, isNotNull);
          expect(
            [
              await userRow(firstSub),
              await userRow(secondSub),
            ].whereType<Usuario>(),
            hasLength(1),
          );
        },
      );

      test('failure after INSERT rolls back user creation', () async {
        final sub = subject('insert-failure');
        final value = email('insert-failure');
        confirmedEmails[sub] = value;
        await allow(value);
        final realSession = await asUser(sub, 'aal1');
        final fault = _FaultSession(realSession, _Fault.afterUserInsert);

        await expectLater(
          endpoint.provisionar(fault),
          throwsA(isA<StateError>()),
        );
        expect(fault.triggered, isTrue);
        expect(await userRow(sub), isNull);
        expect((await whitelistRow(value))!.utilizadoEm, isNull);
      });

      test('failure after UPDATE rolls back user and whitelist', () async {
        final sub = subject('update-failure');
        final value = email('update-failure');
        confirmedEmails[sub] = value;
        await allow(value);
        final realSession = await asUser(sub, 'aal1');
        final fault = _FaultSession(realSession, _Fault.afterWhitelistUpdate);

        await expectLater(
          endpoint.provisionar(fault),
          throwsA(isA<StateError>()),
        );
        expect(fault.triggered, isTrue);
        expect(await userRow(sub), isNull);
        expect((await whitelistRow(value))!.utilizadoEm, isNull);
      });

      test('existing admin keeps id, role, and demand ownership', () async {
        final sub = subject('admin');
        final value = email('admin');
        confirmedEmails[sub] = value;
        final admin = await Usuario.db.insertRow(
          builder.build(),
          Usuario(
            supabaseUserId: sub,
            isAdmin: true,
            createdAt: DateTime.now().toUtc(),
          ),
        );
        final aal2 = await asUser(
          sub,
          'aal2',
          extraClaims: {'isAdmin': false},
        );
        final demanda = await DemandaEndpoint().criarDemanda(
          aal2,
          DemandaCreateRequest(
            titulo: 'Owner preserved',
            tempoEstimadoMinutos: 30,
          ),
        );
        createdDemandas.add(demanda.id!);

        final result = await endpoint.provisionar(await asUser(sub, 'aal1'));
        final adminAfter = (await userRow(sub))!;
        final demandaAfter = await Demanda.db.findById(
          builder.build(),
          demanda.id!,
        );
        expect(result.usuarioId, admin.id);
        expect(result.isAdmin, isTrue);
        final me = await endpoint.me(aal2);
        expect(me.usuarioId, admin.id);
        expect(me.aal, 'aal2');
        expect(me.isAdmin, isTrue);
        expect(adminAfter.id, admin.id);
        expect(adminAfter.isAdmin, isTrue);
        expect(demandaAfter?.usuarioId, admin.id);
        expect(await whitelistRow(value), isNull);
        expect(
          (await DemandaEndpoint().buscarDemandaPorId(aal2, demanda.id!))?.id,
          demanda.id,
        );

        final otherSub = subject('admin-impostor');
        confirmedEmails[otherSub] = value;
        await expectLater(
          endpoint.provisionar(await asUser(otherSub, 'aal1')),
          throwsA(
            isA<AuthException>().having(
              (error) => error.codigo,
              'codigo',
              'emailNaoAutorizado',
            ),
          ),
        );
        expect(await userRow(otherSub), isNull);
        expect((await userRow(sub))!.isAdmin, isTrue);
      });

      test('existing common user without whitelist remains common', () async {
        final sub = subject('common');
        confirmedEmails[sub] = email('common');
        final common = await Usuario.db.insertRow(
          builder.build(),
          Usuario(
            supabaseUserId: sub,
            isAdmin: false,
            createdAt: DateTime.now().toUtc(),
          ),
        );

        final result = await endpoint.provisionar(
          await asUser(sub, 'aal1', extraClaims: {'isAdmin': true}),
        );
        expect(result.usuarioId, common.id);
        expect(result.isAdmin, isFalse);
        expect(await whitelistRow(confirmedEmails[sub]!), isNull);
        await expectLater(
          endpoint.me(await asUser(sub, 'aal1')),
          throwsA(
            isA<AuthException>().having(
              (error) => error.codigo,
              'codigo',
              'aal2Required',
            ),
          ),
        );
        final me = await endpoint.me(await asUser(sub, 'aal2'));
        expect(me.usuarioId, common.id);
        expect(me.isAdmin, isFalse);
      });
    },
    applyMigrations: false,
    rollbackDatabase: RollbackDatabase.disabled,
  );
}

enum _Fault { afterUserInsert, afterWhitelistUpdate }

class _FaultSession implements Session {
  _FaultSession(this._original, _Fault fault)
    : _database = _FaultDatabase(_original.db, fault);

  final Session _original;
  final _FaultDatabase _database;

  bool get triggered => _database.triggered;

  @override
  Database get db => _database;

  @override
  String? get authenticationKey => _original.authenticationKey;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _original.noSuchMethod(invocation);
}

class _FaultDatabase implements Database {
  _FaultDatabase(this._original, this.fault);

  final Database _original;
  final _Fault fault;
  bool triggered = false;

  @override
  Future<R> transaction<R>(
    TransactionFunction<R> transactionFunction, {
    TransactionSettings? settings,
  }) => _original.transaction(transactionFunction, settings: settings);

  @override
  Future<DatabaseResult> unsafeQuery(
    String query, {
    int? timeoutInSeconds,
    Transaction? transaction,
    QueryParameters? parameters,
  }) async {
    final result = await _original.unsafeQuery(
      query,
      timeoutInSeconds: timeoutInSeconds,
      transaction: transaction,
      parameters: parameters,
    );
    if (fault == _Fault.afterUserInsert &&
        query.startsWith('INSERT INTO "usuarios"')) {
      triggered = true;
      throw StateError('Injected failure after user INSERT');
    }
    return result;
  }

  // Generated repositories call Database.findFirstRow directly.
  @override
  Future<T?> findFirstRow<T extends TableRow>({
    Expression? where,
    int? offset,
    Column? orderBy,
    List<Order>? orderByList,
    bool orderDescending = false,
    Transaction? transaction,
    Include? include,
    LockMode? lockMode,
    LockBehavior? lockBehavior,
  }) => _original.findFirstRow<T>(
    where: where,
    offset: offset,
    orderBy: orderBy,
    orderByList: orderByList,
    orderDescending: orderDescending,
    transaction: transaction,
    include: include,
    lockMode: lockMode,
    lockBehavior: lockBehavior,
  );

  // Generated repositories call Database.updateById directly.
  @override
  Future<T?> updateById<T extends TableRow>(
    Object id, {
    required List<ColumnValue> columnValues,
    Transaction? transaction,
  }) async {
    final result = await _original.updateById<T>(
      id,
      columnValues: columnValues,
      transaction: transaction,
    );
    if (fault == _Fault.afterWhitelistUpdate && T == EmailWhitelist) {
      triggered = true;
      throw StateError('Injected failure after whitelist UPDATE');
    }
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _original.noSuchMethod(invocation);
}
