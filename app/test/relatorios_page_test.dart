import 'package:temdas/ui/components/mobile_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/data/repositories/relatorio_repository.dart';
import 'package:temdas/view/relatorios_page.dart';
import 'package:temdas/view_model/relatorios_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

void main() {
  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('relatório responsivo em $width com texto ampliado', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vm = RelatoriosViewModel(
        repository: _FakeRelatorioRepository(),
        relogio: () => DateTime(2026, 9, 16),
      );
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: RelatoriosPage(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('1 - Mãe'),
        150,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('relatorio-lista-responsiva')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('1 - Mãe'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('3 - Filha'),
        100,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('relatorio-lista-responsiva')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('3 - Filha'), findsOneWidget);
      expect(
        find.byType(MobileBottomNavigation),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('exibe resumo, identificação formatada e hierarquia', (
    tester,
  ) async {
    final viewModel = RelatoriosViewModel(
      repository: _FakeRelatorioRepository(),
      relogio: () => DateTime(2026, 9, 16, 15),
    );

    await tester.pumpWidget(
      MaterialApp(home: RelatoriosPage(viewModel: viewModel)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tempo realizado total'), findsOneWidget);
    expect(find.text('1h30'), findsAtLeastNWidgets(1));
    expect(find.text('3 - Filha'), findsOneWidget);
    expect(find.text('1 - Mãe'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('relatorio-lista-responsiva')),
      findsOneWidget,
    );

    viewModel.dispose();
  });
}

class _FakeRelatorioRepository implements RelatorioRepository {
  @override
  Future<backend.RelatorioDemandasResponse> gerarRelatorio(
    backend.RelatorioDemandaRequest request,
  ) async {
    return backend.RelatorioDemandasResponse(
      inicioEm: request.inicioEm,
      fimExclusivo: request.fimExclusivo,
      tempoRealizadoTotalMinutos: 90,
      quantidadeDemandasComTempo: 1,
      itens: [
        backend.RelatorioDemandaItem(
          demandaId: 1,
          titulo: 'Mãe',
          nivelHierarquico: 0,
          status: backend.DemandaStatus.aberta,
          prioridade: backend.Prioridade.media,
          tempoEstimadoMinutos: 60,
          tempoRealizadoProprioMinutos: 30,
          tempoRealizadoTotalArvoreMinutos: 90,
          apenasContexto: true,
        ),
        backend.RelatorioDemandaItem(
          demandaId: 3,
          titulo: 'Filha',
          demandaMaeId: 1,
          nivelHierarquico: 1,
          status: backend.DemandaStatus.emAndamento,
          prioridade: backend.Prioridade.alta,
          tempoEstimadoMinutos: 120,
          tempoRealizadoProprioMinutos: 60,
          tempoRealizadoTotalArvoreMinutos: 60,
          apenasContexto: false,
        ),
      ],
    );
  }
}
