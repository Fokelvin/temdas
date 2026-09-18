import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
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
        expect(find.byType(Form), findsNothing);
        final abrir = find.byKey(const ValueKey('abrir-criar-demanda'));
        expect(
          find.descendant(of: find.byType(AppBar), matching: abrir),
          findsOneWidget,
        );
        await tester.tap(abrir);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);

        if (!falha) {
          await tester.tap(find.byKey(const ValueKey('criar-demanda')));
          await tester.pumpAndSettle();
          expect(find.text('Informe o título.'), findsOneWidget);
          expect(repository.chamadasCriar, 0);
          await tester.tap(find.text('Cancelar'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          await tester.tap(abrir);
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Fechar'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          expect(repository.chamadasCriar, 0);
          await tester.tap(abrir);
          await tester.pumpAndSettle();
        }
        await tester.enterText(
          find.byType(TextFormField).first,
          'Nova demanda',
        );
        await tester.enterText(find.byType(TextFormField).last, '1,5');

        await _confirmarComLoading(tester, 'criar-demanda', 'Criando...');
        expect(repository.chamadasCriar, 1);
        expect(repository.ultimaCriacao?.tempoEstimadoMinutos, 90);
        expect(viewModel.demandas, [original]);
        expect(find.text('1 - Demanda inicial'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
              .onPressed,
          isNull,
        );
        if (falha) {
          resposta.completeError(StateError('Falha ao criar'));
        } else {
          resposta.complete(demandaFixture(id: 2, titulo: 'Nova demanda'));
        }
        await tester.pumpAndSettle();

        expect(repository.chamadasListar, 1);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        if (falha) {
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const ValueKey('criar-demanda')),
                )
                .onPressed,
            isNotNull,
          );
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
          expect(find.byType(AlertDialog), findsNothing);
          expect(viewModel.demandas, hasLength(2));
          expect(find.text('2 - Nova demanda'), findsOneWidget);
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
      if (operacao != 'filha') await _abrirMenuAcoes(tester, 1);
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
      expect(find.text('ID: 1'), findsOneWidget);
      if (operacao == 'filha') {
        expect(
          tester.widget<TextButton>(find.byKey(ValueKey(abrir))).onPressed,
          isNotNull,
        );
      } else {
        expect(
          tester
              .widget<PopupMenuButton<dynamic>>(
                find.byKey(const ValueKey('acoes-demanda-1')),
              )
              .enabled,
          isTrue,
        );
      }
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
    await _abrirMenuAcoes(tester, 1);
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
    await tester.tap(find.byKey(const ValueKey('editar-demanda-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluída').last);
    await tester.pumpAndSettle();
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
        status: backend.DemandaStatus.concluida,
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.chamadasAtualizar, 1);
    expect(repository.chamadasListar, 1);
    expect(repository.ultimaAtualizacao?.tempoEstimadoMinutos, 90);
    expect(
      repository.ultimaAtualizacao?.status,
      backend.DemandaStatus.concluida,
    );
    expect(find.text('1 - Demanda editada pela tela'), findsOneWidget);
    expect(find.text('Demanda atualizada com sucesso.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('demanda-tree-node-1-0'))).dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('demanda-status-concluida')))
            .dy,
      ),
    );
    // O card continua expandido depois de mudar de coluna.
    expect(find.text('Estimado: 1 h 30 min'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('acoes-demanda-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('acoes-demanda-1')).hitTestable(),
      findsOneWidget,
    );
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
    expect(find.text('Demanda mãe: 1 - Demanda mãe'), findsOneWidget);
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
    expect(find.text('2 - Primeira filha'), findsOneWidget);
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
    await _abrirMenuAcoes(tester, 1);
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
    expect(find.text('Nenhuma demanda neste status.'), findsNWidgets(5));
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
    await _abrirMenuAcoes(tester, 1);
    await tester.ensureVisible(find.byKey(const ValueKey('excluir-demanda-1')));
    await tester.tap(find.byKey(const ValueKey('excluir-demanda-1')));
    await tester.pumpAndSettle();

    expect(find.text('Excluir demanda e descendentes?'), findsOneWidget);
    expect(find.text('Excluir tudo'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.chamadasExcluirArvore, 0);
    expect(find.text('1 - Mãe'), findsOneWidget);

    await _abrirMenuAcoes(tester, 1);
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
    expect(find.text('Nenhuma demanda neste status.'), findsNWidgets(5));
    expect(
      find.text('Demanda e descendentes excluídos com sucesso.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'agrupa árvores pelo status da raiz preservando status e ordem das filhas',
    (tester) async {
      await _configurarTela(tester);
      final demandas = [
        demandaFixture(
          id: 2,
          demandaPaiId: 1,
          titulo: 'Filha pausada',
          status: backend.DemandaStatus.pausada,
        ),
        demandaFixture(id: 3, titulo: 'Primeira aberta'),
        demandaFixture(id: 4, demandaPaiId: 2, titulo: 'Neta aberta'),
        demandaFixture(
          id: 1,
          titulo: 'Mãe concluída',
          status: backend.DemandaStatus.concluida,
        ),
        demandaFixture(id: 5, titulo: 'Última aberta'),
        demandaFixture(
          id: 6,
          titulo: 'Em execução',
          status: backend.DemandaStatus.emAndamento,
        ),
        demandaFixture(
          id: 7,
          titulo: 'Cancelada',
          status: backend.DemandaStatus.cancelada,
        ),
      ];
      final repository = FakeDemandaRepository(demandas: demandas);
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await _abrirPagina(tester, viewModel);
      await _expandirDemanda(tester, 'Mãe concluída');
      await _expandirDemanda(tester, 'Filha pausada');
      await _expandirDemanda(tester, 'Neta aberta');

      final grupos = {
        backend.DemandaStatus.aberta: (raizes: 2, ids: [3, 5]),
        backend.DemandaStatus.emAndamento: (raizes: 1, ids: [6]),
        backend.DemandaStatus.pausada: (raizes: 0, ids: <int>[]),
        backend.DemandaStatus.concluida: (raizes: 1, ids: [1, 2, 4]),
        backend.DemandaStatus.cancelada: (raizes: 1, ids: [7]),
      };
      expect(find.byType(DemandaCard), findsNWidgets(demandas.length));
      var ultimoX = double.negativeInfinity;
      final primeiroY = tester
          .getTopLeft(find.byKey(const ValueKey('demanda-status-aberta')))
          .dy;
      for (final grupo in grupos.entries) {
        final coluna = find.byKey(ValueKey('demanda-coluna-${grupo.key.name}'));
        final cabecalho = find.byKey(
          ValueKey('demanda-status-${grupo.key.name}'),
        );
        final posicao = tester.getTopLeft(cabecalho);
        expect(posicao.dx, greaterThan(ultimoX));
        expect(posicao.dy, primeiroY);
        ultimoX = tester.getTopRight(coluna).dx;
        expect(
          find.descendant(
            of: cabecalho,
            matching: find.text('(${grupo.value.raizes})'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: coluna, matching: find.byType(DemandaCard)),
          findsNWidgets(grupo.value.ids.length),
        );
        var ultimoY = tester.getBottomLeft(cabecalho).dy;
        for (final id in grupo.value.ids) {
          final card = find.byKey(ValueKey('demanda-card-$id'));
          expect(card, findsOneWidget);
          expect(find.descendant(of: coluna, matching: card), findsOneWidget);
          final cardY = tester.getTopLeft(card).dy;
          expect(cardY, greaterThanOrEqualTo(ultimoY));
          ultimoY = tester.getBottomLeft(card).dy;
        }
      }
      expect(
        find.byKey(const ValueKey('demanda-tree-node-2-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('demanda-tree-node-4-2')),
        findsOneWidget,
      );
      expect(viewModel.demandas, demandas);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('demanda-card-2')),
          matching: find.text('Pausada'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('demanda-card-4')),
          matching: find.text('Aberta'),
        ),
        findsOneWidget,
      );
      expect(repository.chamadasListar, 1);
      expect(repository.chamadasAtualizar, 0);
    },
  );

  for (final largura in [390.0, 1200.0, 2400.0]) {
    testWidgets(
      'quadro com largura $largura mantém colunas e usa só o scroll vertical da página',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(largura, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repository = FakeDemandaRepository(
          demandas: [
            for (var id = 1; id <= 12; id++)
              demandaFixture(id: id, titulo: 'Demanda $id'),
            demandaFixture(
              id: 100,
              demandaPaiId: 1,
              status: backend.DemandaStatus.concluida,
            ),
          ],
        );
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await _abrirPagina(tester, viewModel);

        final quadro = find.byKey(const ValueKey('demandas-quadro-status'));
        final scrollQuadro = find.descendant(
          of: quadro,
          matching: find.byType(Scrollable),
        );
        expect(scrollQuadro, findsOneWidget);
        final horizontal = tester.state<ScrollableState>(scrollQuadro);
        expect(horizontal.position.axis, Axis.horizontal);
        final barra = tester.widget<Scrollbar>(
          find.byKey(const ValueKey('demandas-quadro-scrollbar')),
        );
        final controller = tester
            .widget<SingleChildScrollView>(quadro)
            .controller;
        expect(controller, isNotNull);
        expect(barra.controller, same(controller));
        expect(controller!.position, same(horizontal.position));
        expect(barra.thumbVisibility, largura < 2000);
        expect(barra.trackVisibility, isFalse);
        expect(barra.scrollbarOrientation, ScrollbarOrientation.bottom);
        expect(barra.interactive, isTrue);
        final scrollVertical = find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
        );
        expect(scrollVertical, findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('demandas-pagina-scroll')),
            matching: scrollVertical,
          ),
          findsOneWidget,
        );
        final vertical = tester.state<ScrollableState>(scrollVertical);
        expect(vertical.position.maxScrollExtent, greaterThan(0));

        final nomes = {
          backend.DemandaStatus.aberta: 'Abertas',
          backend.DemandaStatus.emAndamento: 'Em andamento',
          backend.DemandaStatus.pausada: 'Pausadas',
          backend.DemandaStatus.concluida: 'Concluídas',
          backend.DemandaStatus.cancelada: 'Canceladas',
        };
        var ultimoX = double.negativeInfinity;
        final topo = tester
            .getTopLeft(find.byKey(const ValueKey('demanda-status-aberta')))
            .dy;
        for (final status in nomes.entries) {
          final coluna = find.byKey(
            ValueKey('demanda-coluna-${status.key.name}'),
          );
          final cabecalho = find.byKey(
            ValueKey('demanda-status-${status.key.name}'),
          );
          expect(
            find.descendant(of: cabecalho, matching: find.text(status.value)),
            findsOneWidget,
          );
          expect(tester.getSize(coluna).width, greaterThanOrEqualTo(360));
          if (largura < 2000) {
            expect(tester.getSize(coluna).width, 360);
          } else {
            final limites = tester.getRect(cabecalho);
            final viewport = tester.getRect(quadro);
            expect(limites.left, greaterThanOrEqualTo(viewport.left));
            expect(limites.right, lessThanOrEqualTo(viewport.right));
            expect(limites.top, greaterThanOrEqualTo(0));
            expect(limites.bottom, lessThanOrEqualTo(900));
          }
          expect(tester.getTopLeft(cabecalho).dy, topo);
          expect(tester.getTopLeft(coluna).dx, greaterThan(ultimoX));
          ultimoX = tester.getTopRight(coluna).dx;
        }
        expect(
          tester
              .getSize(find.byKey(const ValueKey('demanda-coluna-aberta')))
              .height,
          greaterThan(vertical.position.viewportDimension),
        );
        expect(find.text('Nenhuma demanda neste status.'), findsNWidgets(4));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('demanda-status-aberta')),
            matching: find.text('(12)'),
          ),
          findsOneWidget,
        );

        final tituloPagina = find.text('Demandas salvas');
        final posicaoTitulo = tester.getTopLeft(tituloPagina);
        if (largura < 2000) {
          expect(horizontal.position.maxScrollExtent, greaterThan(0));
          await tester.dragFrom(
            tester.getTopLeft(quadro) + const Offset(250, 20),
            const Offset(-200, 0),
          );
          await tester.pumpAndSettle();
          expect(horizontal.position.pixels, greaterThan(0));
          expect(vertical.position.pixels, 0);
          expect(tester.getTopLeft(tituloPagina), posicaoTitulo);
        } else {
          expect(horizontal.position.maxScrollExtent, 0);
          expect(ultimoX, closeTo(largura - 24, 0.01));
        }

        final deslocamentoHorizontal = horizontal.position.pixels;
        final topoQuadro = tester.getTopLeft(quadro).dy;
        await tester.dragFrom(const Offset(200, 400), const Offset(0, -250));
        await tester.pumpAndSettle();
        expect(vertical.position.pixels, greaterThan(0));
        expect(horizontal.position.pixels, deslocamentoHorizontal);
        expect(tester.getTopLeft(quadro).dy, lessThan(topoQuadro));
        final ultimoCard = find.byKey(const ValueKey('demanda-card-12'));
        await tester.ensureVisible(ultimoCard);
        await tester.pumpAndSettle();
        expect(ultimoCard.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'barra discreta no fim do conteúdo ganha destaque em hover e arraste',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final viewModel = DemandasViewModel(
        repository: FakeDemandaRepository(
          demandas: [for (var id = 1; id <= 12; id++) demandaFixture(id: id)],
        ),
      );
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light.copyWith(platform: TargetPlatform.linux),
          home: DemandasPage(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();
      // A barra continua utilizável depois do tempo de fade padrão, sem hover.
      await tester.pump(const Duration(seconds: 3));

      final barra = find.byKey(const ValueKey('demandas-quadro-scrollbar'));
      expect(
        find.descendant(of: barra, matching: find.byType(Scrollbar)),
        findsNothing,
      );
      final controller = tester.widget<Scrollbar>(barra).controller!;
      final pagina = tester.state<ScrollableState>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      expect(controller.offset, 0);
      expect(tester.getBottomLeft(barra).dy, greaterThan(900));
      pagina.position.jumpTo(pagina.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final posicaoVertical = pagina.position.pixels;
      final pintor = _pintorBarra(tester, barra);
      expect(pintor.thickness, 4);
      expect(pintor.color.a, closeTo(0.28, 0.01));
      expect(pintor.fadeoutOpacityAnimation.value, 1);
      expect(pintor.trackColor.a, 0);
      final pontoBarra = tester.getBottomLeft(barra) + const Offset(20, -6);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(pontoBarra);
      await tester.pumpAndSettle();
      expect(pintor.thickness, 9);
      expect(pintor.color.a, closeTo(0.60, 0.01));
      await mouse.down(pontoBarra);
      await mouse.moveBy(const Offset(150, 0));
      await tester.pump();
      expect(controller.offset, greaterThan(0));
      expect(pintor.thickness, 9);
      expect(pintor.color.a, closeTo(0.75, 0.01));
      await mouse.moveBy(const Offset(900, 0));
      await mouse.up();
      await mouse.moveTo(Offset.zero);
      await mouse.removePointer();
      await tester.pumpAndSettle();
      expect(controller.offset, controller.position.maxScrollExtent);
      expect(pagina.position.pixels, posicaoVertical);
      expect(pintor.thickness, 4);
      expect(pintor.color.a, closeTo(0.28, 0.01));
      expect(pintor.fadeoutOpacityAnimation.value, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'barra segue a coluna mais alta e rola com o conteúdo da página',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final viewModel = DemandasViewModel(
        repository: FakeDemandaRepository(
          demandas: [
            for (var id = 1; id <= 12; id++)
              demandaFixture(id: id, titulo: 'Demanda $id'),
            demandaFixture(id: 13, status: backend.DemandaStatus.emAndamento),
          ],
        ),
      );
      addTearDown(viewModel.dispose);
      await _abrirPagina(tester, viewModel);
      final barra = find.byKey(const ValueKey('demandas-quadro-scrollbar'));
      final colunaAlta = find.byKey(const ValueKey('demanda-coluna-aberta'));
      final pintor = _pintorBarra(tester, barra);
      double topoBarra() =>
          tester.getBottomLeft(barra).dy -
          pintor.crossAxisMargin -
          pintor.thickness;
      void verificarAbaixoDasColunas() {
        for (final status in backend.DemandaStatus.values) {
          final coluna = find.byKey(ValueKey('demanda-coluna-${status.name}'));
          expect(topoBarra(), greaterThan(tester.getBottomLeft(coluna).dy));
        }
        // Confere também a região efetivamente pintada/interativa da barra.
        expect(
          pintor.hitTestOnlyThumbInteractive(
            Offset(
              20,
              tester.getSize(barra).height - pintor.crossAxisMargin - 2,
            ),
            PointerDeviceKind.mouse,
          ),
          isTrue,
        );
      }

      verificarAbaixoDasColunas();
      expect(topoBarra(), greaterThan(900));
      final topoAntes = topoBarra();
      final alturaAntes = tester.getSize(colunaAlta).height;
      await tester.tap(find.text('1 - Demanda 1'));
      await tester.pumpAndSettle();
      final crescimento = tester.getSize(colunaAlta).height - alturaAntes;
      expect(crescimento, greaterThan(0));
      expect(topoBarra() - topoAntes, closeTo(crescimento, 0.01));
      verificarAbaixoDasColunas();

      final pagina = tester.state<ScrollableState>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      final topoAntesDoScroll = topoBarra();
      final distanciaDaColuna =
          topoBarra() - tester.getBottomLeft(colunaAlta).dy;
      pagina.position.jumpTo(120);
      await tester.pumpAndSettle();
      expect(topoBarra(), closeTo(topoAntesDoScroll - 120, 0.01));
      expect(
        topoBarra() - tester.getBottomLeft(colunaAlta).dy,
        closeTo(distanciaDaColuna, 0.01),
      );
      expect(topoBarra(), greaterThan(900));
      verificarAbaixoDasColunas();

      pagina.position.jumpTo(pagina.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(topoBarra(), lessThan(900));
      expect(
        topoBarra() - tester.getBottomLeft(colunaAlta).dy,
        closeTo(distanciaDaColuna, 0.01),
      );
      verificarAbaixoDasColunas();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quadro vazio mantém as cinco colunas e contagens zeradas', (
    tester,
  ) async {
    await _configurarTela(tester);
    final viewModel = DemandasViewModel(repository: FakeDemandaRepository());
    addTearDown(viewModel.dispose);
    await _abrirPagina(tester, viewModel);

    expect(find.byType(DemandaCard), findsNothing);
    for (final status in backend.DemandaStatus.values) {
      final coluna = find.byKey(ValueKey('demanda-coluna-${status.name}'));
      expect(coluna, findsOneWidget);
      expect(
        find.descendant(of: coluna, matching: find.text('(0)')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: coluna,
          matching: find.text('Nenhuma demanda neste status.'),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('expande e recolhe cards sem mudar a posição dos descendentes', (
    tester,
  ) async {
    await _configurarTela(tester);
    final viewModel = DemandasViewModel(
      repository: FakeDemandaRepository(
        demandas: [
          demandaFixture(id: 1, titulo: 'Mãe'),
          demandaFixture(
            id: 2,
            demandaPaiId: 1,
            titulo: 'Filha',
            status: backend.DemandaStatus.pausada,
          ),
        ],
      ),
    );
    addTearDown(viewModel.dispose);
    await _abrirPagina(tester, viewModel);

    expect(find.text('ID: 1'), findsNothing);
    await _expandirDemanda(tester, 'Mãe');
    expect(find.text('ID: 1'), findsOneWidget);
    await _expandirDemanda(tester, 'Mãe');
    expect(find.text('ID: 1'), findsNothing);

    await _expandirDemanda(tester, 'Mãe');
    expect(find.text('ID: 2'), findsNothing);
    await _expandirDemanda(tester, 'Filha');
    expect(find.text('ID: 2'), findsOneWidget);
    await _expandirDemanda(tester, 'Filha');
    expect(find.text('ID: 2'), findsNothing);
    final mae = find.byKey(const ValueKey('demanda-card-1'));
    final filha = find.byKey(const ValueKey('demanda-card-2'));
    final coluna = find.byKey(const ValueKey('demanda-coluna-aberta'));
    expect(find.descendant(of: coluna, matching: mae), findsOneWidget);
    expect(find.descendant(of: coluna, matching: filha), findsOneWidget);
    expect(tester.getTopLeft(filha).dx, greaterThan(tester.getTopLeft(mae).dx));
    expect(
      tester.getTopLeft(filha).dy,
      greaterThan(tester.getBottomLeft(mae).dy),
    );
  });

  for (final editarRaiz in [true, false]) {
    testWidgets(
      editarRaiz
          ? 'mudar status da raiz move toda a árvore e mantém os cards expandidos'
          : 'mudar só o status da filha mantém a árvore na coluna da raiz',
      (tester) async {
        await _configurarTela(tester);
        final mae = demandaFixture(id: 1, titulo: 'Mãe');
        final filha = demandaFixture(
          id: 2,
          demandaPaiId: 1,
          titulo: 'Filha',
          status: backend.DemandaStatus.concluida,
        );
        final neta = demandaFixture(
          id: 3,
          demandaPaiId: 2,
          titulo: 'Neta',
          status: backend.DemandaStatus.emAndamento,
        );
        final repository = FakeDemandaRepository(demandas: [mae, filha, neta]);
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await _abrirPagina(tester, viewModel);
        for (final titulo in ['Mãe', 'Filha', 'Neta']) {
          await _expandirDemanda(tester, titulo);
        }

        void verificarArvore(backend.DemandaStatus statusRaiz) {
          final coluna = find.byKey(
            ValueKey('demanda-coluna-${statusRaiz.name}'),
          );
          final limites = tester.getRect(coluna);
          var ultimoY = tester
              .getBottomLeft(
                find.byKey(ValueKey('demanda-status-${statusRaiz.name}')),
              )
              .dy;
          var ultimoX = double.negativeInfinity;
          for (final id in [1, 2, 3]) {
            final card = find.byKey(ValueKey('demanda-card-$id'));
            expect(card, findsOneWidget);
            expect(find.descendant(of: coluna, matching: card), findsOneWidget);
            final posicao = tester.getTopLeft(card);
            expect(posicao.dy, greaterThanOrEqualTo(ultimoY));
            expect(tester.getBottomLeft(card).dy, lessThan(limites.bottom));
            expect(posicao.dx, greaterThanOrEqualTo(limites.left));
            expect(
              tester.getTopRight(card).dx,
              lessThanOrEqualTo(limites.right),
            );
            expect(posicao.dx, greaterThan(ultimoX));
            ultimoY = tester.getBottomLeft(card).dy;
            ultimoX = posicao.dx;
            // O conteúdo só fica visível enquanto o card está expandido.
            expect(
              find.descendant(of: card, matching: find.text('ID: $id')),
              findsOneWidget,
            );
          }
        }

        verificarArvore(backend.DemandaStatus.aberta);
        final idEditado = editarRaiz ? 1 : 2;
        await _abrirMenuAcoes(tester, idEditado);
        final botaoEditar = find.byKey(ValueKey('editar-demanda-$idEditado'));
        await tester.ensureVisible(botaoEditar);
        await tester.tap(botaoEditar);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('editar-demanda-status')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(editarRaiz ? 'Em andamento' : 'Cancelada').last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('salvar-edicao-demanda')));
        await tester.pumpAndSettle();

        verificarArvore(
          editarRaiz
              ? backend.DemandaStatus.emAndamento
              : backend.DemandaStatus.aberta,
        );
        expect(find.byType(DemandaCard), findsNWidgets(3));
        expect(repository.chamadasAtualizar, 1);
        expect(repository.ultimaAtualizacao?.id, idEditado);
        expect(repository.chamadasListar, editarRaiz ? 1 : 2);
        expect(
          viewModel.demandas[0].status,
          editarRaiz ? backend.DemandaStatus.emAndamento : mae.status,
        );
        expect(
          viewModel.demandas[1].status,
          editarRaiz ? filha.status : backend.DemandaStatus.cancelada,
        );
        expect(viewModel.demandas[2], neta);
        expect(viewModel.demandas[1].demandaPaiId, 1);
        expect(viewModel.demandas[2].demandaPaiId, 2);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('demanda-card-2')),
            matching: find.text(editarRaiz ? 'Concluída' : 'Cancelada'),
          ),
          findsOneWidget,
        );
      },
    );
  }

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

    await _expandirDemanda(tester, 'Raiz');
    await _expandirDemanda(tester, 'Filha');

    expect(find.byKey(const ValueKey('demanda-tree-node-1-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('demanda-tree-node-2-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('demanda-tree-node-3-2')), findsOneWidget);

    await _expandirDemanda(tester, 'Neta');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('demanda-card-3')),
        matching: find.text('Estimado: 1 h'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('demanda-card-3')),
        matching: find.text('Executado: 1 h 30 min'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('demanda-card-3')),
        matching: find.text('Excedido em 30 min'),
      ),
      findsOneWidget,
    );
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
    await _preencherIntervaloLogTime(tester);
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
    await tester.pumpWidget(
      MaterialApp(home: DemandasPage(viewModel: viewModel)),
    );
    await tester.pumpAndSettle();
    await _expandirDemanda(tester, 'Demanda inicial');
    await _abrirMenuAcoes(tester, 42);
    await tester.ensureVisible(find.byKey(const ValueKey('mostrar-tudo-42')));
    await tester.tap(find.byKey(const ValueKey('mostrar-tudo-42')));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da demanda'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });
}

ScrollbarPainter _pintorBarra(WidgetTester tester, Finder barra) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: barra,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is CustomPaint &&
                      widget.foregroundPainter is ScrollbarPainter,
                ),
              ),
            )
            .foregroundPainter!
        as ScrollbarPainter;

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
  expect(
    dialogo
        ? find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(CircularProgressIndicator),
          )
        : find.byType(CircularProgressIndicator),
    findsOneWidget,
  );
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
    if (chave != 'criar-demanda') {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('criar-demanda')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
    }
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
  await tester.ensureVisible(find.textContaining(titulo));
  await tester.tap(find.textContaining(titulo));
  await tester.pumpAndSettle();
}

Future<void> _preencherIntervaloLogTime(WidgetTester tester) async {
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
    '15',
  );
}

Future<void> _abrirMenuAcoes(WidgetTester tester, int id) async {
  final menu = find.byKey(ValueKey('acoes-demanda-$id'));
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await tester.pumpAndSettle();
}
