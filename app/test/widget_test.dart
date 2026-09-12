import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/app/app_routes.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view_model/demandas_view_model.dart';

import 'support/fake_demanda_repository.dart';

void main() {
  testWidgets('edita uma demanda e mostra feedback de sucesso', (tester) async {
    await _configurarTela(tester);
    final repository = FakeDemandaRepository(demandas: [demandaFixture()]);
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
    await tester.tap(find.byKey(const ValueKey('salvar-edicao-demanda')));
    await tester.pumpAndSettle();

    expect(repository.chamadasAtualizar, 1);
    expect(repository.ultimaAtualizacao?.tempoEstimadoMinutos, 90);
    expect(find.text('Demanda editada pela tela'), findsOneWidget);
    expect(find.text('Demanda atualizada com sucesso.'), findsOneWidget);
  });

  testWidgets('cria filha mantendo a demanda mãe fixa', (tester) async {
    await _configurarTela(tester);
    final mae = demandaFixture(id: 1, titulo: 'Demanda mãe');
    final repository = FakeDemandaRepository(demandas: [mae]);
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
    await tester.tap(find.byKey(const ValueKey('salvar-demanda-filha')));
    await tester.pumpAndSettle();

    expect(repository.ultimaCriacao?.demandaPaiId, 1);
    expect(repository.ultimaCriacao?.tempoEstimadoMinutos, 30);
    expect(find.text('Primeira filha'), findsOneWidget);
    expect(find.text('Demanda filha criada com sucesso.'), findsOneWidget);
  });

  testWidgets('só exclui uma demanda folha após confirmação explícita', (
    tester,
  ) async {
    await _configurarTela(tester);
    final repository = FakeDemandaRepository(demandas: [demandaFixture()]);
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

    await tester.tap(find.byKey(const ValueKey('confirmar-exclusao-1')));
    await tester.pumpAndSettle();

    expect(repository.chamadasExcluir, 1);
    expect(repository.chamadasExcluirArvore, 0);
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
    final repository = FakeDemandaRepository(demandas: [mae, filha, neta]);
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
    await tester.tap(find.text('Excluir tudo'));
    await tester.pumpAndSettle();

    expect(repository.chamadasExcluir, 0);
    expect(repository.chamadasExcluirArvore, 1);
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
