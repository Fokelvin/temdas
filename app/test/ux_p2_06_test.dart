import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/ui/components/demand_components.dart';
import 'package:temdas/view/formatters/demanda_hierarquia.dart';
import 'package:temdas/view_model/demandas_agrupamento.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;

import 'demandas_redesign_test.dart' show open;
import 'support/fake_demanda_repository.dart';

final demandas = [
  demandaFixture(
    id: 24,
    titulo: 'iVertex – Reuniões',
    prioridade: b.Prioridade.urgente,
  ),
  demandaFixture(
    id: 25,
    titulo: 'CRM + Lojas',
    demandaPaiId: 24,
    status: b.DemandaStatus.pausada,
  ),
  demandaFixture(
    id: 26,
    titulo: 'Validar integração com título longo',
    demandaPaiId: 25,
  ),
];

void main() {
  test('caminho completo acompanha renomeação e para em ciclos', () {
    final indice = indexarDemandas(demandas);
    expect(
      caminhoAncestral(demandas.last, (id) => indice[id]),
      'iVertex – Reuniões › CRM + Lojas',
    );
    indice[24] = demandas.first.copyWith(
      titulo: 'Reuniões atualizadas',
      demandaPaiId: 26,
    );
    expect(
      caminhoAncestral(demandas.last, (id) => indice[id]),
      'Reuniões atualizadas › CRM + Lojas',
    );
  });

  for (final density in ['normal', 'compacta']) {
    for (final mode in ['lista', 'kanban']) {
      testWidgets('árvore e conclusão explícita em $mode $density', (
        tester,
      ) async {
        await open(
          tester,
          mode: mode,
          density: density,
          width: density == 'normal' ? 1440 : 390,
          dark: density == 'compacta',
          demands: demandas,
        );
        final agrupar = find.byTooltip('Agrupar por');
        expect(agrupar, mode == 'lista' ? findsOneWidget : findsNothing);
        if (mode == 'lista') {
          expect(find.byType(GroupHeader), findsNothing);
        }
        await tester.tap(find.byKey(const ValueKey('expandir-demanda-24')));
        await tester.pumpAndSettle();
        expect(find.text('Demandas filhas (1)'), findsNothing);
        final concluir = find.byKey(const ValueKey('concluir-demanda-24'));
        if (mode == 'lista') {
          expect(tester.widget(concluir), isA<TextButton>());
          expect(find.text('Concluir demanda'), findsOneWidget);
          expect(find.text('Título: ${demandas.first.titulo}'), findsNothing);
          final barra = find.descendant(
            of: find.byKey(const ValueKey('demanda-card-24')),
            matching: find.byType(LinearProgressIndicator),
          );
          expect(barra, findsOneWidget);
          expect(
            tester.getTopLeft(concluir).dy - tester.getBottomLeft(barra).dy,
            greaterThanOrEqualTo(12),
          );
        } else {
          expect(tester.widget(concluir), isA<IconButton>());
          expect(find.text('Concluir demanda'), findsNothing);
        }
        expect(
          find.byKey(const ValueKey('demanda-tree-node-25-1')),
          findsOneWidget,
        );
        final filha = find.byKey(const ValueKey('expandir-demanda-25'));
        await tester.ensureVisible(filha);
        await tester.tap(filha);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('demanda-tree-node-26-2')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('agrupa pela raiz, mantém status da filha e persiste seleção', (
    tester,
  ) async {
    await open(tester, mode: 'lista', width: 1280, demands: demandas);
    Future<void> agrupar(String nome) async {
      await tester.tap(find.byTooltip('Agrupar por'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<AgrupamentoDemandas>, nome),
      );
      await tester.pumpAndSettle();
    }

    await agrupar('Status');
    expect(
      tester.widget<GroupHeader>(find.byType(GroupHeader)).status,
      b.DemandaStatus.aberta,
    );
    await tester.tap(find.byKey(const ValueKey('expandir-demanda-24')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('demanda-card-25')),
        matching: find.text('Pausada'),
      ),
      findsOneWidget,
    );
    await agrupar('Prioridade');
    final cabecalho = tester.widget<GroupHeader>(find.byType(GroupHeader));
    expect(cabecalho.prioridade, b.Prioridade.urgente);
    expect(cabecalho.count, 1);
    expect(
      find.byKey(const ValueKey('demanda-tree-node-25-1')),
      findsOneWidget,
    );
    expect(
      (await SharedPreferences.getInstance()).getString(
        DemandasAgrupamento.storageKey,
      ),
      'prioridade',
    );
    final preferencia = DemandasAgrupamento();
    addTearDown(preferencia.dispose);
    await preferencia.load();
    expect(preferencia.value, AgrupamentoDemandas.prioridade);
    expect(tester.takeException(), isNull);
  });
}
