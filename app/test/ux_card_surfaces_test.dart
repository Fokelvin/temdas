import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
import 'package:temdas/view/widgets/densidade_demanda.dart';
import 'package:temdas/view/widgets/log_time_calendar.dart';
import 'package:temdas/view_model/agenda_view_model.dart';

import 'support/fake_demanda_repository.dart' show demandaFixture;
import 'support/fake_agenda_repositories.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    for (final density in DensidadeDemanda.values) {
      testWidgets(
        'borda de Demanda herda tema ${theme.brightness} / $density e destaque substitui borda',
        (tester) async {
          Future<void> build(bool highlighted) => tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: DemandaCard(
                  demanda: demandaFixture(id: 1),
                  densidade: density,
                  destacado: highlighted,
                  tempoExecutadoTotalMinutos: 0,
                  onEditar: () {},
                  onExcluir: () {},
                  onConcluir: () {},
                  onAlterarStatus: (_) {},
                ),
              ),
            ),
          );
          await build(false);
          final card = tester.widget<Card>(find.byType(Card));
          expect(card.shape, isNull);
          final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
          expect(shape.side, TemdasTokens.subtleBorder(theme.colorScheme));
          await build(true);
          final selected =
              tester.widget<Card>(find.byType(Card)).shape!
                  as RoundedRectangleBorder;
          expect(selected.side.color, theme.colorScheme.primary);
          expect(selected.borderRadius, shape.borderRadius);
        },
      );
    }

    for (final minutos in [15, 30, 60, 120]) {
      for (final escala in [1.0, 1.5]) {
        testWidgets(
          'bloco Log Time usa borda sutil sem overflow ${theme.brightness}, $minutos min, escala $escala',
          (tester) async {
            final viewModel = AgendaViewModel(
              demandaRepository: FakeAgendaDemandaRepository(
                demandas: [
                  demandaAgendaFixture(
                    titulo:
                        'Demanda de integração com título longo para verificar a leitura no calendário',
                  ),
                ],
              ),
              registroTempoRepository: FakeRegistroTempoRepository(
                registros: [
                  registroTempoFixture(
                    id: 1,
                    inicioLocal: DateTime(2026, 9, 9, 9),
                    duracaoMinutos: minutos,
                  ),
                ],
              ),
              hoje: DateTime(2026, 9, 9),
            );
            addTearDown(viewModel.dispose);
            await viewModel.carregar();
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(escala)),
                  child: child!,
                ),
                home: Scaffold(
                  body: LogTimeCalendar(
                    viewModel: viewModel,
                    onEditar: (_) async {},
                    onExcluir: (_) async {},
                    onMover: (_, _, _) async => true,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final material = tester.widget<Material>(
              find
                  .ancestor(
                    of: find.byKey(const ValueKey('editar-registro-1')),
                    matching: find.byType(Material),
                  )
                  .first,
            );
            expect(
              (material.shape! as RoundedRectangleBorder).side,
              TemdasTokens.subtleBorder(theme.colorScheme),
            );
          },
        );
      }
    }
  }

  testWidgets(
    'compacto reduz alturas recolhida e expandida, preservando conteúdo e ações',
    (tester) async {
      final heights = <DensidadeDemanda, List<double>>{};
      var actions = 0;
      for (final density in DensidadeDemanda.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 304,
                  child: DemandaCard(
                    key: ValueKey(density),
                    demanda: demandaFixture(id: 1),
                    densidade: density,
                    tempoExecutadoTotalMinutos: 60,
                    onEditar: () {},
                    onExcluir: () {},
                    onConcluir: () {},
                    onAlterarStatus: (_) {},
                    onCriarFilha: () => actions++,
                    onLancarTempo: () => actions++,
                  ),
                ),
              ),
            ),
          ),
        );
        final card = find.byKey(const ValueKey('demanda-card-1'));
        final collapsed = tester.getSize(card).height;
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();
        heights[density] = [collapsed, tester.getSize(card).height];
        expect(find.text('Descrição: Descrição inicial'), findsOneWidget);
        expect(find.text('Observações: Observação preservada'), findsNothing);
        expect(find.byKey(const ValueKey('status-demanda-1')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('concluir-demanda-1')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('acoes-demanda-1')), findsOneWidget);
        for (final key in ['criar-filha-1', 'lancar-tempo-1']) {
          final button = find.byKey(ValueKey(key));
          await tester.ensureVisible(button);
          await tester.tap(button);
        }
        expect(tester.takeException(), isNull);
      }
      expect(actions, 4);
      for (var i = 0; i < 2; i++) {
        expect(
          heights[DensidadeDemanda.compacta]![i],
          lessThan(heights[DensidadeDemanda.normal]![i]),
        );
      }
    },
  );
}
