import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/authenticated_test_user.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('To-dos pessoais', (session, endpoints) {
    final todo = endpoints.todo;
    final demandas = endpoints.demanda;

    Future<Demanda> criarDemanda(String titulo, {int? pai}) =>
        demandas.criarDemanda(
          session,
          DemandaCreateRequest(
            titulo: titulo,
            demandaPaiId: pai,
            tempoEstimadoMinutos: 30,
          ),
        );

    setUp(() => installAal2TestUser(session, 'todos-owner'));
    tearDown(clearAal2TestUser);

    test('valida AAL2, conteúdo, data e dimensões', () async {
      final card = await todo.criar(session, 'Linha 1\nLinha 2', null);
      await expectLater(todo.criar(session, ' \n ', null), throwsArgumentError);
      await expectLater(
        todo.alterarData(session, card.id!, '2026-02-30'),
        throwsArgumentError,
      );
      await expectLater(
        todo.alterarData(session, card.id!, '2026-11-11T15:00:00'),
        throwsArgumentError,
      );
      await expectLater(
        todo.redimensionar(session, card.id!, 199, 400),
        throwsArgumentError,
      );
      clearAal2TestUser();
      await expectLater(todo.listar(session), throwsA(isA<AuthException>()));
    });

    test('persiste linhas mistas e preserva a leitura legada', () async {
      final card = await todo.criar(session, 'Texto\nItem', null);
      expect(card.linhas, isNull);
      expect((await todo.listar(session)).single.conteudo, 'Texto\nItem');
      final linhas = [
        TodoLinha(
          id: 'texto',
          tipo: TodoTipoLinha.texto,
          texto: 'Texto',
          marcado: false,
        ),
        TodoLinha(
          id: 'item',
          tipo: TodoTipoLinha.checklist,
          texto: 'Item',
          marcado: true,
        ),
        TodoLinha(
          id: 'vazio',
          tipo: TodoTipoLinha.texto,
          texto: '',
          marcado: false,
        ),
      ];
      await todo.editarLinhas(session, card.id!, linhas);
      final salvo = (await todo.listar(session)).single;
      expect(
        salvo.linhas!.map((linha) => linha.toJson()),
        linhas.map((linha) => linha.toJson()),
      );
      expect(salvo.conteudo, 'Texto\nItem\n');
      expect(salvo.concluido, isFalse);
      await expectLater(
        todo.editarTexto(session, card.id!, 'Cliente anterior'),
        throwsStateError,
      );
      await expectLater(
        todo.editarLinhas(session, card.id!, [linhas.first, linhas.first]),
        throwsArgumentError,
      );

      await installAal2TestUser(session, 'todos-outro-owner');
      await expectLater(
        todo.editarLinhas(session, card.id!, linhas),
        throwsException,
      );
      expect(await todo.listar(session), isEmpty);
    });

    test('isola leitura, mutações, destino do arraste e vínculo', () async {
      final demanda = await criarDemanda('Demanda privada');
      final privado = await todo.criar(session, 'Privado', demanda.id);
      final id = privado.id!;

      await installAal2TestUser(session, 'todos-outro-owner');
      final proprio = await todo.criar(session, 'Próprio', null);
      expect((await todo.listar(session)).map((t) => t.id), [proprio.id]);
      await expectLater(todo.criar(session, 'X', demanda.id), throwsException);
      await expectLater(
        todo.vincular(session, proprio.id!, demanda.id),
        throwsException,
      );
      await expectLater(todo.editarTexto(session, id, 'X'), throwsException);
      await expectLater(todo.alterarData(session, id, null), throwsException);
      await expectLater(
        todo.alterarConclusao(session, id, true),
        throwsException,
      );
      await expectLater(todo.vincular(session, id, null), throwsException);
      await expectLater(
        todo.redimensionar(session, id, 320, 400),
        throwsException,
      );
      await expectLater(
        todo.mover(session, proprio.id!, id, false),
        throwsException,
      );
      await expectLater(
        todo.mover(session, id, proprio.id!, false),
        throwsException,
      );
      await todo.excluir(session, id);

      await installAal2TestUser(session, 'todos-owner');
      expect((await todo.listar(session)).single.conteudo, 'Privado');
    });

    test(
      'persiste campos, ordena por data e insere no topo da ordem manual',
      () async {
        final semData = await todo.criar(session, 'Sem data', null);
        final futuro = await todo.criar(session, 'Futuro', null);
        final hoje = await todo.criar(session, 'Hoje', null);
        final atrasado = await todo.criar(session, 'Atrasado', null);
        await todo.alterarData(session, futuro.id!, '2026-11-12');
        await todo.alterarData(session, hoje.id!, '2026-11-11');
        await todo.alterarData(session, atrasado.id!, '2026-11-10');
        expect((await todo.listar(session)).map((t) => t.id), [
          atrasado.id,
          hoje.id,
          futuro.id,
          semData.id,
        ]);

        await todo.mover(session, semData.id!, atrasado.id!, false);
        final novo = await todo.criar(session, 'Novo', null);
        final demanda = await criarDemanda('Vínculo');
        await todo.vincular(session, novo.id!, demanda.id);
        await todo.editarTexto(session, novo.id!, 'Editado\nem duas linhas');
        await todo.alterarData(session, novo.id!, '2026-11-13');
        await todo.redimensionar(session, novo.id!, 350, 420);
        await todo.alterarConclusao(session, novo.id!, true);

        final lista = await todo.listar(session);
        expect(lista.map((t) => t.id), [
          novo.id,
          semData.id,
          atrasado.id,
          hoje.id,
          futuro.id,
        ]);
        expect(lista.first.conteudo, 'Editado\nem duas linhas');
        expect(lista.first.data, '2026-11-13');
        expect(lista.first.demandaId, demanda.id);
        expect(lista.first.concluido, isTrue);
        expect(lista.first.largura, 350);
        expect(lista.first.altura, 420);

        await todo.alterarData(session, novo.id!, null);
        await todo.vincular(session, novo.id!, null);
        await todo.alterarConclusao(session, novo.id!, false);
        final reaberto = (await todo.listar(session)).first;
        expect(reaberto.concluido, isFalse);
        expect(reaberto.data, isNull);
        expect(reaberto.demandaId, isNull);
        await todo.excluir(session, novo.id!);
        expect(
          (await todo.listar(session)).map((t) => t.id),
          isNot(contains(novo.id)),
        );
      },
    );

    test(
      'mantém o To-do ao mover a Demanda entre Demandas e Backlog',
      () async {
        final demanda = await criarDemanda('Com To-do');
        final vinculado = await todo.criar(session, 'Cartão', demanda.id);
        for (final destino in [
          DemandaLocalizacao.backlog,
          DemandaLocalizacao.demandas,
        ]) {
          await demandas.alterarLocalizacao(session, demanda.id!, destino, []);
          final lista = await demandas.listarDemandas(
            session,
            localizacao: destino,
          );
          expect(lista.map((item) => item.id), contains(demanda.id));
          final card = (await todo.listar(session)).single;
          expect(card.id, vinculado.id);
          expect(card.demandaId, demanda.id);
          expect(card.conteudo, 'Cartão');
        }
      },
    );

    test(
      'preserva nos status e exclui só vínculos da árvore excluída',
      () async {
        final raiz = await criarDemanda('Raiz');
        final filha = await criarDemanda('Filha', pai: raiz.id);
        final independente = await todo.criar(session, 'Independente', null);
        final vinculado = await todo.criar(session, 'Vinculado', filha.id);
        await todo.alterarConclusao(session, vinculado.id!, true);

        for (final status in [
          DemandaStatus.concluida,
          DemandaStatus.aberta,
          DemandaStatus.cancelada,
        ]) {
          await demandas.alterarStatusDemanda(
            session,
            filha.id!,
            status,
            motivoCancelamento: status == DemandaStatus.cancelada
                ? 'Teste de cancelamento'
                : null,
          );
          final card = (await todo.listar(
            session,
          )).singleWhere((t) => t.id == vinculado.id);
          expect(card.demandaId, filha.id);
          expect(card.concluido, isTrue);
        }
        expect(await demandas.excluirArvoreDemanda(session, raiz.id!), isTrue);
        expect((await todo.listar(session)).map((t) => t.id), [
          independente.id,
        ]);
      },
    );
  });
}
