import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  for (final status in [
    backend.DemandaStatus.concluida,
    backend.DemandaStatus.cancelada,
  ]) {
    final acao = status == backend.DemandaStatus.concluida
        ? 'Reabrir'
        : 'Reativar';
    final chaveAcao = status == backend.DemandaStatus.concluida
        ? 'reabrir-demanda-1'
        : 'reativar-demanda-1';
    final chaveConfirmacao = status == backend.DemandaStatus.concluida
        ? 'reabrir-demanda-confirmar'
        : 'reativar-demanda-confirmar';

    testWidgets('$acao exige confirmação e envia Aberta', (tester) async {
      final alvo = demandaFixture(titulo: 'Alvo', status: status);
      final resposta = Completer<backend.Demanda>();
      final repository = FakeDemandaRepository(demandas: [alvo])
        ..respostaAlterarStatusPendente = resposta;
      final vm = await _abrir(tester, repository);

      await _abrirMenuAcoes(tester, 1);
      expect(find.text(acao), findsOneWidget);
      await tester.tap(find.byKey(ValueKey(chaveAcao)));
      await tester.pumpAndSettle();

      expect(find.text('$acao demanda?'), findsOneWidget);
      expect(
        find.text('A demanda voltará para o status Aberta.'),
        findsOneWidget,
      );
      expect(repository.chamadasAlterarStatus, 0);

      await tester.tap(find.byKey(ValueKey(chaveConfirmacao)));
      await tester.tap(find.byKey(ValueKey(chaveConfirmacao)));
      await tester.pump();
      expect(repository.chamadasAlterarStatus, 1);
      expect(
        repository.ultimaAlteracaoStatus?.status,
        backend.DemandaStatus.aberta,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      resposta.complete(alvo.copyWith(status: backend.DemandaStatus.aberta));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(vm.demandas.single.status, backend.DemandaStatus.aberta);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('demanda-coluna-aberta')),
          matching: find.byKey(const ValueKey('demanda-card-1')),
        ),
        findsOneWidget,
      );
      expect(repository.chamadasListar, 1);
    });

    testWidgets('$acao pode ser cancelada sem alterar a demanda', (
      tester,
    ) async {
      final alvo = demandaFixture(titulo: 'Alvo', status: status);
      final repository = FakeDemandaRepository(demandas: [alvo]);
      final vm = await _abrir(tester, repository);

      await _abrirMenuAcoes(tester, 1);
      await tester.tap(find.byKey(ValueKey(chaveAcao)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cancelar-dialogo-reabertura')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.chamadasAlterarStatus, 0);
      expect(vm.demandas.single.status, status);
    });

    testWidgets('$acao mantém o status quando o backend rejeita', (
      tester,
    ) async {
      final alvo = demandaFixture(titulo: 'Alvo', status: status);
      final resposta = Completer<backend.Demanda>();
      final repository = FakeDemandaRepository(demandas: [alvo])
        ..respostaAlterarStatusPendente = resposta;
      final vm = await _abrir(tester, repository);

      await _abrirMenuAcoes(tester, 1);
      await tester.tap(find.byKey(ValueKey(chaveAcao)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(chaveConfirmacao)));
      resposta.completeError(
        backend.TransicaoStatusException(
          codigo: backend.TransicaoStatusErroCodigo.demandaNaoEncontrada,
          mensagem: 'A demanda não está mais disponível.',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.byKey(const ValueKey('erro-dialogo-reabertura')),
        findsOneWidget,
      );
      expect(vm.demandas.single.status, status);
      expect(vm.demandasEmProcessamento, isEmpty);
    });
  }

  for (final status in [
    backend.DemandaStatus.aberta,
    backend.DemandaStatus.emAndamento,
    backend.DemandaStatus.pausada,
  ]) {
    testWidgets('status $status não exibe ação terminal', (tester) async {
      final demanda = demandaFixture(id: 1, status: status);
      var chamada = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DemandaCard(
              demanda: demanda,
              tempoExecutadoTotalMinutos: 0,
              onEditar: () {},
              onExcluir: () {},
              onAlterarStatus: (_) {},
              onConcluir: () {},
              onReabrir: () => chamada = true,
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining(demanda.titulo));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('acoes-demanda-1')));
      await tester.pumpAndSettle();

      expect(find.text('Reabrir'), findsNothing);
      expect(find.text('Reativar'), findsNothing);
      expect(chamada, isFalse);
    });
  }
}

Future<DemandasViewModel> _abrir(
  WidgetTester tester,
  FakeDemandaRepository repository,
) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final vm = DemandasViewModel(repository: repository);
  addTearDown(vm.dispose);
  await tester.pumpWidget(MaterialApp(home: DemandasPage(viewModel: vm)));
  await tester.pumpAndSettle();
  final alvo = find.textContaining('Alvo');
  await tester.ensureVisible(alvo);
  await tester.tap(alvo);
  await tester.pumpAndSettle();
  return vm;
}

Future<void> _abrirMenuAcoes(WidgetTester tester, int id) async {
  final menu = find.byKey(ValueKey('acoes-demanda-$id'));
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await tester.pumpAndSettle();
}
