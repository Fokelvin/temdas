import 'package:temdas_backend_server/src/auth/supabase_auth_service.dart';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/authenticated_test_user.dart';

void main() {
  withServerpod('Pacote 4 persistência e autorização', (builder, endpoints) {
    setUp(() => installAal2TestUser(builder, 'pacote4-owner'));
    tearDown(clearAal2TestUser);
    Future<Demanda> criar({int? pai}) => endpoints.demanda.criarDemanda(
      builder,
      DemandaCreateRequest(
        titulo: 'Pacote 4',
        tempoEstimadoMinutos: 30,
        demandaPaiId: pai,
      ),
    );
    Future<RegistroTempo> tempo(int demandaId, int minuto, String? texto) =>
        endpoints.registroTempo.registrarTempo(
          builder,
          RegistroTempoCreateRequest(
            demandaId: demandaId,
            inicioEm: DateTime.utc(2026, 10, 1, 9, minuto),
            duracaoMinutos: 30,
            observacao: texto,
          ),
        );

    test(
      'anotações persistem, editam com data e excluem logicamente',
      () async {
        final demanda = await criar();
        final primeira = await endpoints.anotacaoDemanda.criar(
          builder,
          demanda.id!,
          ' primeiro\ntexto ',
        );
        final segunda = await endpoints.anotacaoDemanda.criar(
          builder,
          demanda.id!,
          'segundo',
        );
        expect(
          (await endpoints.anotacaoDemanda.listar(
            builder,
            demanda.id!,
          )).map((a) => a.id),
          [segunda.id, primeira.id],
        );
        final editada = await endpoints.anotacaoDemanda.editar(
          builder,
          primeira.id!,
          'editada',
        );
        expect(editada.editadoEm, isNotNull);
        expect(editada.criadoEm, primeira.criadoEm);
        expect(editada.autorId, demanda.usuarioId);
        await endpoints.anotacaoDemanda.excluir(builder, primeira.id!);
        expect(
          await endpoints.anotacaoDemanda.listar(builder, demanda.id!),
          hasLength(1),
        );
        final arquivada = await AnotacaoDemanda.db.findById(
          builder.build(),
          primeira.id!,
        );
        expect(arquivada!.excluidoEm, isNotNull);
        expect(arquivada.conteudo, 'editada');
        await expectLater(
          endpoints.anotacaoDemanda.editar(builder, primeira.id!, 'não'),
          throwsException,
        );
      },
    );
    test(
      'mãe e filhas têm históricos separados; status terminal não bloqueia anotações',
      () async {
        final mae = await criar();
        final filha = await criar(pai: mae.id);
        await endpoints.demanda.concluirDemandaEmCascata(builder, mae.id!);
        await endpoints.anotacaoDemanda.criar(
          builder,
          mae.id!,
          'mãe concluída',
        );
        await endpoints.anotacaoDemanda.criar(
          builder,
          filha.id!,
          'filha concluída',
        );
        expect(
          (await endpoints.anotacaoDemanda.listar(
            builder,
            mae.id!,
          )).single.conteudo,
          'mãe concluída',
        );
        final cancelada = await criar();
        await endpoints.demanda.alterarStatusDemanda(
          builder,
          cancelada.id!,
          DemandaStatus.cancelada,
          motivoCancelamento: 'teste',
        );
        expect(
          (await endpoints.anotacaoDemanda.criar(
            builder,
            cancelada.id!,
            'cancelada',
          )).conteudo,
          'cancelada',
        );
      },
    );
    test(
      'owner diferente não consulta nem altera anotações ou observações',
      () async {
        final demanda = await criar();
        final anotacao = await endpoints.anotacaoDemanda.criar(
          builder,
          demanda.id!,
          'privada',
        );
        final registro = await tempo(demanda.id!, 0, 'privada');
        await installAal2TestUser(builder, 'pacote4-other');
        await expectLater(
          endpoints.anotacaoDemanda.listar(builder, demanda.id!),
          throwsException,
        );
        await expectLater(
          endpoints.anotacaoDemanda.criar(builder, demanda.id!, 'não'),
          throwsException,
        );
        await expectLater(
          endpoints.anotacaoDemanda.editar(builder, anotacao.id!, 'não'),
          throwsException,
        );
        await expectLater(
          endpoints.anotacaoDemanda.excluir(builder, anotacao.id!),
          throwsException,
        );
        await expectLater(
          endpoints.registroTempo.atualizarObservacao(
            builder,
            registro.id!,
            'não',
          ),
          throwsException,
        );
      },
    );
    test(
      'autoria é validada independentemente do ownership da demanda',
      () async {
        final demanda = await criar();
        final outro = await Usuario.db.insertRow(
          builder.build(),
          Usuario(
            supabaseUserId: 'autor-outro',
            createdAt: DateTime.now().toUtc(),
          ),
        );
        final anotacao = await AnotacaoDemanda.db.insertRow(
          builder.build(),
          AnotacaoDemanda(
            demandaId: demanda.id!,
            autorId: outro.id!,
            conteudo: 'somente consulta',
            criadoEm: DateTime.now().toUtc(),
          ),
        );
        expect(
          await endpoints.anotacaoDemanda.listar(builder, demanda.id!),
          hasLength(1),
        );
        await expectLater(
          endpoints.anotacaoDemanda.editar(builder, anotacao.id!, 'não'),
          throwsException,
        );
        await expectLater(
          endpoints.anotacaoDemanda.excluir(builder, anotacao.id!),
          throwsException,
        );
      },
    );
    test('AAL1 é negado pelos novos endpoints', () async {
      final demanda = await criar();
      final registro = await tempo(demanda.id!, 0, 'A');
      final usuario = (await Usuario.db.findById(
        builder.build(),
        demanda.usuarioId,
      ))!;
      setUsuarioResolverForTesting(
        (_) async =>
            AuthenticatedUsuario(usuario, usuario.supabaseUserId, 'aal1'),
      );
      await expectLater(
        endpoints.anotacaoDemanda.listar(builder, demanda.id!),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        endpoints.anotacaoDemanda.criar(builder, demanda.id!, 'não'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        endpoints.anotacaoDemanda.editar(builder, 1, 'não'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        endpoints.anotacaoDemanda.excluir(builder, 1),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        endpoints.registroTempo.atualizarObservacao(
          builder,
          registro.id!,
          'não',
        ),
        throwsA(isA<AuthException>()),
      );
    });
    test(
      'observação isolada preserva intervalos, total e demanda terminal',
      () async {
        final demanda = await criar();
        final registro = await tempo(demanda.id!, 0, 'A');
        await endpoints.demanda.alterarStatusDemanda(
          builder,
          demanda.id!,
          DemandaStatus.concluida,
        );
        final antes = (await endpoints.demanda.buscarDemandaPorId(
          builder,
          demanda.id!,
        ))!;
        final atualizado = await endpoints.registroTempo.atualizarObservacao(
          builder,
          registro.id!,
          ' nota\ncompleta ',
        );
        expect(atualizado.inicioEm, registro.inicioEm);
        expect(atualizado.duracaoMinutos, registro.duracaoMinutos);
        expect(atualizado.criadoEm, registro.criadoEm);
        expect(atualizado.demandaId, registro.demandaId);
        expect(atualizado.observacao, ' nota\ncompleta ');
        expect(
          (await endpoints.demanda.buscarDemandaPorId(
            builder,
            demanda.id!,
          ))!.toJson(),
          antes.toJson(),
        );
        expect(
          (await endpoints.registroTempo.atualizarObservacao(
            builder,
            registro.id!,
            null,
          )).observacao,
          isNull,
        );
      },
    );
    test(
      'uniões transacionais consecutivas preservam textos e removem absorvidos',
      () async {
        final demanda = await criar();
        await tempo(demanda.id!, 0, 'A');
        final b = await tempo(demanda.id!, 60, 'C');
        final resultado = await tempo(demanda.id!, 30, 'B');
        final registros = await endpoints.registroTempo
            .listarRegistrosTempoDaDemanda(builder, demanda.id!);
        expect(registros, hasLength(1));
        expect(resultado.duracaoMinutos, 90);
        expect(resultado.observacao, contains('A'));
        expect(resultado.observacoesOriginais!.map((o) => o.texto), [
          'A',
          'B',
          'C',
        ]);
        expect(resultado.observacao, contains('B'));
        expect(resultado.observacao, contains('C'));
        expect(await RegistroTempo.db.findById(builder.build(), b.id!), isNull);
        expect(
          (await endpoints.demanda.buscarDemandaPorId(
            builder,
            demanda.id!,
          ))!.tempoExecutadoMinutos,
          90,
        );
      },
    );
    test(
      'conflito aborta união e preserva todos os textos e registros',
      () async {
        final demanda = await criar();
        final outra = await criar();
        final original = await tempo(demanda.id!, 0, 'não perder');
        await tempo(outra.id!, 30, 'conflito');
        await expectLater(
          tempo(demanda.id!, 15, 'novo'),
          throwsA(isA<ConflitoHorarioException>()),
        );
        final preservado =
            (await endpoints.registroTempo.listarRegistrosTempoDaDemanda(
              builder,
              demanda.id!,
            )).single;
        expect(preservado.toJson(), original.toJson());
      },
    );
    test(
      'edição une observações e atualização isolada reinicia proveniência sem tocar horários',
      () async {
        final demanda = await criar();
        final a = await tempo(demanda.id!, 0, 'A');
        final c = await tempo(demanda.id!, 60, 'C');
        final unido = await endpoints.registroTempo.editarRegistroTempo(
          builder,
          RegistroTempoUpdateRequest(
            id: c.id!,
            inicioEm: DateTime.utc(2026, 10, 1, 9, 30),
            duracaoMinutos: 30,
            observacao: 'C editada',
          ),
        );
        expect(unido.duracaoMinutos, 60);
        expect(unido.observacao, contains('A'));
        expect(unido.observacao, contains('C editada'));
        expect(await RegistroTempo.db.findById(builder.build(), a.id!), isNull);
        final isolada = await endpoints.registroTempo.atualizarObservacao(
          builder,
          unido.id!,
          'substituída explicitamente',
        );
        expect(isolada.observacaoOrigens, isNull);
        final finalizada = await tempo(demanda.id!, 60, 'nova');
        expect(finalizada.observacao, contains('substituída explicitamente'));
        expect(finalizada.observacao, isNot(contains('C editada')));
        expect(finalizada.duracaoMinutos, 90);
      },
    );
    test(
      'cliente antigo pode reenviar arquivo legado intacto sem duplicar descrição',
      () async {
        final demanda = await criar();
        await Demanda.db.updateRow(
          builder.build(),
          demanda.copyWith(descricao: 'oficial', observacoes: 'arquivo legado'),
        );
        final editada = await endpoints.demanda.atualizarDemanda(
          builder,
          DemandaUpdateRequest(
            id: demanda.id!,
            titulo: demanda.titulo,
            descricao: 'oficial editada',
            status: demanda.status,
            prioridade: demanda.prioridade,
            tempoEstimadoMinutos: 30,
            observacoes: 'arquivo legado',
          ),
        );
        expect(editada.descricao, 'oficial editada');
        expect(editada.observacoes, 'arquivo legado');
        await expectLater(
          endpoints.demanda.atualizarDemanda(
            builder,
            DemandaUpdateRequest(
              id: demanda.id!,
              titulo: demanda.titulo,
              descricao: 'oficial editada',
              status: demanda.status,
              prioridade: demanda.prioridade,
              tempoEstimadoMinutos: 30,
              observacoes: 'tentativa de escrita',
            ),
          ),
          throwsException,
        );
      },
    );
    test(
      'projeção de origens persiste após reconsulta sem expor identidade interna',
      () async {
        final demanda = await criar();
        await tempo(demanda.id!, 0, 'mesmo texto');
        final unida = await tempo(demanda.id!, 0, 'mesmo texto');
        expect(unida.observacoesOriginais, hasLength(2));
        expect(unida.observacao, 'mesmo texto\n\nmesmo texto');
        final semAlteracao = await endpoints.registroTempo.atualizarObservacao(
          builder,
          unida.id!,
          unida.observacao,
        );
        expect(semAlteracao.observacoesOriginais, hasLength(2));
        final movida = await endpoints.registroTempo.editarRegistroTempo(
          builder,
          RegistroTempoUpdateRequest(
            id: unida.id!,
            inicioEm: DateTime.utc(2026, 10, 1, 10),
            duracaoMinutos: 30,
          ),
        );
        expect(movida.inicioEm, DateTime.utc(2026, 10, 1, 10));
        expect(
          movida.observacoesOriginais!.first.inicioEm,
          DateTime.utc(2026, 10, 1, 9),
        );
        final carregada =
            (await endpoints.registroTempo.listarRegistrosTempoDaDemanda(
              builder,
              demanda.id!,
            )).single;
        expect(carregada.observacoesOriginais!.map((o) => o.texto), [
          'mesmo texto',
          'mesmo texto',
        ]);
        expect(
          carregada.observacoesOriginais!.map((o) => o.inicioEm).toSet(),
          hasLength(1),
        );
        final periodo = await endpoints.registroTempo
            .listarRegistrosTempoPorPeriodo(
              builder,
              DateTime.utc(2026, 10, 1),
              DateTime.utc(2026, 10, 2),
            );
        expect(periodo.single.observacoesOriginais, hasLength(2));
        final seguinte = await tempo(demanda.id!, 30, 'seguinte');
        expect(seguinte.observacoesOriginais, hasLength(3));
      },
    );
    test(
      'editar horário sem alterar texto preserva o intervalo original anterior à união',
      () async {
        final demanda = await criar();
        await tempo(demanda.id!, 0, 'primeira');
        final outra = await tempo(demanda.id!, 60, 'segunda');
        final editada = await endpoints.registroTempo.editarRegistroTempo(
          builder,
          RegistroTempoUpdateRequest(
            id: outra.id!,
            inicioEm: DateTime.utc(2026, 10, 1, 9, 30),
            duracaoMinutos: 30,
          ),
        );
        expect(editada.duracaoMinutos, 60);
        expect(editada.observacoesOriginais!.map((o) => o.texto), [
          'primeira',
          'segunda',
        ]);
        expect(
          editada.observacoesOriginais!.last.inicioEm,
          DateTime.utc(2026, 10, 1, 10),
        );
        expect(
          editada.observacoesOriginais!.last.fimEm,
          DateTime.utc(2026, 10, 1, 10, 30),
        );
      },
    );
    test('campo legado de observações não aceita novas escritas', () async {
      await expectLater(
        endpoints.demanda.criarDemanda(
          builder,
          DemandaCreateRequest(
            titulo: 'legado',
            tempoEstimadoMinutos: 30,
            observacoes: 'use descrição',
          ),
        ),
        throwsException,
      );
      final demanda = await criar();
      await expectLater(
        endpoints.anotacaoDemanda.criar(builder, demanda.id!, '  '),
        throwsException,
      );
    });
  });
}
