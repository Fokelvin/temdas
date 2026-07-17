import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/model/demanda.dart';
import 'package:temdas/view_model/workspace_view_model.dart';

void main() {
  test('demanda sem data recebe logs separados', () {
    final hoje = DateTime(2026, 7, 16);
    final viewModel = WorkspaceViewModel(hoje: hoje);
    viewModel.adicionarDemanda(
      titulo: 'Demanda sem data',
      estimado: const Duration(hours: 2),
      status: DemandaStatus.pendente,
    );
    final demanda = viewModel.demandas.last;
    viewModel.adicionarLog(
      demandaId: demanda.id,
      data: hoje,
      hora: const TimeOfDayValue(16, 0),
      duracao: const Duration(minutes: 30),
    );

    expect(
      viewModel.executadoDaDemanda(demanda.id),
      const Duration(minutes: 30),
    );
    expect(
      viewModel.logsDoDia(hoje).map((item) => item.demandaId),
      contains(demanda.id),
    );
  });

  test('calcula resumo de logs do dia', () {
    final viewModel = WorkspaceViewModel(hoje: DateTime(2026, 7, 16));
    expect(viewModel.executadoDoPeriodo, const Duration(hours: 3, minutes: 15));
    expect(viewModel.lancamentosDoPeriodo, 3);
  });
}
