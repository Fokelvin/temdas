import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  for (final status in [
    backend.DemandaStatus.aberta,
    backend.DemandaStatus.emAndamento,
    backend.DemandaStatus.pausada,
  ]) {
    testWidgets('card expandido altera normalmente para $status', (
      tester,
    ) async {
      final alvo = demandaFixture(
        titulo: 'Alvo',
        status: backend.DemandaStatus.concluida,
      );
      final resposta = Completer<backend.Demanda>();
      final repository = FakeDemandaRepository(demandas: [alvo])
        ..respostaAlterarStatusPendente = resposta;
      final vm = await _abrir(tester, repository);
      await _selecionar(tester, alvo.id!, status);
      expect(vm.alteracoesNormais, 1);
      expect(vm.conclusoes, 0);
      expect(repository.ultimaAlteracaoStatus?.status, status);
      expect(repository.chamadasAtualizar, 0);
      expect(find.byType(AlertDialog), findsNothing);
      resposta.complete(alvo.copyWith(status: status));
      await tester.pumpAndSettle();
      expect(vm.demandas.single.status, status);
      expect(repository.chamadasListar, 1);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('demanda-coluna-${status.name}')),
          matching: find.byKey(ValueKey('demanda-card-${alvo.id}')),
        ),
        findsOneWidget,
      );
    });
  }

  for (final via in ['menu', 'check']) {
    testWidgets('$via conclui pelo mesmo fluxo sem abrir diálogo adicional', (
      tester,
    ) async {
      final alvo = demandaFixture(titulo: 'Alvo');
      final filha = demandaFixture(id: 2, demandaPaiId: 1);
      final resposta = Completer<backend.Demanda>();
      final repository = FakeDemandaRepository(demandas: [alvo, filha])
        ..respostaAlterarStatusPendente = resposta;
      final vm = await _abrir(tester, repository);
      await _concluir(tester, via);
      expect(vm.conclusoes, 1);
      expect(vm.alteracoesNormais, 0);
      expect(repository.chamadasAlterarStatus, 1);
      expect(
        repository.ultimaAlteracaoStatus?.status,
        backend.DemandaStatus.concluida,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('concluir-demanda-1')),
            )
            .onPressed,
        isNull,
      );
      resposta.complete(alvo.copyWith(status: backend.DemandaStatus.concluida));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.chamadasConcluirEmCascata, 0);
      expect(vm.demandas.first.status, backend.DemandaStatus.concluida);
      expect(vm.demandas.last, filha);
      expect(find.text('ID: 1'), findsOneWidget);
    });

    for (final confirmar in [false, true]) {
      testWidgets(
        '$via trata descendentes ativos e ${confirmar ? 'confirma' : 'cancela'} cascata',
        (tester) async {
          final alvo = demandaFixture(titulo: 'Alvo');
          final filha = demandaFixture(id: 2, demandaPaiId: 1);
          final resposta = Completer<backend.Demanda>();
          final cascata = Completer<backend.Demanda>();
          final repository = FakeDemandaRepository(demandas: [alvo, filha])
            ..respostaAlterarStatusPendente = resposta
            ..respostaConcluirEmCascataPendente = cascata;
          final vm = await _abrir(tester, repository);
          await _concluir(tester, via);
          resposta.completeError(_descendentesAtivos());
          await tester.pumpAndSettle();
          expect(vm.conclusoes, 1);
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(find.textContaining('subdemandas ativas'), findsOneWidget);
          expect(find.textContaining('somente esta'), findsNothing);
          expect(repository.chamadasConcluirEmCascata, 0);
          expect(vm.demandas, [alvo, filha]);

          if (!confirmar) {
            await _tocar(tester, 'voltar-dialogo-status');
            expect(find.byType(AlertDialog), findsNothing);
            expect(vm.demandas, [alvo, filha]);
            expect(repository.chamadasConcluirEmCascata, 0);
          } else {
            await _confirmarDuasVezes(tester, 'confirmar-conclusao-cascata');
            expect(repository.chamadasConcluirEmCascata, 1);
            expect(repository.ultimoIdConclusaoEmCascata, 1);
            final concluida = alvo.copyWith(
              status: backend.DemandaStatus.concluida,
            );
            final filhaConcluida = filha.copyWith(
              status: backend.DemandaStatus.concluida,
            );
            repository.respostasListarPendentes.add(
              Completer<List<backend.Demanda>>()
                ..complete([concluida, filhaConcluida]),
            );
            cascata.complete(concluida);
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsNothing);
            expect(vm.demandas, [concluida, filhaConcluida]);
            expect(repository.chamadasConcluirEmCascata, 1);
          }
        },
      );
    }
  }

  for (final erro in [
    _descendentesAtivos(podeConcluir: false),
    backend.TransicaoStatusException(
      codigo: backend.TransicaoStatusErroCodigo.demandaNaoEncontrada,
      mensagem: 'Demanda não encontrada no backend.',
      podeConcluirEmCascata: true,
    ),
  ]) {
    testWidgets(
      'não oferece cascata sem código e permissão compatíveis: ${erro.codigo}',
      (tester) async {
        final alvo = demandaFixture(titulo: 'Alvo');
        final resposta = Completer<backend.Demanda>();
        final repository = FakeDemandaRepository(demandas: [alvo])
          ..respostaAlterarStatusPendente = resposta;
        await _abrir(tester, repository);
        await _concluir(tester, 'check');
        resposta.completeError(erro);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.widgetWithText(SnackBar, erro.mensagem), findsOneWidget);
        expect(repository.chamadasConcluirEmCascata, 0);
      },
    );
  }

  for (final filha in [false, true]) {
    testWidgets(
      'cancelamento de ${filha ? 'filha já cancelada' : 'folha'} exige motivo e confirmação',
      (tester) async {
        final alvo = demandaFixture(
          id: filha ? 2 : 1,
          demandaPaiId: filha ? 1 : null,
          titulo: 'Alvo',
          status: filha
              ? backend.DemandaStatus.cancelada
              : backend.DemandaStatus.aberta,
        );
        final demandas = [if (filha) demandaFixture(titulo: 'Mãe'), alvo];
        final resposta = Completer<backend.Demanda>();
        final repository = FakeDemandaRepository(demandas: demandas)
          ..respostaCancelarEmCascataPendente = resposta;
        final vm = await _abrir(tester, repository);
        await _selecionar(tester, alvo.id!, backend.DemandaStatus.cancelada);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('também serão cancelados'), findsOneWidget);
        expect(find.textContaining('somente esta'), findsNothing);
        expect(repository.chamadasCancelarEmCascata, 0);
        await _tocar(tester, 'confirmar-cancelamento');
        expect(find.text('Informe o motivo do cancelamento.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('motivo-cancelamento')),
          '  \n ',
        );
        await _tocar(tester, 'confirmar-cancelamento');
        expect(repository.chamadasCancelarEmCascata, 0);
        await tester.enterText(
          find.byKey(const ValueKey('motivo-cancelamento')),
          ' Mudança de planos ',
        );
        await _confirmarDuasVezes(tester, 'confirmar-cancelamento');
        expect(repository.chamadasCancelarEmCascata, 1);
        expect(repository.ultimoCancelamentoEmCascata, (
          id: alvo.id!,
          motivo: 'Mudança de planos',
        ));
        expect(vm.alteracoesNormais, 0);
        expect(vm.conclusoes, 0);
        resposta.complete(
          alvo.copyWith(
            status: backend.DemandaStatus.cancelada,
            motivoCancelamento: 'Mudança de planos',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(vm.demandas.last.motivoCancelamento, 'Mudança de planos');
        expect(repository.chamadasCancelarEmCascata, 1);
      },
    );
  }

  testWidgets(
    'cancelamento preserva motivo e mostra erro do backend no diálogo',
    (tester) async {
      final alvo = demandaFixture(titulo: 'Alvo');
      final resposta = Completer<backend.Demanda>();
      final repository = FakeDemandaRepository(demandas: [alvo])
        ..respostaCancelarEmCascataPendente = resposta;
      final vm = await _abrir(tester, repository);
      await _selecionar(tester, 1, backend.DemandaStatus.cancelada);
      await tester.enterText(
        find.byKey(const ValueKey('motivo-cancelamento')),
        'Motivo informado',
      );
      await _confirmarDuasVezes(tester, 'confirmar-cancelamento');
      resposta.completeError(
        backend.TransicaoStatusException(
          codigo: backend.TransicaoStatusErroCodigo.demandaNaoEncontrada,
          mensagem: 'A demanda não está mais disponível.',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('erro-dialogo-status')))
            .data,
        'A demanda não está mais disponível.',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('motivo-cancelamento')),
            )
            .controller!
            .text,
        'Motivo informado',
      );
      expect(vm.demandas, [alvo]);
      await _tocar(tester, 'voltar-dialogo-status');
      expect(repository.chamadasCancelarEmCascata, 1);
    },
  );

  testWidgets(
    'cancelamento aguarda outro patch sem mostrar um envio inexistente',
    (tester) async {
      final alvo = demandaFixture(id: 1, titulo: 'Alvo');
      final outra = demandaFixture(id: 2, titulo: 'Outra');
      final respostaLocal = Completer<backend.Demanda>();
      final respostaCascata = Completer<backend.Demanda>();
      final repository = FakeDemandaRepository(demandas: [alvo, outra])
        ..respostaAlterarStatusPendente = respostaLocal
        ..respostaCancelarEmCascataPendente = respostaCascata;
      final vm = await _abrir(tester, repository);
      final local = vm.alterarStatusDemanda(
        demanda: outra,
        status: backend.DemandaStatus.pausada,
      );
      tester
          .widget<PopupMenuButton<backend.DemandaStatus>>(
            find.byKey(const ValueKey('status-demanda-1')),
          )
          .onSelected!(backend.DemandaStatus.cancelada);
      await tester.pumpAndSettle();
      final dialogo = find.byType(AlertDialog);
      final confirmar = find.byKey(const ValueKey('confirmar-cancelamento'));
      expect(dialogo, findsOneWidget);
      expect(tester.widget<FilledButton>(confirmar).onPressed, isNull);
      expect(
        find.descendant(
          of: dialogo,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('voltar-dialogo-status')),
            )
            .onPressed,
        isNotNull,
      );
      respostaLocal.complete(
        outra.copyWith(status: backend.DemandaStatus.pausada),
      );
      expect(await local, isTrue);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(confirmar).onPressed, isNotNull);
      await tester.enterText(
        find.byKey(const ValueKey('motivo-cancelamento')),
        'Motivo',
      );
      await _confirmarDuasVezes(tester, 'confirmar-cancelamento');
      respostaCascata.complete(
        alvo.copyWith(
          status: backend.DemandaStatus.cancelada,
          motivoCancelamento: 'Motivo',
        ),
      );
      await tester.pumpAndSettle();
      expect(dialogo, findsNothing);
      expect(repository.chamadasListar, 2);
      expect(repository.chamadasCancelarEmCascata, 1);
    },
  );

  testWidgets('cliques repetidos não abrem dois diálogos de motivo', (
    tester,
  ) async {
    final alvo = demandaFixture(titulo: 'Alvo');
    final repository = FakeDemandaRepository(demandas: [alvo]);
    await _abrir(tester, repository);
    final selecionar = tester
        .widget<PopupMenuButton<backend.DemandaStatus>>(
          find.byKey(const ValueKey('status-demanda-1')),
        )
        .onSelected!;
    selecionar(backend.DemandaStatus.cancelada);
    selecionar(backend.DemandaStatus.cancelada);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await _tocar(tester, 'voltar-dialogo-status');
    expect(find.byType(AlertDialog), findsNothing);
    expect(repository.chamadasCancelarEmCascata, 0);
  });
}

backend.TransicaoStatusException _descendentesAtivos({
  bool podeConcluir = true,
}) => backend.TransicaoStatusException(
  codigo: backend.TransicaoStatusErroCodigo.descendentesAtivos,
  mensagem: 'A demanda possui descendentes ativos.',
  podeConcluirEmCascata: podeConcluir,
);

Future<_ViewModelObservada> _abrir(
  WidgetTester tester,
  FakeDemandaRepository repository,
) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final vm = _ViewModelObservada(repository: repository);
  addTearDown(vm.dispose);
  await tester.pumpWidget(MaterialApp(home: DemandasPage(viewModel: vm)));
  await tester.pumpAndSettle();
  if (find.textContaining('Alvo').evaluate().isEmpty &&
      find.textContaining('Mãe').evaluate().isNotEmpty) {
    await tester.tap(find.textContaining('Mãe'));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.textContaining('Alvo'));
  await tester.tap(find.textContaining('Alvo'));
  await tester.pumpAndSettle();
  return vm;
}

Future<void> _tocar(WidgetTester tester, String chave) async {
  final finder = find.byKey(ValueKey(chave));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _selecionar(
  WidgetTester tester,
  int id,
  backend.DemandaStatus status,
) async {
  await _tocar(tester, 'status-demanda-$id');
  final opcao = find.byKey(ValueKey('status-opcao-${status.name}-$id'));
  await tester.ensureVisible(opcao);
  await tester.tap(opcao);
  // A resposta pode estar pendente; não aguarda a animação do loading.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _concluir(WidgetTester tester, String via) async {
  if (via == 'menu') {
    await _selecionar(tester, 1, backend.DemandaStatus.concluida);
  } else {
    final check = find.byKey(const ValueKey('concluir-demanda-1'));
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.tap(check);
    await tester.pump();
  }
}

Future<void> _confirmarDuasVezes(WidgetTester tester, String chave) async {
  final botao = find.byKey(ValueKey(chave));
  await tester.ensureVisible(botao);
  await tester.tap(botao);
  await tester.tap(botao);
  await tester.pump();
  expect(tester.widget<FilledButton>(botao).onPressed, isNull);
  expect(
    tester
        .widget<TextButton>(find.byKey(const ValueKey('voltar-dialogo-status')))
        .onPressed,
    isNull,
  );
  expect(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(CircularProgressIndicator),
    ),
    findsOneWidget,
  );
  await tester.tapAt(const Offset(10, 10));
  await tester.pump();
  expect(find.byType(AlertDialog), findsOneWidget);
}

class _ViewModelObservada extends DemandasViewModel {
  _ViewModelObservada({required super.repository});

  int conclusoes = 0;
  int alteracoesNormais = 0;

  @override
  Future<bool> concluirDemanda(backend.Demanda demanda) {
    conclusoes++;
    return super.concluirDemanda(demanda);
  }

  @override
  Future<bool> alterarStatusDemanda({
    required backend.Demanda demanda,
    required backend.DemandaStatus status,
    String? motivoCancelamento,
  }) {
    alteracoesNormais++;
    return super.alterarStatusDemanda(
      demanda: demanda,
      status: status,
      motivoCancelamento: motivoCancelamento,
    );
  }
}
