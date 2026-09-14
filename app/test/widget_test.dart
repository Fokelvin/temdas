import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/app/app_routes.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  for (final falha in [false, true]) {
    testWidgets(
      'criação raiz mostra loading local e trata ${falha ? 'erro' : 'sucesso'}',
      (tester) async {
        await _configurarTela(tester);
        final original = demandaFixture();
        final resposta = Completer<backend.Demanda>();
        final repository = FakeDemandaRepository(demandas: [original])
          ..respostaCriarPendente = resposta;
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await _abrirPagina(tester, viewModel);
        await tester.enterText(
          find.byType(TextFormField).first,
          'Nova demanda',
        );

        await _confirmarComLoading(
          tester,
          'criar-demanda',
          'Criando...',
          dialogo: false,
        );
        expect(repository.chamadasCriar, 1);
        expect(viewModel.demandas, [original]);
        expect(find.text('Demanda inicial'), findsOneWidget);
        if (falha) {
          resposta.completeError(StateError('Falha ao criar'));
        } else {
          resposta.complete(demandaFixture(id: 2, titulo: 'Nova demanda'));
        }
        await tester.pumpAndSettle();

        expect(repository.chamadasListar, 1);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('criar-demanda')))
              .onPressed,
          isNotNull,
        );
        if (falha) {
          expect(viewModel.demandas, [original]);
          expect(
            find.widgetWithText(
              SnackBar,
              'Não foi possível criar a demanda. Tente novamente.',
            ),
            findsOneWidget,
          );
          expect(
            tester
                .widget<TextFormField>(find.byType(TextFormField).first)
                .controller!
                .text,
            'Nova demanda',
          );
        } else {
          expect(viewModel.demandas, hasLength(2));
          expect(find.text('Nova demanda'), findsOneWidget);
          expect(find.text('Demanda criada com sucesso.'), findsOneWidget);
        }
      },
    );
  }

  for (final operacao in ['filha', 'edição', 'folha', 'árvore']) {
    testWidgets('falha de $operacao remove loading e preserva dados', (
      tester,
    ) async {
      await _configurarTela(tester);
      final mae = demandaFixture();
      final originais = [
        mae,
        if (operacao == 'árvore')
          demandaFixture(id: 2, demandaPaiId: 1, titulo: 'Filha'),
      ];
      final respostaDemanda = Completer<backend.Demanda>();
      final respostaExclusao = Completer<bool>();
      final repository = FakeDemandaRepository(demandas: originais);
      final String abrir;
      final String confirmar;
      final String loading;
      final String mensagem;
      switch (operacao) {
        case 'filha':
          repository.respostaCriarPendente = respostaDemanda;
          abrir = 'criar-filha-1';
          confirmar = 'salvar-demanda-filha';
          loading = 'Criando...';
          mensagem = 'Não foi possível criar a demanda. Tente novamente.';
        case 'edição':
          repository.respostaAtualizarPendente = respostaDemanda;
          abrir = 'editar-demanda-1';
          confirmar = 'salvar-edicao-demanda';
          loading = 'Salvando...';
          mensagem = 'Não foi possível atualizar a demanda. Tente novamente.';
        default:
          if (operacao == 'árvore') {
            repository.respostaExcluirArvorePendente = respostaExclusao;
          } else {
            repository.respostaExcluirPendente = respostaExclusao;
          }
          abrir = 'excluir-demanda-1';
          confirmar = 'confirmar-exclusao-1';
          loading = 'Excluindo...';
          mensagem = 'Não foi possível excluir a demanda. Tente novamente.';
      }
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await _abrirPagina(tester, viewModel);
      await _expandirDemanda(tester, 'Demanda inicial');
      await tester.ensureVisible(find.byKey(ValueKey(abrir)));
      await tester.tap(find.byKey(ValueKey(abrir)));
      await tester.pumpAndSettle();
      if (operacao == 'filha') {
        await tester.enterText(
          find.byKey(const ValueKey('criar-filha-titulo')),
          'Filha',
        );
      }
      await _confirmarComLoading(tester, confirmar, loading);
      if (operacao == 'filha' || operacao == 'edição') {
        respostaDemanda.completeError(StateError('Falha da mutação'));
      } else {
        respostaExclusao.completeError(StateError('Falha da mutação'));
      }
      await tester.pumpAndSettle();

      expect(viewModel.demandas, originais);
      expect(viewModel.enviando, isFalse);
      expect(repository.chamadasListar, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.widgetWithText(SnackBar, mensagem), findsOneWidget);
      await _expandirDemanda(tester, 'Demanda inicial');
      expect(
        tester.widget<TextButton>(find.byKey(ValueKey(abrir))).onPressed,
        isNotNull,
      );
    });
  }

  testWidgets('edita uma demanda e mostra feedback de sucesso', (tester) async {
    await _configurarTela(tester);
    final resposta = Completer<backend.Demanda>();
    final original = demandaFixture();
    final repository = FakeDemandaRepository(demandas: [original])
      ..respostaAtualizarPendente = resposta;
    final viewModel = DemandasViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await _abrirPagina(tester, viewModel);
    await _expandirDemanda(tester, 'Demanda inicial');
    await tester.ensureVisible(find.byKey(const ValueKey('editar-demanda-1')));
    await tester.tap(find.byKey(const ValueKey('editar-demanda-1')));
    await tester.pumpAndSettle();

    expect(find.text('Editar demanda'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('editar-demanda-titulo')),
      'Demanda editada pela tela',
    );
    await tester.enterText(
      find.byKey(const ValueKey('editar-demanda-tempo')),
      '1,5',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('salvar-edicao-demanda')),
    );
    await _confirmarComLoading(tester, 'salvar-edicao-demanda', 'Salvando...');
    expect(repository.chamadasAtualizar, 1);
    expect(viewModel.demandas, [original]);
    resposta.complete(
      original.copyWith(
        titulo: 'Demanda editada pela tela',
        tempoEstimadoMinutos: 90,
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.chamadasAtualizar, 1);
    expect(repository.chamadasListar, 1);
    expect(repository.ultimaAtualizacao?.tempoEstimadoMinutos, 90);
    expect(find.text('Demanda editada pela tela'), findsOneWidget);
    expect(find.text('Demanda atualizada com sucesso.'), findsOneWidget);
  });

  testWidgets('cria filha mantendo a demanda mãe fixa', (tester) async {
    await _configurarTela(tester);
    final mae = demandaFixture(id: 1, titulo: 'Demanda mãe');
    final resposta = Completer<backend.Demanda>();
    final repository = FakeDemandaRepository(demandas: [mae])
      ..respostaCriarPendente = resposta;
    final viewModel = DemandasViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await _abrirPagina(tester, viewModel);
    await _expandirDemanda(tester, 'Demanda mãe');
    await tester.ensureVisible(find.byKey(const ValueKey('criar-filha-1')));
    await tester.tap(find.byKey(const ValueKey('criar-filha-1')));
    await tester.pumpAndSettle();

    expect(find.text('Criar demanda filha'), findsOneWidget);
    expect(find.text('Demanda mãe: Demanda mãe'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('criar-filha-titulo')),
      'Primeira filha',
    );
    await tester.enterText(
      find.byKey(const ValueKey('criar-filha-tempo')),
      '0,5',
    );
    await _confirmarComLoading(tester, 'salvar-demanda-filha', 'Criando...');
    expect(repository.chamadasCriar, 1);
    expect(viewModel.demandas, [mae]);
    resposta.complete(
      demandaFixture(
        id: 2,
        demandaPaiId: 1,
        titulo: 'Primeira filha',
        tempoEstimadoMinutos: 30,
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.ultimaCriacao?.demandaPaiId, 1);
    expect(repository.chamadasListar, 1);
    expect(find.byKey(const ValueKey('demanda-tree-node-2-1')), findsOneWidget);
    expect(repository.ultimaCriacao?.tempoEstimadoMinutos, 30);
    expect(find.text('Primeira filha'), findsOneWidget);
    expect(find.text('Demanda filha criada com sucesso.'), findsOneWidget);
  });

  testWidgets('só exclui uma demanda folha após confirmação explícita', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resposta = Completer<bool>();
    final original = demandaFixture();
    final repository = FakeDemandaRepository(demandas: [original])
      ..respostaExcluirPendente = resposta;
    final viewModel = DemandasViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await _abrirPagina(tester, viewModel);
    await _expandirDemanda(tester, 'Demanda inicial');
    await tester.ensureVisible(find.byKey(const ValueKey('excluir-demanda-1')));
    await tester.tap(find.byKey(const ValueKey('excluir-demanda-1')));
    await tester.pumpAndSettle();

    expect(find.text('Excluir demanda?'), findsOneWidget);
    expect(find.text('Excluir tudo'), findsNothing);
    expect(repository.chamadasExcluir, 0);

    await _confirmarComLoading(tester, 'confirmar-exclusao-1', 'Excluindo...');
    expect(repository.chamadasExcluir, 1);
    expect(viewModel.demandas, [original]);
    resposta.complete(true);
    await tester.pumpAndSettle();

    expect(repository.chamadasExcluir, 1);
    expect(repository.chamadasExcluirArvore, 0);
    expect(repository.chamadasListar, 1);
    expect(find.text('Nenhuma demanda cadastrada.'), findsOneWidget);
    expect(find.text('Demanda excluída com sucesso.'), findsOneWidget);
  });

  testWidgets('cancela ou exclui recursivamente uma demanda mãe', (
    tester,
  ) async {
    await _configurarTela(tester);
    final mae = demandaFixture(id: 1, titulo: 'Mãe');
    final filha = demandaFixture(id: 2, demandaPaiId: 1, titulo: 'Filha');
    final neta = demandaFixture(id: 3, demandaPaiId: 2, titulo: 'Neta');
    final resposta = Completer<bool>();
    final repository = FakeDemandaRepository(demandas: [mae, filha, neta])
      ..respostaExcluirArvorePendente = resposta;
    final viewModel = DemandasViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await _abrirPagina(tester, viewModel);
    await _expandirDemanda(tester, 'Mãe');
    await tester.ensureVisible(find.byKey(const ValueKey('excluir-demanda-1')));
    await tester.tap(find.byKey(const ValueKey('excluir-demanda-1')));
    await tester.pumpAndSettle();

    expect(find.text('Excluir demanda e descendentes?'), findsOneWidget);
    expect(find.text('Excluir tudo'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.chamadasExcluirArvore, 0);
    expect(find.text('Mãe'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('excluir-demanda-1')));
    await tester.pumpAndSettle();
    await _confirmarComLoading(tester, 'confirmar-exclusao-1', 'Excluindo...');
    expect(repository.chamadasExcluirArvore, 1);
    expect(viewModel.demandas, [mae, filha, neta]);
    resposta.complete(true);
    await tester.pumpAndSettle();

    expect(repository.chamadasExcluir, 0);
    expect(repository.chamadasExcluirArvore, 1);
    expect(repository.chamadasListar, 1);
    expect(find.text('Nenhuma demanda cadastrada.'), findsOneWidget);
    expect(
      find.text('Demanda e descendentes excluídos com sucesso.'),
      findsOneWidget,
    );
  });

  testWidgets('renderiza árvore recursiva e comparação de tempo', (
    tester,
  ) async {
    await _configurarTela(tester);
    final repository = FakeDemandaRepository(
      demandas: [
        demandaFixture(id: 1, titulo: 'Raiz'),
        demandaFixture(id: 2, demandaPaiId: 1, titulo: 'Filha'),
        demandaFixture(
          id: 3,
          demandaPaiId: 2,
          titulo: 'Neta',
          tempoEstimadoMinutos: 60,
          tempoExecutadoMinutos: 90,
        ),
      ],
    );
    final viewModel = DemandasViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await _abrirPagina(tester, viewModel);

    expect(find.byKey(const ValueKey('demanda-tree-node-1-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('demanda-tree-node-2-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('demanda-tree-node-3-2')), findsOneWidget);

    await _expandirDemanda(tester, 'Neta');
    expect(find.text('Estimado: 1 h'), findsOneWidget);
    expect(find.text('Executado: 1 h 30 min'), findsOneWidget);
    expect(find.text('Excedido em 30 min'), findsOneWidget);
  });

  testWidgets('lança duração em horas e atualiza o total da demanda', (
    tester,
  ) async {
    await _configurarTela(tester);
    final repository = FakeDemandaRepository(
      demandas: [demandaFixture(tempoExecutadoMinutos: 0)],
    );
    final registroRepository = FakeRegistroTempoRepository(
      demandaRepository: repository,
    );
    final viewModel = DemandasViewModel(
      repository: repository,
      registroTempoRepository: registroRepository,
    );
    addTearDown(viewModel.dispose);

    await _abrirPagina(tester, viewModel);
    await _expandirDemanda(tester, 'Demanda inicial');
    await tester.ensureVisible(find.byKey(const ValueKey('lancar-tempo-1')));
    await tester.tap(find.byKey(const ValueKey('lancar-tempo-1')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Lançar tempo'),
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('log-time-duracao')),
      '1,25',
    );
    await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
    await tester.pumpAndSettle();

    expect(registroRepository.chamadasRegistrar, 1);
    expect(registroRepository.ultimaDemandaId, 1);
    expect(registroRepository.ultimaDuracaoMinutos, 75);
    expect(registroRepository.ultimoInicioEm?.isUtc, isTrue);
    expect(find.text('Tempo registrado com sucesso.'), findsOneWidget);
    expect(find.text('Executado: 1 h 15 min'), findsOneWidget);
  });

  testWidgets('Mostrar tudo navega com o ID da demanda', (tester) async {
    await _configurarTela(tester);
    final repository = FakeDemandaRepository(
      demandas: [demandaFixture(id: 42)],
    );
    final viewModel = DemandasViewModel(repository: repository);
    addTearDown(viewModel.dispose);
    Object? argumentosRecebidos;

    await tester.pumpWidget(
      MaterialApp(
        home: DemandasPage(viewModel: viewModel),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.demandaDetalhe) {
            argumentosRecebidos = settings.arguments;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Detalhe aberto')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();
    await _expandirDemanda(tester, 'Demanda inicial');
    await tester.ensureVisible(find.byKey(const ValueKey('mostrar-tudo-42')));
    await tester.tap(find.byKey(const ValueKey('mostrar-tudo-42')));
    await tester.pumpAndSettle();

    expect(argumentosRecebidos, 42);
    expect(find.text('Detalhe aberto'), findsOneWidget);
  });
}

Future<void> _configurarTela(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _confirmarComLoading(
  WidgetTester tester,
  String chave,
  String texto, {
  bool dialogo = true,
}) async {
  final botao = find.byKey(ValueKey(chave));
  await tester.ensureVisible(botao);
  // Dois cliques antes do próximo frame também devem gerar só um envio.
  await tester.tap(botao);
  await tester.tap(botao);
  await tester.pump();
  expect(tester.widget<FilledButton>(botao).onPressed, isNull);
  expect(
    find.descendant(of: botao, matching: find.text(texto)),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: botao,
      matching: find.byType(CircularProgressIndicator),
    ),
    findsOneWidget,
  );
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await tester.tap(botao);
  await tester.pump();
  if (dialogo) {
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
          .onPressed,
      isNull,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('criar-demanda')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
  }
}

Future<void> _abrirPagina(
  WidgetTester tester,
  DemandasViewModel viewModel,
) async {
  await tester.pumpWidget(
    MaterialApp(home: DemandasPage(viewModel: viewModel)),
  );
  await tester.pumpAndSettle();
}

Future<void> _expandirDemanda(WidgetTester tester, String titulo) async {
  await tester.ensureVisible(find.text(titulo));
  await tester.tap(find.text(titulo));
  await tester.pumpAndSettle();
}
