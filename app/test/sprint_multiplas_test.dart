import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:temdas/ui/components/demand_components.dart';
import 'support/fake_demanda_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/formatters/sprint_apresentacao.dart';
import 'package:temdas/view/widgets/sprints_da_demanda.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;
import 'support/fake_sprint_repository.dart';

b.Sprint sprint(int id, b.SprintStatus status, int dia) => b.Sprint(
  id: id,
  usuarioId: 1,
  nome: 'Sprint $id',
  status: status,
  dataInicio: DateTime.utc(2026, 1, dia),
  dataFim: DateTime.utc(2026, 1, dia + 1),
);

void main() {
  setUpAll(() async {
    final loader = FontLoader('SprintTest')
      ..addFont(rootBundle.load('assets/fonts/inter/Inter-Regular.ttf'));
    await loader.load();
  });
  final lista = [
    sprint(72, b.SprintStatus.concluida, 2),
    sprint(76, b.SprintStatus.planejada, 24),
    sprint(71, b.SprintStatus.cancelada, 1),
    sprint(75, b.SprintStatus.planejada, 20),
    sprint(74, b.SprintStatus.ativa, 15),
  ];
  test(
    'consulta única agrupa todos os vínculos e ordena sem RPC por Sprint',
    () async {
      final repository = FakeSprintRepository(
        sprints: lista,
        vinculosPorSprint: {
          for (final s in lista)
            s.id!: [b.SprintDemanda(sprintId: s.id!, demandaId: 1)],
        },
      );
      final vm = SprintViewModel(repository: repository);
      addTearDown(vm.dispose);
      final resultado = await vm.carregarSprintsDasDemandas();
      expect(resultado![1]!.map((s) => s.id), [74, 75, 76, 72, 71]);
      expect(repository.chamadasContexto, 1);
      expect(repository.chamadasListagem, 0);
      expect(repository.chamadasVinculos, 0);
    },
  );
  test('nome complementa e colagem repetida preserva seleção válida', () {
    const formatter = ComplementoSprintFormatter();
    for (final nome in [
      'Sprint 73',
      'sprint Sprint 73',
      '  Sprint Sprint Sprint 73',
    ]) {
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: nome,
          selection: TextSelection.collapsed(offset: nome.length),
        ),
      );
      expect(value.text, '73');
      expect(value.selection.extentOffset, 2);
      expect(nomeSprint(nome), 'Sprint 73');
    }
    expect(nomeSprint('Sprint review'), 'Sprint review');
    expect(nomeSprint('SprintSprint'), 'Sprint SprintSprint');
  });
  for (final width in [320.0, 420.0, 1200.0]) {
    testWidgets('lista compacta ordena e abre cada Sprint em $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SprintsDaDemanda(sprints: lista, demandaId: 1)),
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => Scaffold(body: Text('Destino ${settings.name}')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final textos = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(SprintsDaDemanda),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(textos, [
        'Sprint 74 · Ativa',
        'Sprint 75 · Planejada',
        'Sprint 76 · Planejada',
        'Sprint 72 · Finalizada',
        'Sprint 71 · Cancelada',
      ]);
      for (final id in [74, 75, 76, 72, 71]) {
        await tester.tap(find.textContaining('Sprint $id ·'));
        await tester.pumpAndSettle();
        expect(find.text('Destino /sprint/$id'), findsOneWidget);
        Navigator.of(tester.element(find.text('Destino /sprint/$id'))).pop();
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [320.0, 768.0, 1440.0]) {
    for (final lista in [false, true]) {
      testWidgets('contexto completo na lista/card em $width lista=$lista', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final contexto = SprintsDaDemanda(
          sprints: lista
              ? [
                  sprint(74, b.SprintStatus.ativa, 15),
                  sprint(72, b.SprintStatus.concluida, 2),
                ]
              : [sprint(72, b.SprintStatus.concluida, 2)],
          demandaId: 1,
        );
        final demanda = demandaFixture(id: 1, titulo: 'Múltiplas Sprints');
        final Widget child = lista
            ? DemandRow(
                id: 1,
                title: demanda.titulo,
                priority: demanda.prioridade,
                hours: 0,
                estimate: 30,
                status: demanda.status,
                actions: const SizedBox(width: 32),
                chevron: const SizedBox(width: 24),
                onTap: () {},
                sprint: contexto,
              )
            : DemandCard(
                demand: demanda,
                real: 0,
                actions: const SizedBox(width: 32),
                chevron: const SizedBox(width: 24),
                sprint: contexto,
              );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'SprintTest'),
            home: Scaffold(
              body: Center(
                child: SizedBox(width: lista ? width : 280, child: child),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final label = find.text('Sprint 72 · Finalizada');
        expect(label, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
          isFalse,
        );
        if (lista) expect(find.text('Sprint 74 · Ativa'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
