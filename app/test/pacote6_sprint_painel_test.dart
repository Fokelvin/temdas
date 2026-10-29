import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/sprint_page.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view_model/largura_painel_demanda.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;
import 'support/fake_sprint_repository.dart';
import 'support/fake_demanda_repository.dart';
import 'demanda_painel_test.dart' as detalhes;

b.Sprint sprint() => b.Sprint(
  id: 7,
  usuarioId: 1,
  nome: 'Entrega responsiva',
  status: b.SprintStatus.ativa,
  dataInicio: DateTime(2026, 9, 1),
  dataFim: DateTime(2026, 9, 7),
  tempoPrevistoMinutos: 120,
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('larguras de Sprint e Demanda são independentes', () async {
    SharedPreferences.setMockInitialValues({
      LarguraPainelDemanda.storageKey: 600.0,
    });
    final demanda = LarguraPainelDemanda(),
        sprint = LarguraPainelDemanda(
          preferenceKey: 'temdas.sprint.painel.largura',
        );
    addTearDown(demanda.dispose);
    addTearDown(sprint.dispose);
    await demanda.load();
    await sprint.load();
    expect(demanda.value, 600);
    expect(sprint.value, 420);
    sprint.ajustar(700, 1440);
    await sprint.salvar();
    expect(demanda.value, 600);
    expect(
      (await SharedPreferences.getInstance()).getDouble(
        LarguraPainelDemanda.storageKey,
      ),
      600,
    );
  });
  testWidgets(
    'painel com contexto novo consulta outras Sprints antes de permitir início',
    (tester) async {
      final planned = sprint().copyWith(status: b.SprintStatus.planejada);
      final repo = FakeSprintRepository(
        sprints: [planned, sprint().copyWith(id: 9)],
      );
      final vm = SprintViewModel(repository: repo);
      final dvm = DemandasViewModel(
        repository: FakeDemandaRepository(demandas: []),
      );
      addTearDown(vm.dispose);
      addTearDown(dvm.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SprintDetalhePage(
            painel: true,
            sprintId: 7,
            viewModel: vm,
            demandasViewModel: dvm,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.chamadasListagem, 1);
      expect(find.byKey(const ValueKey('iniciar-sprint-resumo')), findsNothing);
      expect(find.byKey(const ValueKey('editar-sprint')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [
    const Size(320, 700),
    const Size(768, 700),
    const Size(1440, 900),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('Sprint ↔ Demanda e resize em $size / escuro=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = FakeSprintRepository(
          sprints: [sprint()],
          vinculosPorSprint: {
            7: [b.SprintDemanda(sprintId: 7, demandaId: 1)],
          },
        );
        final vm = SprintViewModel(repository: repo);
        final dvm = DemandasViewModel(
          repository: FakeDemandaRepository(demandas: [demandaFixture(id: 1)]),
        );
        final detail = detalhes.model();
        addTearDown(vm.dispose);
        addTearDown(dvm.dispose);
        addTearDown(detail.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: SprintPage(
              viewModel: vm,
              demandasViewModel: dvm,
              demandaDetalheViewModel: detail,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('sprint-card-7')));
        await tester.pumpAndSettle();
        final panel = find.byKey(const ValueKey('resumo-sprint-dialog'));
        expect(
          tester.getSize(panel).width,
          size.width < 840 ? size.width : 420,
        );
        expect(tester.getTopRight(panel).dx, size.width);
        expect(find.byKey(const ValueKey('concluir-sprint')), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('0 de 1 Demandas concluídas'),
          150,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('sprint-detalhe-scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('0 de 1 Demandas concluídas'), findsOneWidget);
        if (size.width >= 840) {
          final queries = repo.chamadasBusca;
          await tester.tap(find.byTooltip('Ampliar painel'));
          await tester.pumpAndSettle();
          expect(tester.getSize(panel).width, 1008);
          await tester.drag(
            find.byKey(const ValueKey('redimensionar-painel-demanda')),
            const Offset(100, 0),
          );
          await tester.pumpAndSettle();
          expect(repo.chamadasBusca, queries);
          expect(vm.sprintSelecionada?.id, 7);
        }
        final link = find.byKey(const ValueKey('demanda-vinculada-sprint-1'));
        await tester.scrollUntilVisible(
          link,
          150,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('sprint-detalhe-scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(link);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('demanda-detalhe-dialog')),
          findsOneWidget,
        );
        final consultas = repo.chamadasIndicadores;
        await tester.tap(find.byTooltip('Fechar detalhes'));
        await tester.pumpAndSettle();
        expect(panel, findsOneWidget);
        expect(repo.chamadasIndicadores, greaterThan(consultas));
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'cancelar pelo painel conserva Demandas e usa operação existente',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeSprintRepository(sprints: [sprint()]);
      final vm = SprintViewModel(repository: repo);
      final demands = FakeDemandaRepository(demandas: [demandaFixture()]);
      final dvm = DemandasViewModel(repository: demands);
      addTearDown(vm.dispose);
      addTearDown(dvm.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SprintPage(viewModel: vm, demandasViewModel: dvm),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sprint-card-7')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('acoes-sprint')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('menu-cancelar-sprint')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(
            const ValueKey('confirmar-cancelamento-sprint-dialog'),
          ),
          matching: find.widgetWithText(FilledButton, 'Cancelar Sprint'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.chamadasCancelamento, 1);
      expect(demands.chamadasExcluir, 0);
      expect(vm.sprintSelecionada?.status, b.SprintStatus.cancelada);
      expect(tester.takeException(), isNull);
    },
  );
}
