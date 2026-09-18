import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/formatters/demanda_identificacao.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
import 'package:temdas/view/widgets/tempo_comparacao.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  for (final filha in [false, true]) {
    testWidgets(
      '${filha ? 'filha' : 'raiz'} recolhida mostra só resumo e preserva ações ao expandir',
      (tester) async {
        final demanda = demandaFixture(
          id: 2,
          demandaPaiId: filha ? 1 : null,
          titulo: filha ? 'Filha' : 'Demanda',
          status: filha
              ? backend.DemandaStatus.pausada
              : backend.DemandaStatus.aberta,
          tempoEstimadoMinutos: 600,
          tempoExecutadoMinutos: filha ? 90 : 0,
        );
        final chamadas = <String>[];
        final statuses = <backend.DemandaStatus>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: filha ? 250 : 360,
                  child: DemandaCard(
                    demanda: demanda,
                    tempoExecutadoTotalMinutos: demanda.tempoExecutadoMinutos,
                    onAlterarStatus: statuses.add,
                    onConcluir: () => chamadas.add('concluir'),
                    onEditar: () => chamadas.add('editar'),
                    onExcluir: () => chamadas.add('excluir'),
                    onCriarFilha: () => chamadas.add('filha'),
                    onLancarTempo: () => chamadas.add('tempo'),
                    onMostrarTudo: () => chamadas.add('mostrar'),
                  ),
                ),
              ),
            ),
          ),
        );

        final card = find.byKey(const ValueKey('demanda-card-2'));
        void verificarRecolhido() {
          expect(
            find.text(formatarIdentificacaoDemanda(demanda)),
            findsOneWidget,
          );
          expect(
            find.text('Média · Est. 10 h · Real. ${filha ? '1,5' : '0'} h'),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('status-demanda-2')), findsNothing);
          expect(
            find.byKey(const ValueKey('concluir-demanda-2')),
            findsNothing,
          );
          expect(find.byKey(const ValueKey('acoes-demanda-2')), findsNothing);
          expect(find.text(filha ? 'Pausada' : 'Aberta'), findsNothing);
          expect(find.byIcon(Icons.check), findsNothing);
          expect(find.byIcon(Icons.more_vert), findsNothing);
          expect(find.text('ID: 2'), findsNothing);
          expect(find.text('Descrição: Descrição inicial'), findsNothing);
          expect(find.text('Sprint: Sprint preservada'), findsNothing);
          expect(find.text('Observações: Observação preservada'), findsNothing);
          expect(find.byType(TempoComparacao), findsNothing);
          expect(find.byType(LinearProgressIndicator), findsNothing);
          expect(find.byType(TextButton), findsNothing);
          expect(find.byIcon(Icons.expand_more), findsOneWidget);
        }

        verificarRecolhido();
        final alturaRecolhida = tester.getSize(card).height;
        expect(alturaRecolhida, lessThan(120));
        await _tocar(tester, find.text(formatarIdentificacaoDemanda(demanda)));
        expect(tester.getSize(card).height, greaterThan(alturaRecolhida));
        expect(find.byKey(const ValueKey('status-demanda-2')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('concluir-demanda-2')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('acoes-demanda-2')), findsOneWidget);
        expect(find.text(filha ? 'Pausada' : 'Aberta'), findsOneWidget);
        expect(find.text('ID: 2'), findsOneWidget);
        expect(find.text('Descrição: Descrição inicial'), findsOneWidget);
        expect(find.text('Sprint: Sprint preservada'), findsOneWidget);
        expect(find.text('Observações: Observação preservada'), findsOneWidget);
        expect(find.byType(TempoComparacao), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.byType(TextButton), findsNWidgets(2));

        await _tocar(tester, find.byKey(const ValueKey('criar-filha-2')));
        await _tocar(tester, find.byKey(const ValueKey('lancar-tempo-2')));
        await _tocar(tester, find.byKey(const ValueKey('concluir-demanda-2')));
        await _tocar(tester, find.byKey(const ValueKey('status-demanda-2')));
        expect(
          find.byType(CheckedPopupMenuItem<backend.DemandaStatus>),
          findsNWidgets(5),
        );
        for (final status in backend.DemandaStatus.values) {
          final item = tester
              .widget<CheckedPopupMenuItem<backend.DemandaStatus>>(
                find.byKey(ValueKey('status-opcao-${status.name}-2')),
              );
          expect(item.checked, status == demanda.status);
        }
        await _tocar(
          tester,
          find.byKey(const ValueKey('status-opcao-emAndamento-2')),
        );
        expect(statuses, [backend.DemandaStatus.emAndamento]);

        for (final acao in [
          'editar-demanda',
          'mostrar-tudo',
          'excluir-demanda',
        ]) {
          await _tocar(tester, find.byKey(const ValueKey('acoes-demanda-2')));
          expect(find.byType(PopupMenuDivider), findsOneWidget);
          expect(
            tester.getTopLeft(find.text('Editar')).dy,
            lessThan(tester.getTopLeft(find.text('Mostrar tudo')).dy),
          );
          expect(
            tester.getTopLeft(find.text('Mostrar tudo')).dy,
            lessThan(tester.getTopLeft(find.text('Excluir')).dy),
          );
          expect(
            tester.widget<Text>(find.text('Excluir')).style?.color,
            Theme.of(tester.element(card)).colorScheme.error,
          );
          await _tocar(tester, find.byKey(ValueKey('$acao-2')));
        }
        expect(chamadas, [
          'filha',
          'tempo',
          'concluir',
          'editar',
          'mostrar',
          'excluir',
        ]);
        await _tocar(tester, find.text(formatarIdentificacaoDemanda(demanda)));
        verificarRecolhido();
        expect(tester.getSize(card).height, alturaRecolhida);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
