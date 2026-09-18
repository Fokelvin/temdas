import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
import 'package:temdas/view/widgets/demanda_tree.dart';
import 'package:temdas/view/widgets/tempo_comparacao.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  for (final idAlvo in [1, 2, 3]) {
    testWidgets(
      'tempo no nível $idAlvo atualiza ancestrais sem desmontar, recolher ou rolar o quadro',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final demandas = [
          demandaFixture(id: 1, titulo: 'Mãe', tempoExecutadoMinutos: 30),
          demandaFixture(
            id: 2,
            titulo: 'Filha',
            demandaPaiId: 1,
            tempoExecutadoMinutos: 60,
          ),
          demandaFixture(
            id: 3,
            titulo: 'Neta',
            demandaPaiId: 2,
            tempoExecutadoMinutos: 30,
          ),
          demandaFixture(
            id: 4,
            titulo: 'Independente',
            status: backend.DemandaStatus.emAndamento,
            tempoExecutadoMinutos: 15,
          ),
          for (var id = 5; id <= 15; id++) demandaFixture(id: id),
        ];
        final repository = FakeDemandaRepository(demandas: demandas);
        final registros = FakeRegistroTempoRepository();
        final vm = DemandasViewModel(
          repository: repository,
          registroTempoRepository: registros,
        );
        addTearDown(vm.dispose);
        await tester.pumpWidget(MaterialApp(home: DemandasPage(viewModel: vm)));
        await tester.pumpAndSettle();
        for (final demanda in [
          demandas[3],
          demandas[0],
          demandas[1],
          demandas[2],
        ]) {
          await _expandirDemanda(tester, demanda.id!);
          await tester.pumpAndSettle();
        }

        void verificarTotal(int id, int esperado) {
          expect(
            tester.widget<DemandaCard>(_card(id)).tempoExecutadoTotalMinutos,
            esperado,
          );
          final comparacao = tester.widget<TempoComparacao>(
            find.descendant(
              of: _card(id),
              matching: find.byType(TempoComparacao),
            ),
          );
          expect(comparacao.executadoMinutos, esperado);
          expect(comparacao.estimadoMinutos, 60);
          expect(
            find.descendant(of: _card(id), matching: find.text('ID: $id')),
            findsOneWidget,
          );
        }

        verificarTotal(1, 120);
        verificarTotal(2, 90);
        verificarTotal(3, 30);
        verificarTotal(4, 15);

        final vertical = _scroll(tester, Axis.vertical);
        final horizontal = _scroll(tester, Axis.horizontal);
        vertical.position.jumpTo(120);
        horizontal.position.jumpTo(180);
        await tester.pumpAndSettle();
        final quadro = tester.element(find.byType(DemandaTree));
        final independente = tester.element(_card(4));
        final posicaoIndependente = tester.getRect(_card(4));
        final barra = find.byKey(const ValueKey('demandas-quadro-scrollbar'));
        final controller = tester.widget<Scrollbar>(barra).controller;

        void verificarEstabilidade() {
          expect(tester.element(find.byType(DemandaTree)), same(quadro));
          expect(tester.element(_card(4)), same(independente));
          expect(tester.getRect(_card(4)), posicaoIndependente);
          expect(_scroll(tester, Axis.vertical), same(vertical));
          expect(_scroll(tester, Axis.horizontal), same(horizontal));
          expect(vertical.position.pixels, 120);
          expect(horizontal.position.pixels, 180);
          expect(tester.widget<Scrollbar>(barra).controller, same(controller));
          expect(vm.carregando, isFalse);
          expect(vm.envioGlobalEmAndamento, isFalse);
          for (final id in [1, 2, 3, 4]) {
            expect(
              find.descendant(of: _card(id), matching: find.text('ID: $id')),
              findsOneWidget,
            );
          }
        }

        final respostaRegistro = Completer<backend.RegistroTempo>();
        final respostaBusca = Completer<backend.Demanda?>();
        registros.respostaRegistrarPendente = respostaRegistro;
        repository.respostaBuscarPendente = respostaBusca;
        tester.widget<DemandaCard>(_card(idAlvo)).onLancarTempo!();
        await tester.pumpAndSettle();
        await _preencherIntervalo(tester);
        await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        verificarEstabilidade();
        expect(vm.demandasEmProcessamento, {idAlvo});
        expect(repository.idsBuscados, isEmpty);
        for (final id in [1, 2, 3, 4]) {
          final card = tester.widget<DemandaCard>(_card(id));
          expect(card.emProcessamento, id == idAlvo);
          expect(card.acoesHabilitadas, id != idAlvo);
        }
        // O refresh da demanda também exibe o indicador global; o card mantém
        // seu indicador local para bloquear somente as ações daquela demanda.
        expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
        expect(
          find.descendant(
            of: _card(idAlvo),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );

        respostaRegistro.complete(
          backend.RegistroTempo(
            id: 1,
            demandaId: idAlvo,
            inicioEm: DateTime.utc(2026),
            duracaoMinutos: 90,
            criadoEm: DateTime.utc(2026),
          ),
        );
        await tester.pump();
        expect(repository.idsBuscados, [idAlvo]);
        expect(vm.demandasEmProcessamento, {idAlvo});
        verificarEstabilidade();
        final original = demandas[idAlvo - 1];
        final atualizada = original.copyWith(
          tempoExecutadoMinutos: original.tempoExecutadoMinutos + 90,
        );
        respostaBusca.complete(atualizada);
        await tester.pumpAndSettle();
        verificarEstabilidade();
        verificarTotal(1, 210);
        verificarTotal(2, idAlvo == 1 ? 90 : 180);
        verificarTotal(3, idAlvo == 3 ? 120 : 30);
        verificarTotal(4, 15);
        expect(
          find.descendant(
            of: _card(1),
            matching: find.text('Média · Est. 1 h · Real. 3,5 h'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _card(1),
            matching: find.text('Executado: 3 h 30 min'),
          ),
          findsOneWidget,
        );
        for (var index = 0; index < demandas.length; index++) {
          expect(
            vm.demandas[index],
            same(index == idAlvo - 1 ? atualizada : demandas[index]),
          );
        }
        expect(repository.chamadasListar, 1);
        expect(repository.idsBuscados, [idAlvo]);
        expect(registros.chamadasRegistrar, 1);
        expect(registros.ultimaDuracaoMinutos, 90);
        expect(vm.demandasEmProcessamento, isEmpty);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Tempo registrado com sucesso.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _preencherIntervalo(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('log-time-inicio-hora')),
    '09',
  );
  await tester.enterText(
    find.byKey(const ValueKey('log-time-inicio-minuto')),
    '00',
  );
  await tester.enterText(find.byKey(const ValueKey('log-time-fim-hora')), '10');
  await tester.enterText(
    find.byKey(const ValueKey('log-time-fim-minuto')),
    '30',
  );
}

Finder _card(int id) => find.byKey(PageStorageKey('demanda-expansao-$id'));

Future<void> _expandirDemanda(WidgetTester tester, int id) async {
  final card = _card(id);
  final tile = find.descendant(of: card, matching: find.byType(ExpansionTile));
  await tester.ensureVisible(tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

ScrollableState _scroll(WidgetTester tester, Axis axis) =>
    tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(
              axis == Axis.vertical
                  ? const ValueKey('demandas-pagina-scroll')
                  : const ValueKey('demandas-quadro-status'),
            ),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  axisDirectionToAxis(widget.axisDirection) == axis,
            ),
          )
          .first,
    );
