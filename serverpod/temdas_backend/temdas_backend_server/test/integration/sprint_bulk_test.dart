import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:temdas_backend_server/src/sprints/sprint_custom_schema.dart';
import 'package:temdas_backend_server/src/sprints/sprint_demanda_service.dart';

import 'test_tools/authenticated_test_user.dart';
import 'test_tools/serverpod_test_tools.dart';

Matcher fails(SprintErroCodigo code) => throwsA(
  isA<SprintException>().having((e) => e.codigo, 'codigo', code),
);

// Count only calls through the real Serverpod 3.4.11 database adapter. Driver
// BEGIN/COMMIT and server-side trigger statements are intentionally not counted.
class _MeasuredSession extends Session {
  _MeasuredSession(Session source)
    : super(
        server: source.server,
        enableLogging: false,
        endpoint: 'bulk-benchmark',
      );
  int queries = 0;
  Duration queryTime = Duration.zero;
  @override
  get logQuery =>
      ({
        required String query,
        required Duration duration,
        required int? numRowsAffected,
        required String? error,
        required StackTrace stackTrace,
      }) async {
        queries++;
        queryTime += duration;
      };
}

void main() {
  registerSprintCustomIndexes();
  final prefix = 'bulk-${DateTime.now().microsecondsSinceEpoch}';
  var serial = 0;
  withServerpod(
    'Vinculação em lote com triggers reais',
    (builder, endpoints) {
      late Usuario owner;
      final owners = <Usuario>[];
      setUp(() async {
        final sub = '$prefix-${serial++}';
        await installAal2TestUser(builder, sub);
        owner = (await Usuario.db.findFirstRow(
          builder.build(),
          where: (t) => t.supabaseUserId.equals(sub),
        ))!;
        owners.add(owner);
      });
      tearDown(() async {
        clearAal2TestUser();
        for (final u in owners) {
          await Sprint.db.deleteWhere(
            builder.build(),
            where: (t) => t.usuarioId.equals(u.id!),
          );
          await Demanda.db.deleteWhere(
            builder.build(),
            where: (t) => t.usuarioId.equals(u.id!),
          );
          await Usuario.db.deleteRow(builder.build(), u);
        }
        owners.clear();
      });
      Future<Demanda> demand({Demanda? parent}) =>
          endpoints.demanda.criarDemanda(
            builder,
            DemandaCreateRequest(
              titulo: '$prefix-demand-${serial++}',
              demandaPaiId: parent?.id,
              tempoEstimadoMinutos: 30,
            ),
          );
      Future<Sprint> sprint(int offset) => endpoints.sprint.criarSprint(
        builder,
        SprintCreateRequest(
          nome: '$prefix-sprint-${serial++}',
          dataInicio: DateTime.utc(2030, 1, 1).add(Duration(days: offset)),
          dataFim: DateTime.utc(2030, 1, 3).add(Duration(days: offset)),
        ),
      );
      Future<List<SprintDemanda>> link(Sprint s, Iterable<int> ids) =>
          endpoints.sprint.vincularDemandas(builder, s.id!, ids.toList());
      Future<List<SprintDemanda>> links(Sprint s) => SprintDemanda.db.find(
        builder.build(),
        where: (t) => t.sprintId.equals(s.id!),
      );

      test(
        'seis mães/quatro filhas; histórico 72 e cancelado; oito consultas',
        () async {
          final roots = <Demanda>[for (var i = 0; i < 6; i++) await demand()];
          final children = <Demanda>[
            for (var i = 0; i < 4; i++) await demand(parent: roots.first),
          ];
          final history = await sprint(-100);
          await link(history, roots.map((d) => d.id!));
          await Sprint.db.updateById(
            builder.build(),
            history.id!,
            columnValues: (t) => [t.status(SprintStatus.concluida)],
          );
          final cancelled = await sprint(-90);
          await link(cancelled, roots.map((d) => d.id!));
          await endpoints.sprint.cancelarSprint(builder, cancelled.id!);
          final target = await sprint(0);
          final measured = _MeasuredSession(builder.build());
          final result = await measured.db.transaction(
            (tx) => SprintDemandaService().vincularArvores(
              measured,
              sprintId: target.id!,
              demandaIds: [
                ...children.map((d) => d.id!),
                ...roots.map((d) => d.id!),
                roots.first.id!,
              ],
              usuarioId: owner.id!,
              transaction: tx,
            ),
          );
          expect(result, hasLength(10));
          expect(
            measured.queries,
            7,
          ); // + one real owner lookup in authenticated RPC.
          await measured.close();
          final again = await link(target, roots.map((d) => d.id!));
          expect(
            again.map((v) => v.id).toSet(),
            result.map((v) => v.id).toSet(),
          );
          expect(await links(target), hasLength(10));
          expect(await links(history), hasLength(10));
          expect(await links(cancelled), hasLength(10));
        },
      );

      test(
        'árvore profunda, seleção sobreposta e filha antes da mãe',
        () async {
          final root = await demand();
          var last = root;
          final all = <Demanda>[root];
          for (var i = 0; i < 20; i++) {
            last = await demand(parent: last);
            all.add(last);
          }
          final target = await sprint(0);
          final result = await link(target, [
            last.id!,
            all[10].id!,
            root.id!,
            root.id!,
          ]);
          expect(result, hasLength(21));
          expect(
            result.map((v) => v.demandaId).toSet(),
            all.map((d) => d.id!).toSet(),
          );
        },
      );

      test('filha isolada exige mãe; mãe já vinculada é aceita', () async {
        final root = await demand();
        final child = await demand(parent: root);
        final target = await sprint(0);
        await expectLater(
          link(target, [child.id!]),
          fails(SprintErroCodigo.demandaFilhaSemMae),
        );
        expect(await links(target), isEmpty);
        await link(target, [root.id!]);
        expect(await link(target, [child.id!]), hasLength(1));
      });

      test(
        'ID ausente ou estrangeiro reverte todo o lote e isola a Sprint',
        () async {
          final root = await demand();
          final target = await sprint(0);
          final other = await Usuario.db.insertRow(
            builder.build(),
            Usuario(
              supabaseUserId: '$prefix-other-${serial++}',
              createdAt: DateTime.now().toUtc(),
            ),
          );
          owners.add(other);
          final foreign = await Demanda.db.insertRow(
            builder.build(),
            Demanda(
              usuarioId: other.id!,
              titulo: 'synthetic foreign',
              status: DemandaStatus.aberta,
              prioridade: Prioridade.media,
              tempoEstimadoMinutos: 30,
              tempoExecutadoMinutos: 0,
              criadoEm: DateTime.now().toUtc(),
              atualizadoEm: DateTime.now().toUtc(),
            ),
          );
          for (final invalid in [-999999, foreign.id!]) {
            await expectLater(
              link(target, [root.id!, invalid]),
              fails(SprintErroCodigo.demandaNaoEncontrada),
            );
            expect(await links(target), isEmpty);
          }
          final foreignSprint = await Sprint.db.insertRow(
            builder.build(),
            Sprint(
              usuarioId: other.id!,
              nome: 'synthetic foreign',
              nomeNormalizado: 'synthetic foreign',
              dataInicio: DateTime.utc(2030),
              dataFim: DateTime.utc(2030, 1, 3),
              status: SprintStatus.planejada,
            ),
          );
          await expectLater(
            link(foreignSprint, [root.id!]),
            fails(SprintErroCodigo.sprintNaoEncontrada),
          );
        },
      );

      test(
        'erro diferido no COMMIT reverte o lote inteiro com triggers reais',
        () async {
          final root = await demand();
          await demand(parent: root);
          final target = await sprint(0);
          final other = await Usuario.db.insertRow(
            builder.build(),
            Usuario(
              supabaseUserId: '$prefix-deferred-${serial++}',
              createdAt: DateTime.now().toUtc(),
            ),
          );
          owners.add(other);
          final session = builder.build();
          await expectLater(
            session.db.transaction((tx) async {
              await SprintDemandaService().vincularArvores(
                session,
                sprintId: target.id!,
                demandaIds: [root.id!],
                usuarioId: owner.id!,
                transaction: tx,
              );
              // Real INITIALLY DEFERRED owner guards reject this only at COMMIT.
              await Sprint.db.updateById(
                session,
                target.id!,
                columnValues: (t) => [t.usuarioId(other.id!)],
                transaction: tx,
              );
            }),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'deferred owner SQLSTATE',
                contains('23514'),
              ),
            ),
          );
          expect(await links(target), isEmpty);
          expect(
            (await Sprint.db.findById(session, target.id!))!.usuarioId,
            owner.id,
          );
        },
      );

      test(
        'constraints imediatas aceitam filha selecionada antes da mãe',
        () async {
          final root = await demand();
          final child = await demand(parent: root);
          final target = await sprint(0);
          final session = builder.build();
          final result = await session.db.transaction((tx) async {
            await session.db.unsafeQuery(
              'SET CONSTRAINTS ALL IMMEDIATE',
              transaction: tx,
            );
            return SprintDemandaService().vincularArvores(
              session,
              sprintId: target.id!,
              demandaIds: [child.id!, root.id!],
              usuarioId: owner.id!,
              transaction: tx,
            );
          });
          expect(result, hasLength(2));
        },
      );

      test('status fechado e conflito de período não inserem linhas', () async {
        final root = await demand();
        final first = await sprint(0);
        await link(first, [root.id!]);
        final cancelled = await sprint(10);
        await endpoints.sprint.cancelarSprint(builder, cancelled.id!);
        await expectLater(
          link(cancelled, [root.id!]),
          fails(SprintErroCodigo.vinculoStatusProibido),
        );
        // A cancelled Sprint may overlap an open period. Reopening is still
        // prevented by the real exclusion constraint/endpoint, not bypassed here.
        expect(await links(cancelled), isEmpty);
        final second = await sprint(20);
        expect(await link(second, [root.id!]), hasLength(1));
        await expectLater(
          endpoints.sprint.atualizarSprint(
            builder,
            SprintUpdateRequest(
              id: second.id!,
              nome: second.nome,
              dataInicio: first.dataFim,
              dataFim: first.dataFim.add(const Duration(days: 2)),
            ),
          ),
          fails(SprintErroCodigo.periodoSobreposto),
        );
      });

      test(
        'concorrência: lote idempotente e criação de filha preservam herança',
        () async {
          final root = await demand();
          final target = await sprint(0);
          await Future.wait([
            link(target, [root.id!]),
            link(target, [root.id!]),
            demand(parent: root),
          ]);
          final children = await Demanda.db.find(
            builder.build(),
            where: (t) => t.demandaPaiId.equals(root.id!),
          );
          final result = await links(target);
          expect(result, hasLength(2));
          expect(result.map((v) => v.demandaId).toSet(), {
            root.id,
            children.single.id,
          });
        },
      );

      test(
        'concorrência com cancelamento/reabertura mantém lote atômico',
        () async {
          final roots = [await demand(), await demand()];
          final target = await sprint(0);
          final outcomes = await Future.wait<Object>([
            link(
              target,
              roots.map((d) => d.id!),
            ).then<Object>((r) => r).catchError((Object e) => e),
            endpoints.sprint
                .cancelarSprint(builder, target.id!)
                .then<Object>((r) => r),
          ]);
          final count = (await links(target)).length;
          expect(count == 0 || count == 2, isTrue);
          expect(
            outcomes.first is List<SprintDemanda> ||
                outcomes.first is SprintException,
            isTrue,
          );
          await endpoints.sprint.reabrirSprint(builder, target.id!);
          expect(await link(target, roots.map((d) => d.id!)), hasLength(2));
        },
      );

      test(
        'benchmark real: legado vs lote, resposta SQL atrasada 500 ms',
        () async {
          final port = Platform.environment['TEMDAS_SPR_PROXY_CONTROL_PORT'];
          if (port == null) return;
          final roots = <Demanda>[for (var i = 0; i < 6; i++) await demand()];
          for (var i = 0; i < 4; i++) {
            await demand(parent: roots.first);
          }
          final historical = await sprint(-100);
          await link(historical, roots.map((d) => d.id!));
          await Sprint.db.updateById(
            builder.build(),
            historical.id!,
            columnValues: (t) => [t.status(SprintStatus.concluida)],
          );
          final legacyTarget = await sprint(0);
          final bulkTarget = await sprint(10);
          final measurements = <Map<String, Object>>[];
          Future<void> delay(int ms) async {
            final http = HttpClient();
            try {
              final req = await http.getUrl(
                Uri.parse('http://127.0.0.1:$port/delay?ms=$ms'),
              );
              final res = await req.close();
              await res.drain<void>();
              expect(res.statusCode, 200);
            } finally {
              http.close(force: true);
            }
          }

          Future<void> measure(String name, Sprint target, bool legacy) async {
            final session = _MeasuredSession(builder.build());
            final watch = Stopwatch()..start();
            // Match the production RPC's single DB owner lookup, without fake JWT
            // network services or any access to production credentials.
            await Usuario.db.findById(session, owner.id!);
            final service = SprintDemandaService();
            final result = await session.db.transaction((tx) async {
              if (!legacy) {
                return service.vincularArvores(
                  session,
                  sprintId: target.id!,
                  demandaIds: roots.map((d) => d.id!),
                  usuarioId: owner.id!,
                  transaction: tx,
                );
              }
              // The exact previous outer algorithm, using unchanged single-tree
              // service code: one global lock + target read, then sequential roots.
              await service.bloquearCicloDeVida(session, tx);
              await Sprint.db.findById(
                session,
                target.id!,
                transaction: tx,
                lockMode: LockMode.forUpdate,
              );
              return <SprintDemanda>[
                for (final d in roots)
                  ...await service.vincularArvore(
                    session,
                    sprintId: target.id!,
                    demandaId: d.id!,
                    usuarioId: owner.id!,
                    transaction: tx,
                  ),
              ];
            });
            watch.stop();
            expect(result, hasLength(10));
            measurements.add({
              'case': name,
              'queries': session.queries,
              'elapsed_ms': watch.elapsedMilliseconds,
              'query_ms': session.queryTime.inMilliseconds,
            });
            if (!legacy) {
              expect(session.queries, lessThanOrEqualTo(8));
              expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
            }
            await session.close();
          }

          try {
            await delay(500);
            await measure('legacy_insert', legacyTarget, true);
            await measure('legacy_repeat', legacyTarget, true);
            await measure('bulk_insert', bulkTarget, false);
            await measure('bulk_repeat', bulkTarget, false);
          } finally {
            await delay(0);
          }
          expect(measurements[0]['queries'], 56);
          expect(measurements[1]['queries'], 46);
          expect(measurements[2]['queries'], 8);
          expect(measurements[3]['queries'], 7);
          final report = {
            'postgres': '17.11',
            'serverpod': '3.4.11',
            'response_delay_ms': 500,
            'production_access': false,
            'measurements': measurements,
          };
          stdout.writeln('SPR_BULK_BENCHMARK ${jsonEncode(report)}');
          final output = Platform.environment['TEMDAS_SPR_BENCHMARK_REPORT'];
          if (output != null) {
            File(output).writeAsStringSync('${jsonEncode(report)}\n');
          }
        },
        timeout: const Timeout(Duration(minutes: 3)),
        skip: Platform.environment['TEMDAS_SPR_PROXY_CONTROL_PORT'] == null
            ? 'Opt in using TEMDAS_SPR_BENCHMARK=1 in disposable runner'
            : false,
      );
    },
    applyMigrations: false,
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
