import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/ui/components/app_shell.dart';
import 'package:temdas/ui/components/demand_components.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
import 'package:temdas/view/widgets/densidade_demanda.dart';
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
          find.descendant(of: find.byType(PageHeader), matching: abrir),
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
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('demanda-card-1')),
            matching: find.text('Demanda inicial'),
          ),
          findsOneWidget,
        );
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
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text(
                'Não foi possível criar a demanda. Tente novamente.',
              ),
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
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('demanda-card-2')),
              matching: find.text('Nova demanda'),
            ),
            findsOneWidget,
          );
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
      expect(find.byKey(ValueKey('status-demanda-1')), findsOneWidget);
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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('demanda-card-1')),
        matching: find.text('Demanda editada pela tela'),
      ),
      findsOneWidget,
    );
    expect(find.text('Demanda atualizada com sucesso.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('demanda-tree-node-1-0'))).dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('demanda-coluna-concluida')))
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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('demanda-card-2')),
        matching: find.text('Primeira filha'),
      ),
      findsOneWidget,
    );
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
    expect(viewModel.demandas, isEmpty);
    expect(find.byType(DemandaCard), findsNothing);
    expect(find.text('Nenhuma demanda ainda.'), findsOneWidget);
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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('demanda-card-1')),
        matching: find.text('Mãe'),
      ),
      findsOneWidget,
    );

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
    expect(viewModel.demandas, isEmpty);
    expect(find.byType(DemandaCard), findsNothing);
    expect(find.text('Nenhuma demanda ainda.'), findsOneWidget);
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
          .getTopLeft(find.byKey(const ValueKey('demanda-coluna-aberta')))
          .dy;
      for (final grupo in grupos.entries) {
        final coluna = find.byKey(ValueKey('demanda-coluna-${grupo.key.name}'));
        final kanban = tester.widget<KanbanColumn>(
          find.descendant(of: coluna, matching: find.byType(KanbanColumn)),
        );
        expect(kanban.status, grupo.key);
        expect(kanban.count, grupo.value.raizes);
        final cabecalho = find.descendant(
          of: coluna,
          matching: find.byType(GroupHeader),
        );
        final posicao = tester.getTopLeft(coluna);
        expect(posicao.dx, greaterThan(ultimoX));
        expect(posicao.dy, primeiroY);
        ultimoX = tester.getTopRight(coluna).dx;
        if (grupo.value.raizes == 0) {
          expect(kanban.collapsed, isTrue);
          expect(cabecalho, findsNothing);
          expect(
            find.descendant(of: coluna, matching: find.text('Pausada  0')),
            findsOneWidget,
          );
        } else {
          expect(
            tester.widget<GroupHeader>(cabecalho).count,
            grupo.value.raizes,
          );
          expect(
            find.descendant(
              of: cabecalho,
              matching: find.text('${grupo.value.raizes}'),
            ),
            findsOneWidget,
          );
        }
        expect(
          find.descendant(of: coluna, matching: find.byType(DemandaCard)),
          findsNWidgets(grupo.value.ids.length),
        );
        var ultimoY = grupo.value.raizes == 0
            ? posicao.dy
            : tester.getBottomLeft(cabecalho).dy;
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
      'quadro inicia compacto e adapta colunas ou abas em largura $largura',
      (tester) async {
        final vm = DemandasViewModel(
          repository: FakeDemandaRepository(
            demandas: [
              demandaFixture(titulo: 'Demanda aberta'),
              demandaFixture(
                id: 2,
                titulo: 'Demanda concluída',
                status: backend.DemandaStatus.concluida,
              ),
            ],
          ),
        );
        addTearDown(vm.dispose);
        await _abrirKanbanResponsivo(tester, vm, largura);
        expect(
          tester
              .widget<PopupMenuButton<DensidadeDemanda>>(
                find.byType(PopupMenuButton<DensidadeDemanda>),
              )
              .initialValue,
          DensidadeDemanda.compacta,
        );
        expect(
          find.byKey(const ValueKey('buscar-demandas')).hitTestable(),
          findsOneWidget,
        );
        if (largura < 600) {
          expect(find.byType(StatusTabs), findsOneWidget);
          expect(find.byType(KanbanColumn), findsNothing);
          expect(
            find.byKey(const ValueKey('demandas-quadro-scrollbar')),
            findsNothing,
          );
          expect(find.text('Demanda aberta'), findsOneWidget);
          final aba = find.descendant(
            of: find.byType(StatusTabs),
            matching: find.text('Concluída'),
          );
          await tester.ensureVisible(aba);
          await tester.tap(aba);
          await tester.pumpAndSettle();
          expect(find.text('Demanda concluída').hitTestable(), findsOneWidget);
          expect(find.text('Demanda aberta'), findsNothing);
          final quadro = find.byKey(const ValueKey('demandas-quadro-status'));
          await tester.fling(quadro, const Offset(250, 0), 1000);
          await tester.pumpAndSettle();
          expect(find.text('Demanda concluída'), findsNothing);
          final abaAberta = find.descendant(
            of: find.byType(StatusTabs),
            matching: find.text('Aberta'),
          );
          await tester.ensureVisible(abaAberta);
          await tester.tap(abaAberta);
          await tester.pumpAndSettle();
          expect(find.text('Demanda aberta').hitTestable(), findsOneWidget);
        } else {
          expect(find.byType(StatusTabs), findsNothing);
          expect(find.byType(KanbanColumn), findsNWidgets(5));
          double? larguraPreenchida;
          for (final status in backend.DemandaStatus.values) {
            final coluna = find.byKey(
              ValueKey('demanda-coluna-${status.name}'),
            );
            final kanban = tester.widget<KanbanColumn>(
              find.descendant(of: coluna, matching: find.byType(KanbanColumn)),
            );
            final preenchida =
                status == backend.DemandaStatus.aberta ||
                status == backend.DemandaStatus.concluida;
            expect(kanban.count, preenchida ? 1 : 0);
            expect(kanban.collapsed, !preenchida);
            final width = tester.getSize(coluna).width;
            if (preenchida) {
              expect(width, inInclusiveRange(260, 360));
              larguraPreenchida ??= width;
              expect(width, larguraPreenchida);
            } else {
              expect(width, 44);
            }
          }
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final largura in [390.0, 1200.0, 2400.0]) {
    testWidgets(
      'quadro normal com largura $largura preserva agrupamento e rolagem responsiva',
      (tester) async {
        final repository = FakeDemandaRepository(
          demandas: _demandasParaQuadro(),
        );
        final vm = DemandasViewModel(repository: repository);
        addTearDown(vm.dispose);
        await _abrirKanbanResponsivo(tester, vm, largura);
        await tester.tap(find.byTooltip('Densidade dos cards'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(
            CheckedPopupMenuItem<DensidadeDemanda>,
            'Visualização normal',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PopupMenuButton<DensidadeDemanda>>(
                find.byType(PopupMenuButton<DensidadeDemanda>),
              )
              .initialValue,
          DensidadeDemanda.normal,
        );
        if (largura < 600) {
          final aba = find.descendant(
            of: find.byType(StatusTabs),
            matching: find.text('Aberta'),
          );
          await tester.ensureVisible(aba);
          await tester.tap(aba);
          await tester.pumpAndSettle();
        }
        final quadro = find.byKey(const ValueKey('demandas-quadro-status'));
        final toolbar = find.byType(PageHeader);
        final posicaoToolbar = tester.getTopLeft(toolbar);
        final vertical = largura < 600
            ? _scrollNoEixo(tester, quadro, Axis.vertical)
            : _scrollNoEixo(
                tester,
                find.byKey(const ValueKey('demanda-coluna-aberta')),
                Axis.vertical,
              );
        expect(vertical.position.maxScrollExtent, greaterThan(0));
        expect(
          find.byKey(const ValueKey('demandas-pagina-scroll')),
          findsNothing,
        );
        final primeira = find.byKey(const ValueKey('demanda-card-1'));
        await tester.ensureVisible(primeira);
        await tester.tap(find.byKey(const ValueKey('expandir-demanda-1')));
        await tester.pumpAndSettle();
        final filha = find.byKey(const ValueKey('demanda-tree-node-100-1'));
        expect(filha, findsOneWidget);
        if (largura >= 600) {
          final coluna = find.byKey(const ValueKey('demanda-coluna-aberta'));
          expect(find.descendant(of: coluna, matching: filha), findsOneWidget);
          expect(
            tester
                .widget<GroupHeader>(
                  find.descendant(
                    of: coluna,
                    matching: find.byType(GroupHeader),
                  ),
                )
                .count,
            12,
          );
          expect(
            tester
                .getTopLeft(find.byKey(const ValueKey('demanda-card-100')))
                .dx,
            greaterThan(tester.getTopLeft(primeira).dx),
          );
          final horizontal = tester
              .widget<SingleChildScrollView>(quadro)
              .controller!;
          final barra = tester.widget<Scrollbar>(
            find.byKey(const ValueKey('demandas-quadro-scrollbar')),
          );
          expect(barra.controller, same(horizontal));
          expect(barra.thumbVisibility, isTrue);
          double ultimoX = double.negativeInfinity;
          for (final status in backend.DemandaStatus.values) {
            final grupo = find.byKey(ValueKey('demanda-coluna-${status.name}'));
            expect(tester.getSize(grupo).width, inInclusiveRange(260, 360));
            expect(tester.getTopLeft(grupo).dx, greaterThan(ultimoX));
            ultimoX = tester.getTopRight(grupo).dx;
            expect(
              tester
                  .widget<KanbanColumn>(
                    find.descendant(
                      of: grupo,
                      matching: find.byType(KanbanColumn),
                    ),
                  )
                  .count,
              status == backend.DemandaStatus.aberta ? 12 : 1,
            );
          }
          expect(horizontal.position.maxScrollExtent > 0, largura == 1200);
          if (horizontal.position.maxScrollExtent > 0) {
            final posicaoVerticalAntes = vertical.position.pixels;
            await tester.dragFrom(
              tester.getTopLeft(quadro) + const Offset(150, 20),
              const Offset(-400, 0),
            );
            await tester.pumpAndSettle();
            expect(horizontal.offset, greaterThan(0));
            expect(vertical.position.pixels, posicaoVerticalAntes);
            horizontal.jumpTo(0);
            await tester.pumpAndSettle();
          }
        } else {
          expect(find.byType(StatusTabs), findsOneWidget);
          expect(find.byType(KanbanColumn), findsNothing);
        }
        final topoQuadro = tester.getTopLeft(quadro);
        final topoPrimeira = tester.getTopLeft(primeira).dy;
        await tester.dragFrom(
          tester.getTopLeft(primeira) + const Offset(100, 40),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        expect(vertical.position.pixels, greaterThan(0));
        expect(tester.getTopLeft(primeira).dy, lessThan(topoPrimeira));
        expect(tester.getTopLeft(quadro), topoQuadro);
        expect(tester.getTopLeft(toolbar), posicaoToolbar);
        final ultimoCard = find.byKey(const ValueKey('demanda-card-12'));
        await tester.ensureVisible(ultimoCard);
        await tester.pumpAndSettle();
        expect(ultimoCard.hitTestable(), findsOneWidget);
        expect(vm.demandas, hasLength(17));
        expect(repository.chamadasAtualizar, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'barra horizontal fixa ganha destaque em hover e permite arraste',
    (tester) async {
      final vm = DemandasViewModel(
        repository: FakeDemandaRepository(demandas: _demandasParaQuadro()),
      );
      addTearDown(vm.dispose);
      await _abrirKanbanResponsivo(tester, vm, 1200);
      await tester.pump(const Duration(seconds: 3));
      final barra = find.byKey(const ValueKey('demandas-quadro-scrollbar'));
      final controller = tester.widget<Scrollbar>(barra).controller!;
      expect(controller.position.maxScrollExtent, greaterThan(0));
      expect(tester.getBottomLeft(barra).dy, lessThanOrEqualTo(900));
      final pintor = _pintorBarra(tester, barra);
      expect(pintor.thickness, 4);
      expect(pintor.color.a, closeTo(0.28, 0.01));
      expect(pintor.fadeoutOpacityAnimation.value, 1);
      final toolbar = tester.getTopLeft(find.byType(PageHeader));
      final ponto = tester.getBottomLeft(barra) + const Offset(20, -6);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(ponto);
      await tester.pumpAndSettle();
      expect(pintor.thickness, 9);
      expect(pintor.color.a, closeTo(0.60, 0.01));
      await mouse.down(ponto);
      await mouse.moveBy(const Offset(150, 0));
      await tester.pump();
      expect(controller.offset, greaterThan(0));
      expect(pintor.thickness, 9);
      expect(pintor.color.a, closeTo(0.75, 0.01));
      await mouse.moveBy(const Offset(1800, 0));
      await mouse.up();
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(controller.offset, controller.position.maxScrollExtent);
      expect(tester.getTopLeft(find.byType(PageHeader)), toolbar);
      expect(pintor.thickness, 4);
      expect(pintor.color.a, closeTo(0.28, 0.01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'barra horizontal e cabeçalhos ficam fixos durante a rolagem independente das colunas',
    (tester) async {
      final vm = DemandasViewModel(
        repository: FakeDemandaRepository(demandas: _demandasParaQuadro()),
      );
      addTearDown(vm.dispose);
      await _abrirKanbanResponsivo(tester, vm, 1200);
      final barra = find.byKey(const ValueKey('demandas-quadro-scrollbar'));
      final coluna = find.byKey(const ValueKey('demanda-coluna-aberta'));
      final header = find.descendant(
        of: coluna,
        matching: find.byType(GroupHeader),
      );
      final topoHeader = tester.getTopLeft(header);
      final limitesBarra = tester.getRect(barra);
      final alturaColuna = tester.getSize(coluna).height;
      final vertical = _scrollNoEixo(tester, coluna, Axis.vertical);
      final outra = _scrollNoEixo(
        tester,
        find.byKey(const ValueKey('demanda-coluna-emAndamento')),
        Axis.vertical,
      );
      final alcanceAntes = vertical.position.maxScrollExtent;
      await tester.tap(find.byKey(const ValueKey('expandir-demanda-1')));
      await tester.pumpAndSettle();
      expect(vertical.position.maxScrollExtent, greaterThan(alcanceAntes));
      expect(tester.getSize(coluna).height, alturaColuna);
      expect(tester.getRect(barra), limitesBarra);
      await tester.dragFrom(
        tester.getTopLeft(coluna) + const Offset(100, 100),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      expect(vertical.position.pixels, greaterThan(0));
      expect(outra.position.pixels, 0);
      expect(tester.getTopLeft(header), topoHeader);
      expect(tester.getRect(barra), limitesBarra);
      await tester.ensureVisible(find.byKey(const ValueKey('demanda-card-12')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('demanda-card-12')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.getRect(barra), limitesBarra);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quadro vazio oferece criação sem colunas ou contagens antigas', (
    tester,
  ) async {
    final vm = DemandasViewModel(repository: FakeDemandaRepository());
    addTearDown(vm.dispose);
    await _abrirKanbanResponsivo(tester, vm, 1200);
    expect(vm.demandas, isEmpty);
    expect(find.byType(DemandaCard), findsNothing);
    expect(find.byType(KanbanColumn), findsNothing);
    expect(find.byType(StatusTabs), findsNothing);
    expect(
      find.byKey(const ValueKey('demandas-quadro-scrollbar')),
      findsNothing,
    );
    expect(find.text('Nenhuma demanda ainda.'), findsOneWidget);
    expect(tester.widget<PageHeader>(find.byType(PageHeader)).count, 0);
    final criar = find.widgetWithText(TextButton, 'Criar demanda');
    expect(criar.hitTestable(), findsOneWidget);
    await tester.tap(criar);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(const ValueKey('criar-demanda')), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma demanda ainda.'), findsOneWidget);
    expect(vm.demandas, isEmpty);
    expect(tester.takeException(), isNull);
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

    expect(find.byKey(ValueKey('status-demanda-1')), findsNothing);
    await _expandirDemanda(tester, 'Mãe');
    expect(find.byKey(ValueKey('status-demanda-1')), findsOneWidget);
    await _expandirDemanda(tester, 'Mãe');
    expect(find.byKey(ValueKey('status-demanda-1')), findsNothing);

    await _expandirDemanda(tester, 'Mãe');
    expect(find.byKey(ValueKey('status-demanda-2')), findsNothing);
    await _expandirDemanda(tester, 'Filha');
    expect(find.byKey(ValueKey('status-demanda-2')), findsOneWidget);
    await _expandirDemanda(tester, 'Filha');
    expect(find.byKey(ValueKey('status-demanda-2')), findsNothing);
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
                find.descendant(of: coluna, matching: find.byType(GroupHeader)),
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
              find.descendant(
                of: card,
                matching: find.byKey(ValueKey('status-demanda-$id')),
              ),
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

    expect(find.text('Demanda #42'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('demanda-detalhe-dialog')),
      findsOneWidget,
    );
  });
}

List<backend.Demanda> _demandasParaQuadro() => [
  for (var id = 1; id <= 12; id++)
    demandaFixture(id: id, titulo: 'Demanda $id'),
  demandaFixture(
    id: 100,
    demandaPaiId: 1,
    titulo: 'Filha concluída',
    status: backend.DemandaStatus.concluida,
  ),
  for (final status in backend.DemandaStatus.values.where(
    (s) => s != backend.DemandaStatus.aberta,
  ))
    demandaFixture(
      id: 20 + status.index,
      titulo: 'Raiz ${status.name}',
      status: status,
    ),
];

Future<void> _abrirKanbanResponsivo(
  WidgetTester tester,
  DemandasViewModel vm,
  double largura,
) async {
  final dpr = largura < 600 ? 3.0 : 1.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(largura * dpr, 900 * dpr);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light.copyWith(platform: TargetPlatform.linux),
      home: DemandasPage(viewModel: vm),
    ),
  );
  await tester.pumpAndSettle();
  expect(
    MediaQuery.sizeOf(tester.element(find.byType(DemandasPage))),
    Size(largura, 900),
  );
}

ScrollableState _scrollNoEixo(WidgetTester tester, Finder dentro, Axis eixo) =>
    tester.state<ScrollableState>(
      find.descendant(
        of: dentro,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Scrollable && axisDirectionToAxis(w.axisDirection) == eixo,
        ),
      ),
    );

ScrollbarPainter _pintorBarra(WidgetTester tester, Finder barra) =>
    tester
            .widget<CustomPaint>(
              find
                  .descendant(
                    of: barra,
                    matching: find.byWidgetPredicate(
                      (widget) =>
                          widget is CustomPaint &&
                          widget.foregroundPainter is ScrollbarPainter,
                    ),
                  )
                  .first,
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
  final card = find
      .ancestor(
        of: find.textContaining(titulo),
        matching: find.byType(DemandaCard),
      )
      .first;
  final id = tester.widget<DemandaCard>(card).demanda.id;
  await tester.tap(find.byKey(ValueKey('expandir-demanda-$id')));
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
