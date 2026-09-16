import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
import 'package:temdas/view/widgets/demanda_tree.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  for (final alterarRaiz in [true, false]) {
    testWidgets(
      'status da ${alterarRaiz ? 'raiz' : 'filha'} mantém quadro, expansão, scroll e interação dos outros cards',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final mae = demandaFixture(id: 1, titulo: 'Mãe');
        final filha = demandaFixture(id: 2, demandaPaiId: 1, titulo: 'Filha');
        final independente = demandaFixture(id: 3, titulo: 'Independente');
        final demandas = [
          mae,
          filha,
          independente,
          for (var id = 4; id <= 15; id++) demandaFixture(id: id),
        ];
        final repository = FakeDemandaRepository(demandas: demandas);
        final vm = DemandasViewModel(repository: repository);
        addTearDown(vm.dispose);
        await tester.pumpWidget(MaterialApp(home: DemandasPage(viewModel: vm)));
        await tester.pumpAndSettle();
        for (final titulo in ['Mãe', 'Filha', 'Independente']) {
          await tester.ensureVisible(find.text(titulo));
          await tester.tap(find.text(titulo));
          await tester.pumpAndSettle();
        }

        final scrollVertical = _scroll(tester, Axis.vertical);
        final scrollHorizontal = _scroll(tester, Axis.horizontal);
        scrollVertical.position.jumpTo(120);
        scrollHorizontal.position.jumpTo(180);
        await tester.pumpAndSettle();
        final quadro = tester.element(find.byType(DemandaTree));
        final cardIndependente = tester.element(_card(3));
        final alvo = alterarRaiz ? mae : filha;
        final respostaA = Completer<backend.Demanda>();
        repository.respostaAlterarStatusPendente = respostaA;
        final selecionarA = tester
            .widget<DemandaCard>(_card(alvo.id!))
            .onAlterarStatus;

        selecionarA(backend.DemandaStatus.emAndamento);
        selecionarA(backend.DemandaStatus.emAndamento);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(repository.chamadasAlterarStatus, 1);
        expect(repository.chamadasListar, 1);
        expect(vm.demandasEmProcessamento, {alvo.id});
        expect(vm.carregando, isFalse);
        expect(tester.element(find.byType(DemandaTree)), same(quadro));
        expect(tester.element(_card(3)), same(cardIndependente));
        expect(
          tester.widget<DemandaCard>(_card(alvo.id!)).acoesHabilitadas,
          isFalse,
        );
        expect(
          tester.widget<DemandaCard>(_card(alvo.id!)).emProcessamento,
          isTrue,
        );
        final outro = tester.widget<DemandaCard>(_card(3));
        expect(outro.acoesHabilitadas, isTrue);
        expect(outro.emProcessamento, isFalse);
        expect(
          tester
              .widget<PopupMenuButton<backend.DemandaStatus>>(
                find.byKey(const ValueKey('status-demanda-3')),
              )
              .enabled,
          isTrue,
        );
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('concluir-demanda-3')),
              )
              .onPressed,
          isNotNull,
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.descendant(
            of: _card(alvo.id!),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        expect(_scroll(tester, Axis.vertical), same(scrollVertical));
        expect(_scroll(tester, Axis.horizontal), same(scrollHorizontal));
        expect(scrollVertical.position.pixels, 120);
        expect(scrollHorizontal.position.pixels, 180);

        // Uma segunda ação real da página pode prosseguir sem esperar A.
        final respostaB = Completer<backend.Demanda>();
        repository.respostaAlterarStatusPendente = respostaB;
        outro.onAlterarStatus(backend.DemandaStatus.pausada);
        await tester.pump();
        expect(repository.chamadasAlterarStatus, 2);
        expect(vm.demandasEmProcessamento, {alvo.id, 3});
        final atualizadaB = independente.copyWith(
          status: backend.DemandaStatus.pausada,
        );
        respostaB.complete(atualizadaB);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(vm.demandasEmProcessamento, {alvo.id});
        expect(tester.widget<DemandaCard>(_card(3)).acoesHabilitadas, isTrue);

        final atualizadaA = alvo.copyWith(
          status: backend.DemandaStatus.emAndamento,
        );
        respostaA.complete(atualizadaA);
        await tester.pumpAndSettle();

        expect(repository.chamadasListar, 1);
        expect(vm.demandasEmProcessamento, isEmpty);
        expect(vm.demandas[alterarRaiz ? 0 : 1], same(atualizadaA));
        expect(
          vm.demandas[alterarRaiz ? 1 : 0],
          same(alterarRaiz ? filha : mae),
        );
        expect(vm.demandas[2], same(atualizadaB));
        for (var index = 3; index < demandas.length; index++) {
          expect(vm.demandas[index], same(demandas[index]));
        }
        final coluna = find.byKey(
          ValueKey('demanda-coluna-${alterarRaiz ? 'emAndamento' : 'aberta'}'),
        );
        for (final id in [1, 2]) {
          expect(
            find.descendant(of: coluna, matching: _card(id)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: _card(id), matching: find.text('ID: $id')),
            findsOneWidget,
          );
        }
        expect(
          find.descendant(of: _card(3), matching: find.text('ID: 3')),
          findsOneWidget,
        );
        expect(tester.element(find.byType(DemandaTree)), same(quadro));
        expect(_scroll(tester, Axis.vertical), same(scrollVertical));
        expect(_scroll(tester, Axis.horizontal), same(scrollHorizontal));
        expect(scrollVertical.position.pixels, 120);
        expect(scrollHorizontal.position.pixels, 180);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'erro e nova tentativa preservam o quadro e o scroll horizontal',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final alvo = demandaFixture(titulo: 'Alvo');
      final repository = FakeDemandaRepository(demandas: [alvo]);
      final vm = DemandasViewModel(repository: repository);
      addTearDown(vm.dispose);
      await tester.pumpWidget(MaterialApp(home: DemandasPage(viewModel: vm)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alvo'));
      await tester.pumpAndSettle();
      final quadro = tester.element(find.byType(DemandaTree));
      final horizontal = _scroll(tester, Axis.horizontal);
      horizontal.position.jumpTo(150);
      await tester.pumpAndSettle();
      final falha = Completer<backend.Demanda>();
      repository.respostaAlterarStatusPendente = falha;
      final primeira = vm.concluirDemanda(alvo);
      falha.completeError(StateError('Falha temporária'));
      expect(await primeira, isFalse);
      await tester.pumpAndSettle();

      expect(tester.element(find.byType(DemandaTree)), same(quadro));
      expect(_scroll(tester, Axis.horizontal), same(horizontal));
      expect(horizontal.position.pixels, 150);
      expect(
        find.textContaining('Não foi possível alterar o status'),
        findsOneWidget,
      );

      final resposta = Completer<backend.Demanda>();
      repository.respostaAlterarStatusPendente = resposta;
      final segunda = vm.concluirDemanda(alvo);
      await tester.pump();
      expect(tester.element(find.byType(DemandaTree)), same(quadro));
      expect(_scroll(tester, Axis.horizontal), same(horizontal));
      expect(horizontal.position.pixels, 150);
      resposta.complete(alvo.copyWith(status: backend.DemandaStatus.concluida));
      expect(await segunda, isTrue);
      await tester.pumpAndSettle();
      expect(tester.element(find.byType(DemandaTree)), same(quadro));
      expect(horizontal.position.pixels, 150);
      expect(
        find.descendant(of: _card(1), matching: find.text('ID: 1')),
        findsOneWidget,
      );
      expect(repository.chamadasListar, 1);
    },
  );

  testWidgets(
    'editar mantém o quadro montado e bloqueia apenas o card editado',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final alvo = demandaFixture(id: 1, titulo: 'Alvo');
      final outra = demandaFixture(id: 2, titulo: 'Outra');
      final resposta = Completer<backend.Demanda>();
      final repository = FakeDemandaRepository(demandas: [alvo, outra])
        ..respostaAtualizarPendente = resposta;
      final vm = DemandasViewModel(repository: repository);
      addTearDown(vm.dispose);
      await tester.pumpWidget(MaterialApp(home: DemandasPage(viewModel: vm)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alvo'));
      await tester.pumpAndSettle();
      final quadro = tester.element(find.byType(DemandaTree));

      tester.widget<DemandaCard>(_card(1)).onEditar();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('editar-demanda-titulo')),
        'Editada',
      );
      await tester.tap(find.byKey(const ValueKey('salvar-edicao-demanda')));
      await tester.pump();

      expect(tester.element(find.byType(DemandaTree)), same(quadro));
      expect(vm.demandasEmProcessamento, {1});
      expect(vm.carregando, isFalse);
      expect(tester.widget<DemandaCard>(_card(1)).acoesHabilitadas, isFalse);
      expect(tester.widget<DemandaCard>(_card(2)).acoesHabilitadas, isTrue);
      expect(tester.widget<DemandaCard>(_card(2)).emProcessamento, isFalse);
      resposta.complete(alvo.copyWith(titulo: 'Editada'));
      await tester.pumpAndSettle();

      expect(repository.chamadasListar, 1);
      expect(vm.demandas.last, same(outra));
      expect(tester.element(find.byType(DemandaTree)), same(quadro));
      expect(find.text('Editada'), findsOneWidget);
      expect(
        find.descendant(of: _card(1), matching: find.text('ID: 1')),
        findsOneWidget,
      );
    },
  );
}

Finder _card(int id) => find.byKey(PageStorageKey('demanda-expansao-$id'));

ScrollableState _scroll(WidgetTester tester, Axis axis) =>
    tester.state<ScrollableState>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            axisDirectionToAxis(widget.axisDirection) == axis,
      ),
    );
