import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  final prefixo = 'teste-ordem-${DateTime.now().microsecondsSinceEpoch}';

  withServerpod('Ordem e movimentação de demandas', (
    sessionBuilder,
    endpoints,
  ) {
    Future<Demanda> criar(
      String nome, {
      int? pai,
      DemandaStatus status = DemandaStatus.aberta,
    }) async {
      final criada = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo $nome',
          demandaPaiId: pai,
          tempoEstimadoMinutos: 60,
        ),
      );
      if (status == DemandaStatus.aberta) return criada;
      return Demanda.db.updateRow(
        sessionBuilder.build(),
        criada.copyWith(
          status: status,
          concluidoEm: status == DemandaStatus.concluida
              ? DateTime.utc(2026, 1, 1)
              : null,
        ),
      );
    }

    Future<Demanda> ler(Demanda demanda) async =>
        (await endpoints.demanda.buscarDemandaPorId(
          sessionBuilder,
          demanda.id!,
        ))!;

    Future<Demanda> mover(
      Demanda demanda, {
      DemandaStatus? status,
      required int posicao,
    }) => endpoints.demanda.moverDemanda(
      sessionBuilder,
      DemandaMovimentacaoRequest(
        demandaId: demanda.id!,
        statusDestino: status ?? demanda.status,
        posicaoDestino: posicao,
      ),
    );

    Future<List<Demanda>> raizesDoTeste() async =>
        (await endpoints.demanda.listarDemandas(sessionBuilder))
            .where(
              (demanda) =>
                  demanda.titulo.startsWith(prefixo) &&
                  demanda.demandaPaiId == null,
            )
            .toList();

    tearDown(() async {
      await Demanda.db.deleteWhere(
        sessionBuilder.build(),
        where: (t) => t.titulo.like('$prefixo%'),
      );
    });

    test('reordena para cima, para baixo, início e fim', () async {
      final a = await criar('A');
      final b = await criar('B');
      final c = await criar('C');

      await mover(c, posicao: 0);
      expect((await raizesDoTeste()).map((d) => d.titulo).toList(), [
        c.titulo,
        a.titulo,
        b.titulo,
      ]);

      await mover(c, posicao: 2);
      expect((await raizesDoTeste()).map((d) => d.titulo).toList(), [
        a.titulo,
        b.titulo,
        c.titulo,
      ]);

      await mover(a, posicao: 99);
      expect((await raizesDoTeste()).map((d) => d.titulo).toList(), [
        b.titulo,
        c.titulo,
        a.titulo,
      ]);
    });

    test('move entre Aberta, Em andamento e Pausada', () async {
      final demanda = await criar('ativa');

      await mover(demanda, status: DemandaStatus.emAndamento, posicao: 0);
      expect((await ler(demanda)).status, DemandaStatus.emAndamento);
      await mover(
        demanda,
        status: DemandaStatus.pausada,
        posicao: 0,
      );
      expect((await ler(demanda)).status, DemandaStatus.pausada);
      await mover(demanda, status: DemandaStatus.aberta, posicao: 0);
      expect((await ler(demanda)).status, DemandaStatus.aberta);
    });

    test('reordena terminal, mas bloqueia entrada e saída', () async {
      final concluidaA = await criar(
        'concluida A',
        status: DemandaStatus.concluida,
      );
      final concluidaB = await criar(
        'concluida B',
        status: DemandaStatus.concluida,
      );
      await mover(concluidaB, posicao: 0);
      expect(
        (await raizesDoTeste())
            .where((d) => d.status == DemandaStatus.concluida)
            .map((d) => d.titulo),
        [
          concluidaB.titulo,
          concluidaA.titulo,
        ],
      );

      final ativa = await criar('ativa para terminal');
      await expectLater(
        mover(ativa, status: DemandaStatus.concluida, posicao: 0),
        throwsA(isA<MovimentacaoDemandaException>()),
      );
      expect((await ler(ativa)).status, DemandaStatus.aberta);
      await expectLater(
        mover(concluidaA, status: DemandaStatus.aberta, posicao: 0),
        throwsA(isA<MovimentacaoDemandaException>()),
      );
      expect((await ler(concluidaA)).status, DemandaStatus.concluida);
    });

    test('rejeita filha e preserva alteração em falha', () async {
      final pai = await criar('pai');
      final filha = await criar('filha', pai: pai.id);

      await expectLater(
        mover(filha, posicao: 0),
        throwsA(
          isA<MovimentacaoDemandaException>().having(
            (erro) => erro.codigo,
            'codigo',
            MovimentacaoDemandaErroCodigo.demandaFilha,
          ),
        ),
      );
      expect((await ler(filha)).ordem, isNull);

      await expectLater(
        mover(pai, status: DemandaStatus.cancelada, posicao: 0),
        throwsA(isA<MovimentacaoDemandaException>()),
      );
      expect((await ler(pai)).status, DemandaStatus.aberta);
    });
  });
}
