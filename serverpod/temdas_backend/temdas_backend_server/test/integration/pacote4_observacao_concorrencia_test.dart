import 'dart:async';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/authenticated_test_user.dart';

void main() {
  // Conexões/transações reais independentes; dados sintéticos limpos no teardown.
  withServerpod('Observação e união concorrentes', (builder, endpoints) {
    int? owner;
    setUp(() async {
      await installAal2TestUser(builder, 'pacote4-concorrencia');
      owner = (await Usuario.db.findFirstRow(
        builder.build(),
        where: (t) => t.supabaseUserId.equals('pacote4-concorrencia'),
      ))!.id;
    });
    tearDown(() async {
      clearAal2TestUser();
      if (owner != null) {
        await Demanda.db.deleteWhere(
          builder.build(),
          where: (t) => t.usuarioId.equals(owner),
        );
        await Usuario.db.deleteWhere(
          builder.build(),
          where: (t) => t.id.equals(owner),
        );
      }
    });
    test(
      'edição aguarda mutex e união posterior preserva o texto confirmado',
      () async {
        final demanda = await endpoints.demanda.criarDemanda(
          builder,
          DemandaCreateRequest(
            titulo: 'concorrência sintética',
            tempoEstimadoMinutos: 30,
          ),
        );
        final registro = await endpoints.registroTempo.registrarTempo(
          builder,
          RegistroTempoCreateRequest(
            demandaId: demanda.id!,
            inicioEm: DateTime.utc(2026, 10, 1, 9),
            duracaoMinutos: 30,
            observacao: 'anterior',
          ),
        );
        final entrou = Completer<void>();
        final liberar = Completer<void>();
        final session = builder.build();
        final retencao = session.db.transaction((transaction) async {
          await session.db.unsafeQuery(
            "SELECT pg_advisory_xact_lock(hashtext('temdas.registros_tempo'))",
            transaction: transaction,
          );
          entrou.complete();
          await liberar.future;
        });
        await entrou.future;
        Future<RegistroTempo>? editada;
        Future<RegistroTempo>? unida;
        Future<void> aguardar(int quantidade) async {
          final limite = DateTime.now().add(const Duration(seconds: 3));
          while (DateTime.now().isBefore(limite)) {
            final result = await builder.build().db.unsafeQuery(
              "SELECT count(*) FROM pg_locks WHERE locktype='advisory' AND NOT granted",
            );
            if ((result.first[0] as int) >= quantidade) return;
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          fail('Operações não aguardaram o mutex da normalização.');
        }

        try {
          editada = endpoints.registroTempo.atualizarObservacao(
            builder,
            registro.id!,
            'edição confirmada',
          );
          await aguardar(1);
          unida = endpoints.registroTempo.registrarTempo(
            builder,
            RegistroTempoCreateRequest(
              demandaId: demanda.id!,
              inicioEm: DateTime.utc(2026, 10, 1, 9, 30),
              duracaoMinutos: 30,
              observacao: 'novo intervalo',
            ),
          );
          await aguardar(2);
        } finally {
          liberar.complete();
          await retencao;
          if (editada != null) await editada;
          if (unida != null) await unida;
        }
        final salvo =
            (await endpoints.registroTempo.listarRegistrosTempoDaDemanda(
              builder,
              demanda.id!,
            )).single;
        expect(salvo.observacao, contains('edição confirmada'));
        expect(salvo.observacao, contains('novo intervalo'));
        expect(salvo.observacao, isNot(contains('anterior')));
        expect(salvo.duracaoMinutos, 60);
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}
