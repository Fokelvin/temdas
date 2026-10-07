import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/app/app_routes.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/sprint_page.dart';
import 'package:temdas/view_model/demanda_detalhe_view_model.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';
import 'support/fake_sprint_repository.dart';

void main() {
  testWidgets('lista Sprints reais e abre resumo e página completa', (
    tester,
  ) async {
    await _configurarTela(tester);
    final sprint = _sprint();
    final repository = FakeSprintRepository(
      sprints: [sprint],
      indicadoresPorId: {7: _indicadores()},
      vinculosPorSprint: {
        7: [
          backend.SprintDemanda(id: 1, sprintId: 7, demandaId: 11),
          backend.SprintDemanda(id: 2, sprintId: 7, demandaId: 12),
        ],
      },
    );
    final viewModel = SprintViewModel(repository: repository);
    final demandasRepository = FakeDemandaRepository(
      demandas: [
        demandaFixture(id: 11, titulo: 'Entrega'),
        demandaFixture(id: 12, demandaPaiId: 11, titulo: 'Validar entrega'),
      ],
    );
    final demandasViewModel = DemandasViewModel(repository: demandasRepository);
    final demandaDetalheViewModel = _criarDemandaDetalheViewModel(
      demandasRepository,
    );
    addTearDown(viewModel.dispose);
    addTearDown(demandasViewModel.dispose);
    addTearDown(demandaDetalheViewModel.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SprintPage(
          viewModel: viewModel,
          demandasViewModel: demandasViewModel,
          demandaDetalheViewModel: demandaDetalheViewModel,
        ),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.detalheDaSprint(7)) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => SprintDetalhePage(
                sprintId: 7,
                viewModel: viewModel,
                demandasViewModel: demandasViewModel,
                demandaDetalheViewModel: demandaDetalheViewModel,
              ),
            );
          }
          return AppRoutes.onGenerateRoute(settings);
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.chamadasListagem, 1);
    expect(find.text('Sprint Entrega Alpha'), findsOneWidget);
    expect(find.text('05/01/2026 – 12/01/2026'), findsOneWidget);
    expect(find.text('Ativa'), findsOneWidget);
    expect(find.text('Atrasada'), findsOneWidget);
    expect(find.text('4h'), findsOneWidget);
    expect(find.text('3h'), findsOneWidget);
    expect(find.text('2h30'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sprint-card-7')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('resumo-sprint-dialog')), findsOneWidget);
    expect(find.text('Sprint Entrega Alpha'), findsNWidgets(2));
    expect(find.text('Demandas vinculadas (2)'), findsOneWidget);
    expect(find.text('11 - Entrega'), findsOneWidget);
    expect(find.text('12 - Validar entrega'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mostrar-tudo-demandas-sprint-resumo')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('abrir-sprint-completa')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('demanda-vinculada-sprint-11')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('demanda-detalhe-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Fechar detalhes'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('abrir-sprint-completa')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sprint-detalhe-scroll')), findsOneWidget);
    expect(find.text('Tempo total estimado'), findsOneWidget);
    expect(find.text('Demandas vinculadas (2)'), findsOneWidget);
    expect(find.text('11 - Entrega'), findsOneWidget);
    expect(find.text('Gestão da Sprint'), findsNothing);
    expect(find.byKey(const ValueKey('editar-sprint')), findsOneWidget);
    expect(find.byKey(const ValueKey('concluir-sprint')), findsOneWidget);
  });

  testWidgets(
    'resumo mostra zero, uma, cinco ou somente cinco mais Mostrar tudo',
    (tester) async {
      await _configurarTela(tester);
      for (final quantidade in [0, 1, 5, 6]) {
        final sprintId = 500 + quantidade;
        final sprint = _sprint(
          id: sprintId,
          nome: 'Contagem $quantidade',
          status: backend.SprintStatus.planejada,
        );
        final demandas = [
          for (var indice = 0; indice < quantidade; indice++)
            demandaFixture(
              id: 1000 + indice,
              demandaPaiId: indice == 0 ? null : 1000,
              titulo: 'Item $indice',
            ),
        ];
        final repository = FakeDemandaRepository(demandas: demandas);
        final demandasViewModel = DemandasViewModel(repository: repository);
        final detalheViewModel = _criarDemandaDetalheViewModel(repository);
        final sprintRepository = FakeSprintRepository(
          sprints: [sprint],
          vinculosPorSprint: {
            sprintId: [
              for (var indice = 0; indice < quantidade; indice++)
                backend.SprintDemanda(
                  id: indice + 1,
                  sprintId: sprintId,
                  demandaId: 1000 + indice,
                ),
            ],
          },
        );
        final viewModel = SprintViewModel(repository: sprintRepository);
        addTearDown(demandasViewModel.dispose);
        addTearDown(detalheViewModel.dispose);
        addTearDown(viewModel.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: SprintPage(
              viewModel: viewModel,
              demandasViewModel: demandasViewModel,
              demandaDetalheViewModel: detalheViewModel,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('sprint-card-$sprintId')));
        await tester.pumpAndSettle();

        expect(find.text('Demandas vinculadas ($quantidade)'), findsOneWidget);
        if (quantidade == 0) {
          expect(
            find.text('Nenhuma Demanda vinculada à Sprint.'),
            findsOneWidget,
          );
        }
        for (var indice = 0; indice < quantidade && indice < 5; indice++) {
          expect(
            find.byKey(ValueKey('demanda-vinculada-sprint-${1000 + indice}')),
            findsOneWidget,
          );
        }
        expect(
          find.byKey(const ValueKey('mostrar-tudo-demandas-sprint-resumo')),
          quantidade > 5 ? findsOneWidget : findsNothing,
        );

        if (quantidade > 5) {
          await tester.tap(
            find.byKey(const ValueKey('mostrar-tudo-demandas-sprint-resumo')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('painel-lateral-demandas-sprint')),
            findsOneWidget,
          );
          for (var indice = 0; indice < quantidade; indice++) {
            expect(
              find.descendant(
                of: find.byKey(
                  const ValueKey('painel-lateral-demandas-sprint'),
                ),
                matching: find.byKey(
                  ValueKey('demanda-vinculada-sprint-${1000 + indice}'),
                ),
              ),
              findsOneWidget,
            );
          }
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('painel-lateral-demandas-sprint')),
              matching: find.byIcon(Icons.subdirectory_arrow_right),
            ),
            findsNWidgets(5),
          );
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('painel-lateral-demandas-sprint')),
              matching: find.byKey(const ValueKey('menu-demanda-sprint-1000')),
            ),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(const ValueKey('fechar-painel-demandas-sprint')),
          );
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'detalhe limita a cinco, mostra tudo e abre popup padrão da Demanda',
    (tester) async {
      await _configurarTela(tester);
      for (final quantidade in [0, 1, 5, 6]) {
        final demandas = [
          for (var indice = 0; indice < quantidade; indice++)
            demandaFixture(
              id: 1100 + indice,
              demandaPaiId: indice == 0 ? null : 1100,
              titulo: 'Detalhe $indice',
            ),
        ];
        final resultado = await _abrirDetalhe(
          tester,
          sprints: [_sprint(status: backend.SprintStatus.planejada)],
          demandas: demandas,
          vinculosPorSprint: {
            7: [
              for (var indice = 0; indice < quantidade; indice++)
                backend.SprintDemanda(
                  id: indice + 1,
                  sprintId: 7,
                  demandaId: 1100 + indice,
                ),
            ],
          },
        );
        addTearDown(resultado.viewModel.dispose);

        expect(find.text('Demandas vinculadas ($quantidade)'), findsOneWidget);
        for (var indice = 0; indice < quantidade && indice < 5; indice++) {
          expect(
            find.byKey(ValueKey('demanda-vinculada-sprint-${1100 + indice}')),
            findsOneWidget,
          );
        }
        expect(
          find.byKey(const ValueKey('mostrar-tudo-demandas-sprint')),
          quantidade > 5 ? findsOneWidget : findsNothing,
        );

        if (quantidade == 1) {
          await tester.tap(
            find.byKey(const ValueKey('demanda-vinculada-sprint-1100')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('demanda-detalhe-dialog')),
            findsOneWidget,
          );
          await tester.tap(find.byTooltip('Fechar detalhes'));
          await tester.pumpAndSettle();
        }
        if (quantidade > 5) {
          await tester.tap(
            find.byKey(const ValueKey('mostrar-tudo-demandas-sprint')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('painel-lateral-demandas-sprint')),
            findsOneWidget,
          );
          for (var indice = 0; indice < quantidade; indice++) {
            expect(
              find.descendant(
                of: find.byKey(
                  const ValueKey('painel-lateral-demandas-sprint'),
                ),
                matching: find.byKey(
                  ValueKey('demanda-vinculada-sprint-${1100 + indice}'),
                ),
              ),
              findsOneWidget,
            );
          }
          await tester.tap(
            find.descendant(
              of: find.byKey(const ValueKey('painel-lateral-demandas-sprint')),
              matching: find.byKey(
                const ValueKey('demanda-vinculada-sprint-1105'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('demanda-detalhe-dialog')),
            findsOneWidget,
          );
          await tester.tap(find.byTooltip('Fechar detalhes'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('fechar-painel-demandas-sprint')),
          );
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'painel de Sprint concluída mantém os vínculos somente para leitura',
    (tester) async {
      await _configurarTela(tester);
      final demandas = [
        for (var indice = 0; indice < 6; indice++)
          demandaFixture(
            id: 1200 + indice,
            demandaPaiId: indice == 0 ? null : 1200,
            titulo: 'Concluída $indice',
          ),
      ];
      final resultado = await _abrirDetalhe(
        tester,
        sprints: [_sprint(status: backend.SprintStatus.concluida)],
        demandas: demandas,
        vinculosPorSprint: {
          7: [
            for (var indice = 0; indice < 6; indice++)
              backend.SprintDemanda(
                id: indice + 1,
                sprintId: 7,
                demandaId: 1200 + indice,
              ),
          ],
        },
      );
      addTearDown(resultado.viewModel.dispose);

      await tester.tap(
        find.byKey(const ValueKey('mostrar-tudo-demandas-sprint')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('painel-lateral-demandas-sprint')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('painel-lateral-demandas-sprint')),
          matching: find.byKey(const ValueKey('menu-demanda-sprint-1200')),
        ),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('fechar-painel-demandas-sprint')),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets('busca somente Demandas raiz no seletor', (tester) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint()],
      demandas: [
        demandaFixture(id: 21, titulo: 'Épico mobile'),
        demandaFixture(id: 22, demandaPaiId: 21, titulo: 'Ajustar formulário'),
      ],
    );
    addTearDown(resultado.viewModel.dispose);

    await tester.tap(find.byKey(const ValueKey('adicionar-demanda-sprint')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('selecionar-demanda-sprint-dialog')),
      findsOneWidget,
    );
    expect(find.text('21 - Épico mobile'), findsOneWidget);
    expect(find.text('22 - Ajustar formulário'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('buscar-demanda-sprint')),
      'épico',
    );
    await tester.pumpAndSettle();

    expect(find.text('21 - Épico mobile'), findsOneWidget);
    expect(find.text('22 - Ajustar formulário'), findsNothing);
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('candidata-demanda-sprint-21')),
          )
          .enabled,
      isTrue,
    );
  });

  testWidgets(
    'envia somente a Demanda selecionada e recarrega árvore e horas',
    (tester) async {
      await _configurarTela(tester);
      final pai = demandaFixture(
        id: 31,
        titulo: 'Entrega da área',
        descricao: 'Texto longo não deve aparecer na árvore compacta.',
        tempoEstimadoMinutos: 95,
      );
      final filha = demandaFixture(
        id: 32,
        demandaPaiId: 31,
        titulo: 'Revisar tela',
        tempoEstimadoMinutos: 45,
      );
      final resultado = await _abrirDetalhe(
        tester,
        sprints: [_sprint()],
        demandas: [pai, filha],
        vinculosPorSprint: {7: []},
      );
      addTearDown(resultado.viewModel.dispose);
      resultado.repository.respostaVinculo = [
        backend.SprintDemanda(id: 1, sprintId: 7, demandaId: 31),
        backend.SprintDemanda(id: 2, sprintId: 7, demandaId: 32),
      ];
      final indicadoresAntes = resultado.repository.chamadasIndicadores;

      await tester.tap(find.byKey(const ValueKey('adicionar-demanda-sprint')));
      await tester.pumpAndSettle();
      expect(find.text('1h35 | + 1 demanda filha'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('candidata-demanda-sprint-32')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('candidata-demanda-sprint-31')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('confirmar-vinculo-demanda-sprint')),
      );
      await tester.pumpAndSettle();

      expect(resultado.repository.chamadasVinculoLote, 1);
      expect(resultado.repository.demandaIdsVinculadas, [31]);
      expect(resultado.repository.chamadasVinculos, greaterThanOrEqualTo(2));
      expect(resultado.repository.chamadasIndicadores, indicadoresAntes + 1);
      expect(find.text('31 - Entrega da área'), findsOneWidget);
      expect(find.text('32 - Revisar tela'), findsOneWidget);
      expect(find.byIcon(Icons.subdirectory_arrow_right), findsOneWidget);
      expect(find.text('Estimativa própria: 1h35'), findsOneWidget);
      expect(find.text('Estimativa própria: 45min'), findsOneWidget);
      expect(
        find.text('Texto longo não deve aparecer na árvore compacta.'),
        findsNothing,
      );
    },
  );

  testWidgets('seleciona várias Demandas e envia um único lote', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint()],
      demandas: [
        demandaFixture(id: 61, titulo: 'Primeira'),
        demandaFixture(id: 62, titulo: 'Segunda'),
      ],
      vinculosPorSprint: {7: []},
    );
    addTearDown(resultado.viewModel.dispose);

    await tester.tap(find.byKey(const ValueKey('adicionar-demanda-sprint')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('candidata-demanda-sprint-61')));
    await tester.tap(find.byKey(const ValueKey('candidata-demanda-sprint-62')));
    await tester.pumpAndSettle();

    expect(find.text('Vincular (2)'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('confirmar-vinculo-demanda-sprint')),
    );
    await tester.pumpAndSettle();

    expect(resultado.repository.chamadasVinculoLote, 1);
    expect(resultado.repository.demandaIdsVinculadas, [61, 62]);
    expect(resultado.repository.chamadasVinculo, 0);
  });

  testWidgets('oculta raízes e árvores já vinculadas à Sprint atual', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint()],
      demandas: [
        demandaFixture(id: 91, titulo: 'Já vinculada'),
        demandaFixture(id: 92, demandaPaiId: 91, titulo: 'Filha vinculada'),
        demandaFixture(id: 93, titulo: 'Disponível'),
      ],
      vinculosPorSprint: {
        7: [
          backend.SprintDemanda(id: 1, sprintId: 7, demandaId: 91),
          backend.SprintDemanda(id: 2, sprintId: 7, demandaId: 92),
        ],
      },
    );
    addTearDown(resultado.viewModel.dispose);

    await tester.tap(find.byKey(const ValueKey('adicionar-demanda-sprint')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('candidata-demanda-sprint-91')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('candidata-demanda-sprint-92')),
      findsNothing,
    );
    final dialog = find.byKey(
      const ValueKey('selecionar-demanda-sprint-dialog'),
    );
    expect(
      find.descendant(of: dialog, matching: find.text('91 - Já vinculada')),
      findsNothing,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('93 - Disponível')),
      findsOneWidget,
    );
  });

  testWidgets('exibe estado vazio quando todas as raízes já estão vinculadas', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint()],
      demandas: [demandaFixture(id: 94, titulo: 'Única raiz')],
      vinculosPorSprint: {
        7: [backend.SprintDemanda(id: 1, sprintId: 7, demandaId: 94)],
      },
    );
    addTearDown(resultado.viewModel.dispose);

    await tester.tap(find.byKey(const ValueKey('adicionar-demanda-sprint')));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma Demanda encontrada.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('arvore-selecao-demandas-sprint')),
      findsNothing,
    );
  });

  testWidgets('desabilita Demanda já vinculada a outra Sprint aberta', (
    tester,
  ) async {
    await _configurarTela(tester);
    final candidata = demandaFixture(id: 41, titulo: 'Demanda ocupada');
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [
        _sprint(status: backend.SprintStatus.planejada),
        _sprint(
          id: 8,
          nome: 'Outra aberta',
          status: backend.SprintStatus.ativa,
        ),
      ],
      demandas: [candidata],
      vinculosPorSprint: {
        7: [],
        8: [backend.SprintDemanda(id: 3, sprintId: 8, demandaId: 41)],
      },
    );
    addTearDown(resultado.viewModel.dispose);

    await tester.tap(find.byKey(const ValueKey('adicionar-demanda-sprint')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('candidata-demanda-sprint-41')),
          )
          .enabled,
      isFalse,
    );
    expect(find.text('Já pertence à Sprint Outra aberta'), findsOneWidget);
  });

  testWidgets('mostra erro amigável quando o backend rejeita o vínculo', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint()],
      demandas: [demandaFixture(id: 45, titulo: 'Demanda ocupada')],
    );
    addTearDown(resultado.viewModel.dispose);
    resultado.repository.erroVinculo = StateError('erro interno');

    await tester.tap(find.byKey(const ValueKey('adicionar-demanda-sprint')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('candidata-demanda-sprint-45')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('confirmar-vinculo-demanda-sprint')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('erro-vinculo-demanda-sprint')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selecionar-demanda-sprint-dialog')),
      findsOneWidget,
    );
  });

  testWidgets('mostra a contagem recursiva de descendentes da raiz', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint()],
      demandas: [
        demandaFixture(
          id: 81,
          titulo: 'Com descendentes',
          tempoEstimadoMinutos: 60,
        ),
        demandaFixture(id: 82, demandaPaiId: 81, titulo: 'Filha'),
        demandaFixture(id: 83, demandaPaiId: 82, titulo: 'Neta'),
        demandaFixture(
          id: 84,
          titulo: 'Sem descendentes',
          tempoEstimadoMinutos: 60,
        ),
      ],
    );
    addTearDown(resultado.viewModel.dispose);

    await tester.tap(find.byKey(const ValueKey('adicionar-demanda-sprint')));
    await tester.pumpAndSettle();

    expect(find.text('1h | + 2 demandas filhas'), findsOneWidget);
    expect(find.text('1h'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('candidata-demanda-sprint-82')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('candidata-demanda-sprint-83')),
      findsNothing,
    );
  });

  testWidgets('Sprint concluída ou cancelada não expõe mudanças de vínculo', (
    tester,
  ) async {
    await _configurarTela(tester);
    for (final status in [
      backend.SprintStatus.concluida,
      backend.SprintStatus.cancelada,
    ]) {
      final resultado = await _abrirDetalhe(
        tester,
        sprints: [_sprint(status: status)],
        demandas: [demandaFixture(id: 51)],
        vinculosPorSprint: {
          7: [backend.SprintDemanda(id: 1, sprintId: 7, demandaId: 51)],
        },
      );
      addTearDown(resultado.viewModel.dispose);
      expect(
        find.byKey(const ValueKey('adicionar-demanda-sprint')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('menu-demanda-sprint-51')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'menu mantém Backlog desativado e desvincula pelo SprintViewModel',
    (tester) async {
      await _configurarTela(tester);
      final resultado = await _abrirDetalhe(
        tester,
        sprints: [_sprint()],
        demandas: [demandaFixture(id: 61, titulo: 'Operação Sprint')],
        vinculosPorSprint: {
          7: [backend.SprintDemanda(id: 1, sprintId: 7, demandaId: 61)],
        },
      );
      addTearDown(resultado.viewModel.dispose);

      await tester.tap(find.byKey(const ValueKey('menu-demanda-sprint-61')));
      await tester.pumpAndSettle();
      expect(find.text('Excluir permanentemente'), findsOneWidget);
      expect(find.text('Enviar para Backlog'), findsOneWidget);
      expect(find.text('Desvincular da Sprint'), findsOneWidget);
      expect(
        tester
            .widget<PopupMenuItem<dynamic>>(
              find.byKey(const ValueKey('menu-backlog-demanda-sprint-61')),
            )
            .enabled,
        isFalse,
      );
      await tester.tap(
        find.byKey(const ValueKey('menu-desvincular-demanda-sprint-61')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('confirmar-desvincular-demanda-61')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('confirmar-desvincular-demanda-61-confirmar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(resultado.repository.chamadasDesvinculo, 1);
      expect(resultado.repository.demandaIdDesvinculada, 61);
      expect(resultado.demandasRepository.chamadasExcluir, 0);
      expect(resultado.demandasRepository.chamadasExcluirArvore, 0);
    },
  );

  testWidgets('exclusão permanente reutiliza exclusão normal da árvore', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint()],
      demandas: [
        demandaFixture(id: 71, titulo: 'Pai'),
        demandaFixture(id: 72, demandaPaiId: 71, titulo: 'Filha'),
      ],
      vinculosPorSprint: {
        7: [
          backend.SprintDemanda(id: 1, sprintId: 7, demandaId: 71),
          backend.SprintDemanda(id: 2, sprintId: 7, demandaId: 72),
        ],
      },
    );
    addTearDown(resultado.viewModel.dispose);

    await tester.tap(find.byKey(const ValueKey('menu-demanda-sprint-71')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('menu-excluir-demanda-sprint-71')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('confirmar-excluir-demanda-sprint-71')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const ValueKey('confirmar-excluir-demanda-sprint-71-confirmar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(resultado.demandasRepository.chamadasExcluirArvore, 1);
    expect(resultado.demandasRepository.ultimoIdArvoreExcluida, 71);
    expect(resultado.demandasRepository.chamadasExcluir, 0);
    expect(resultado.repository.chamadasDesvinculo, 0);
  });

  testWidgets('mostra ações do cabeçalho conforme o status', (tester) async {
    await _configurarTela(tester);
    for (final status in backend.SprintStatus.values) {
      final resultado = await _abrirDetalhe(
        tester,
        sprints: [_sprint(status: status)],
      );
      final viewModel = resultado.viewModel;
      addTearDown(viewModel.dispose);

      expect(find.byKey(const ValueKey('editar-sprint')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('iniciar-sprint')),
        status == backend.SprintStatus.planejada
            ? findsOneWidget
            : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('concluir-sprint')),
        status == backend.SprintStatus.ativa ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('reabrir-sprint')),
        status == backend.SprintStatus.cancelada
            ? findsOneWidget
            : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('acoes-sprint')),
        status == backend.SprintStatus.concluida
            ? findsNothing
            : findsOneWidget,
      );
      if (status != backend.SprintStatus.concluida) {
        await tester.tap(find.byKey(const ValueKey('acoes-sprint')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu-excluir-sprint')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('menu-cancelar-sprint')),
          status == backend.SprintStatus.planejada ||
                  status == backend.SprintStatus.ativa
              ? findsOneWidget
              : findsNothing,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('edita dados de Sprint concluída e recarrega indicadores', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint(status: backend.SprintStatus.concluida)],
    );
    addTearDown(resultado.viewModel.dispose);
    final repository = resultado.repository;

    await tester.tap(find.byKey(const ValueKey('editar-sprint')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('editar-sprint-dialog')), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('criar-sprint-nome')),
          )
          .controller!
          .text,
      'Entrega Alpha',
    );
    await tester.enterText(
      find.byKey(const ValueKey('criar-sprint-nome')),
      'Entrega Revisada',
    );
    await tester.enterText(
      find.byKey(const ValueKey('criar-sprint-data-inicio')),
      '06/01/2026',
    );
    await tester.enterText(
      find.byKey(const ValueKey('criar-sprint-data-fim')),
      '13/01/2026',
    );
    await tester.enterText(
      find.byKey(const ValueKey('criar-sprint-tempo')),
      '3h15',
    );
    await tester.tap(find.byKey(const ValueKey('salvar-edicao-sprint')));
    await tester.pumpAndSettle();

    expect(repository.chamadasAtualizacao, 1);
    expect(repository.nomeAtualizado, 'Entrega Revisada');
    expect(repository.tempoPrevistoEnviado, 195);
    expect(repository.chamadasBusca, 2);
    expect(repository.chamadasIndicadores, 2);
    expect(find.text('Sprint Entrega Revisada'), findsOneWidget);
    expect(find.text('Concluída'), findsOneWidget);
  });

  testWidgets('confirma início e recarrega Sprint e indicadores', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint(status: backend.SprintStatus.planejada)],
    );
    addTearDown(resultado.viewModel.dispose);
    final repository = resultado.repository;

    await tester.tap(find.byKey(const ValueKey('iniciar-sprint')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('confirmar-inicio-sprint-dialog')),
      findsOneWidget,
    );
    expect(repository.chamadasAtivacao, 0);
    await tester.tap(
      find.byKey(const ValueKey('confirmar-inicio-sprint-dialog-confirmar')),
    );
    await tester.pumpAndSettle();

    expect(repository.chamadasAtivacao, 1);
    expect(repository.sprints.single.status, backend.SprintStatus.ativa);
    expect(repository.chamadasBusca, 2);
    expect(repository.chamadasIndicadores, 2);
    expect(find.byKey(const ValueKey('concluir-sprint')), findsOneWidget);
  });

  testWidgets('confirma cancelamento e reabertura', (tester) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint(status: backend.SprintStatus.ativa)],
    );
    addTearDown(resultado.viewModel.dispose);
    final repository = resultado.repository;

    await tester.tap(find.byKey(const ValueKey('acoes-sprint')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-cancelar-sprint')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('confirmar-cancelamento-sprint-dialog')),
      findsOneWidget,
    );
    expect(repository.chamadasCancelamento, 0);
    await tester.tap(
      find.byKey(
        const ValueKey('confirmar-cancelamento-sprint-dialog-confirmar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.chamadasCancelamento, 1);
    expect(repository.sprints.single.status, backend.SprintStatus.cancelada);
    expect(repository.chamadasIndicadores, 2);

    await tester.tap(find.byKey(const ValueKey('reabrir-sprint')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('confirmar-reabertura-sprint-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const ValueKey('confirmar-reabertura-sprint-dialog-confirmar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.chamadasReabertura, 1);
    expect(repository.sprints.single.status, backend.SprintStatus.planejada);
    expect(repository.chamadasIndicadores, 3);
  });

  testWidgets('mostra erro amigável quando o backend rejeita uma ação', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint(status: backend.SprintStatus.ativa)],
    );
    addTearDown(resultado.viewModel.dispose);
    final repository = resultado.repository
      ..erroCancelamento = StateError('detalhe interno');

    await tester.tap(find.byKey(const ValueKey('acoes-sprint')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-cancelar-sprint')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('confirmar-cancelamento-sprint-dialog-confirmar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível cancelar a sprint. Tente novamente.'),
      findsOneWidget,
    );
    expect(repository.sprints.single.status, backend.SprintStatus.ativa);
  });

  testWidgets('conclusão mostra Demandas pendentes e comparação de horas', (
    tester,
  ) async {
    await _configurarTela(tester);
    final indicadores = _indicadores(diferenca: -30);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint(status: backend.SprintStatus.ativa)],
      indicadoresPorId: {7: indicadores},
    );
    addTearDown(resultado.viewModel.dispose);
    final repository = resultado.repository;

    await tester.tap(find.byKey(const ValueKey('concluir-sprint')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('confirmar-conclusao-sprint-dialog')),
      findsOneWidget,
    );
    expect(find.text('Há 2 Demandas não concluídas.'), findsOneWidget);
    expect(find.text('Executado abaixo do estimado em 30min.'), findsOneWidget);
    expect(repository.chamadasConclusao, 0);
    await tester.tap(find.byKey(const ValueKey('confirmar-conclusao-sprint')));
    await tester.pumpAndSettle();

    expect(repository.chamadasResumoConclusao, 1);
    expect(repository.chamadasConclusao, 1);
    expect(repository.sprints.single.status, backend.SprintStatus.concluida);
    expect(repository.chamadasIndicadores, 2);
  });

  testWidgets('conclusão alerta quando tempo executado passa do estimado', (
    tester,
  ) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint(status: backend.SprintStatus.ativa)],
      indicadoresPorId: {7: _indicadores(diferenca: 45)},
    );
    addTearDown(resultado.viewModel.dispose);

    await tester.tap(find.byKey(const ValueKey('concluir-sprint')));
    await tester.pumpAndSettle();
    expect(find.text('Executado acima do estimado em 45min.'), findsOneWidget);
    expect(
      find.text('Essa diferença não impede a conclusão da Sprint.'),
      findsOneWidget,
    );
  });

  testWidgets('exclusão exige confirmação e volta à lista', (tester) async {
    await _configurarTela(tester);
    final resultado = await _abrirDetalhe(
      tester,
      sprints: [_sprint(status: backend.SprintStatus.planejada)],
    );
    addTearDown(resultado.viewModel.dispose);
    final repository = resultado.repository;

    await tester.tap(find.byKey(const ValueKey('acoes-sprint')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-excluir-sprint')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('confirmar-exclusao-sprint-dialog')),
      findsOneWidget,
    );
    expect(repository.chamadasExclusao, 0);
    await tester.tap(
      find.byKey(const ValueKey('confirmar-exclusao-sprint-dialog-confirmar')),
    );
    await tester.pumpAndSettle();

    expect(repository.chamadasExclusao, 1);
    expect(repository.sprints, isEmpty);
    expect(find.text('Nenhuma Sprint cadastrada'), findsOneWidget);
  });

  for (final (chave, rotulo) in [
    ('ajustar-sprint-ativa', 'Ajustar Sprint atual'),
    ('finalizar-sprint-ativa', 'Finalizar Sprint atual'),
    ('cancelar-sprint-ativa', 'Cancelar Sprint atual'),
  ]) {
    testWidgets('$rotulo navega para a Sprint ativa sem iniciar a planejada', (
      tester,
    ) async {
      await _configurarTela(tester);
      final resultado = await _abrirDetalhe(
        tester,
        sprints: [
          _sprint(status: backend.SprintStatus.planejada),
          _sprint(
            id: 8,
            nome: 'Em execução',
            status: backend.SprintStatus.ativa,
          ),
        ],
      );
      addTearDown(resultado.viewModel.dispose);
      final repository = resultado.repository;

      await tester.tap(find.byKey(const ValueKey('iniciar-sprint')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sprint-ativa-existente-dialog')),
        findsOneWidget,
      );
      expect(
        find.text('Sprint Em execução está ativa. Abra-a para continuar.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ValueKey(chave)));
      await tester.pumpAndSettle();

      expect(find.text('Sprint Em execução'), findsOneWidget);
      expect(repository.chamadasAtivacao, 0);
      expect(repository.sprints.first.status, backend.SprintStatus.planejada);
    });
  }

  testWidgets('mostra loading, estado vazio e erro com tentativa novamente', (
    tester,
  ) async {
    await _configurarTela(tester);
    final repository = FakeSprintRepository(sprints: []);
    final resposta = Completer<List<backend.Sprint>>();
    repository.listaPendente = resposta;
    final viewModel = SprintViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SprintPage(viewModel: viewModel),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('carregando-sprints')), findsOneWidget);

    resposta.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma Sprint cadastrada'), findsOneWidget);
    expect(find.byKey(const ValueKey('nova-sprint')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nova-sprint')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('criar-sprint-dialog')), findsOneWidget);
    expect(find.byKey(const ValueKey('criar-sprint-nome')), findsOneWidget);
    expect(find.text('Status'), findsNothing);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nova-sprint-vazia')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('criar-sprint-dialog')), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.chamadasListagem, 1);

    repository.erroListagem = StateError('falha remota');
    await tester.tap(find.byKey(const ValueKey('recarregar-sprints')));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar as Sprints'), findsOneWidget);

    repository.erroListagem = null;
    await tester.tap(find.byKey(const ValueKey('tentar-carregar-sprints')));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma Sprint cadastrada'), findsOneWidget);
  });

  testWidgets('valida nome, datas e período antes de chamar o backend', (
    tester,
  ) async {
    await _configurarTela(tester);
    final repository = FakeSprintRepository(sprints: []);
    final viewModel = SprintViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await _abrirTelaComCriacao(tester, viewModel);
    await tester.tap(find.byKey(const ValueKey('salvar-sprint')));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome da Sprint.'), findsOneWidget);
    expect(find.text('Informe uma data de início válida.'), findsOneWidget);
    expect(find.text('Informe uma data de fim válida.'), findsOneWidget);
    expect(repository.chamadasCriacao, 0);

    await tester.enterText(
      find.byKey(const ValueKey('criar-sprint-nome')),
      'Entrega Delta',
    );
    await tester.enterText(
      find.byKey(const ValueKey('criar-sprint-data-inicio')),
      '10/10/2026',
    );
    await tester.enterText(
      find.byKey(const ValueKey('criar-sprint-data-fim')),
      '09/10/2026',
    );
    await tester.tap(find.byKey(const ValueKey('salvar-sprint')));
    await tester.pumpAndSettle();
    expect(
      find.text('A data de início não pode ser posterior à data fim.'),
      findsOneWidget,
    );
    expect(repository.chamadasCriacao, 0);

    await tester.enterText(
      find.byKey(const ValueKey('criar-sprint-data-fim')),
      '12/10/2026',
    );
    await tester.enterText(
      find.byKey(const ValueKey('criar-sprint-tempo')),
      'abc',
    );
    await tester.tap(find.byKey(const ValueKey('salvar-sprint')));
    await tester.pumpAndSettle();
    expect(find.text('Informe um tempo válido.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('criar-sprint-tempo')),
      '0min',
    );
    await tester.tap(find.byKey(const ValueKey('salvar-sprint')));
    await tester.pumpAndSettle();
    expect(
      find.text('Informe um tempo previsto maior que zero.'),
      findsOneWidget,
    );
    expect(repository.chamadasCriacao, 0);
  });

  testWidgets('aceita durações livres em minutos, horas e sem estimativa', (
    tester,
  ) async {
    await _configurarTela(tester);
    final repository = FakeSprintRepository(sprints: []);
    final viewModel = SprintViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    const duracoes = <String, int?>{
      '': null,
      '45min': 45,
      '1h15': 75,
      '2h10': 130,
    };
    await _abrirTelaComCriacao(tester, viewModel);
    var indice = 0;
    for (final duracao in duracoes.entries) {
      if (indice > 0) {
        await tester.tap(find.text('Fechar'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nova-sprint')));
        await tester.pumpAndSettle();
      }

      await _preencherFormCriacao(
        tester,
        nome: 'Tempo $indice',
        tempo: duracao.key,
      );
      await tester.tap(find.byKey(const ValueKey('salvar-sprint')));
      await tester.pumpAndSettle();

      expect(repository.tempoPrevistoEnviado, duracao.value);
      expect(repository.chamadasCriacao, indice + 1);
      expect(
        find.byKey(const ValueKey('resumo-sprint-dialog')),
        findsOneWidget,
      );
      indice++;
    }
  });

  testWidgets('cria, recarrega a lista e abre o resumo da Sprint', (
    tester,
  ) async {
    await _configurarTela(tester);
    final repository = FakeSprintRepository(sprints: []);
    final viewModel = SprintViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await _abrirTelaComCriacao(tester, viewModel);
    await _preencherFormCriacao(tester);
    await tester.tap(find.byKey(const ValueKey('salvar-sprint')));
    await tester.pumpAndSettle();

    expect(repository.chamadasCriacao, 1);
    expect(repository.nomeEnviado, 'Entrega Delta');
    expect(repository.dataInicioEnviada, DateTime(2026, 10, 5));
    expect(repository.dataFimEnviada, DateTime(2026, 10, 9));
    expect(repository.tempoPrevistoEnviado, 90);
    expect(repository.chamadasListagem, 2);
    expect(find.byKey(const ValueKey('resumo-sprint-dialog')), findsOneWidget);
    expect(find.text('Sprint Entrega Delta'), findsNWidgets(2));
    expect(find.text('05/10/2026 – 09/10/2026'), findsNWidgets(2));
  });

  testWidgets('exibe erro amigável do backend e mantém o diálogo aberto', (
    tester,
  ) async {
    await _configurarTela(tester);
    final repository = FakeSprintRepository(sprints: [])
      ..erroCriacao = StateError('detalhe interno do servidor');
    final viewModel = SprintViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await _abrirTelaComCriacao(tester, viewModel);
    await _preencherFormCriacao(tester);
    await tester.tap(find.byKey(const ValueKey('salvar-sprint')));
    await tester.pumpAndSettle();

    expect(repository.chamadasCriacao, 1);
    expect(find.byKey(const ValueKey('criar-sprint-dialog')), findsOneWidget);
    expect(find.byKey(const ValueKey('criar-sprint-erro')), findsOneWidget);
  });

  testWidgets('impede submissão duplicada enquanto cria a Sprint', (
    tester,
  ) async {
    await _configurarTela(tester);
    final repository = FakeSprintRepository(sprints: [])
      ..criacaoPendente = Completer<void>();
    final viewModel = SprintViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await _abrirTelaComCriacao(tester, viewModel);
    await _preencherFormCriacao(tester);
    await tester.tap(find.byKey(const ValueKey('salvar-sprint')));
    await tester.pump();
    expect(find.text('Criando...'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('salvar-sprint')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('salvar-sprint')));
    expect(repository.chamadasCriacao, 1);
    repository.criacaoPendente!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('resumo-sprint-dialog')), findsOneWidget);
  });
}

Future<void> _configurarTela(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 960));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<
  ({
    SprintViewModel viewModel,
    FakeSprintRepository repository,
    DemandasViewModel demandasViewModel,
    FakeDemandaRepository demandasRepository,
    DemandaDetalheViewModel demandaDetalheViewModel,
  })
>
_abrirDetalhe(
  WidgetTester tester, {
  required List<backend.Sprint> sprints,
  Map<int, backend.SprintIndicadores> indicadoresPorId = const {},
  Map<int, List<backend.SprintDemanda>> vinculosPorSprint = const {},
  List<backend.Demanda> demandas = const [],
}) async {
  final repository = FakeSprintRepository(
    sprints: sprints,
    indicadoresPorId: indicadoresPorId,
    vinculosPorSprint: vinculosPorSprint,
  );
  final viewModel = SprintViewModel(repository: repository);
  final demandasRepository = FakeDemandaRepository(demandas: demandas);
  final demandasViewModel = DemandasViewModel(repository: demandasRepository);
  final demandaDetalheViewModel = _criarDemandaDetalheViewModel(
    demandasRepository,
  );
  addTearDown(demandasViewModel.dispose);
  addTearDown(demandaDetalheViewModel.dispose);
  final sprintId = sprints.first.id!;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: SprintDetalhePage(
        sprintId: sprintId,
        viewModel: viewModel,
        demandasViewModel: demandasViewModel,
        demandaDetalheViewModel: demandaDetalheViewModel,
      ),
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        final segmentos = uri?.pathSegments;
        if (segmentos != null &&
            segmentos.length == 2 &&
            segmentos.first == 'sprint') {
          final id = int.tryParse(segmentos.last);
          if (id != null) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => SprintDetalhePage(
                sprintId: id,
                viewModel: viewModel,
                demandasViewModel: demandasViewModel,
                demandaDetalheViewModel: demandaDetalheViewModel,
              ),
            );
          }
        }
        if (settings.name == AppRoutes.sprint) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => SprintPage(
              viewModel: viewModel,
              demandasViewModel: demandasViewModel,
              demandaDetalheViewModel: demandaDetalheViewModel,
            ),
          );
        }
        return null;
      },
    ),
  );
  await tester.pumpAndSettle();
  return (
    viewModel: viewModel,
    repository: repository,
    demandasViewModel: demandasViewModel,
    demandasRepository: demandasRepository,
    demandaDetalheViewModel: demandaDetalheViewModel,
  );
}

DemandaDetalheViewModel _criarDemandaDetalheViewModel(
  FakeDemandaRepository demandasRepository,
) => DemandaDetalheViewModel(
  demandaRepository: demandasRepository,
  registroTempoRepository: FakeRegistroTempoRepository(),
);

Future<void> _abrirTelaComCriacao(
  WidgetTester tester,
  SprintViewModel viewModel,
) async {
  final demandasRepository = FakeDemandaRepository();
  final demandasViewModel = DemandasViewModel(repository: demandasRepository);
  final demandaDetalheViewModel = _criarDemandaDetalheViewModel(
    demandasRepository,
  );
  addTearDown(demandasViewModel.dispose);
  addTearDown(demandaDetalheViewModel.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: SprintPage(
        viewModel: viewModel,
        demandasViewModel: demandasViewModel,
        demandaDetalheViewModel: demandaDetalheViewModel,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('nova-sprint')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('criar-sprint-dialog')), findsOneWidget);
}

Future<void> _preencherFormCriacao(
  WidgetTester tester, {
  String nome = '  Entrega Delta  ',
  String tempo = '1,5',
}) async {
  await tester.enterText(find.byKey(const ValueKey('criar-sprint-nome')), nome);
  await tester.enterText(
    find.byKey(const ValueKey('criar-sprint-data-inicio')),
    '05/10/2026',
  );
  await tester.enterText(
    find.byKey(const ValueKey('criar-sprint-data-fim')),
    '09/10/2026',
  );
  await tester.enterText(
    find.byKey(const ValueKey('criar-sprint-tempo')),
    tempo,
  );
}

backend.Sprint _sprint({
  int id = 7,
  String nome = 'Entrega Alpha',
  backend.SprintStatus status = backend.SprintStatus.ativa,
}) => backend.Sprint(
  usuarioId: 1,
  id: id,
  nome: nome,
  dataInicio: DateTime.utc(2026, 1, 5),
  dataFim: DateTime.utc(2026, 1, 12),
  tempoPrevistoMinutos: 240,
  status: status,
);

backend.SprintIndicadores _indicadores({int diferenca = -30}) =>
    backend.SprintIndicadores(
      tempoPrevistoMinutos: 240,
      tempoTotalEstimadoMinutos: 180,
      tempoExecutadoMinutos: 180 + diferenca,
      diferencaExecutadoEstimadoMinutos: diferenca,
    );
