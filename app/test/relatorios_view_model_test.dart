import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/data/repositories/relatorio_repository.dart';
import 'package:temdas/view_model/relatorios_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

void main() {
  group('calcularLimitesRelatorio', () {
    final agora = DateTime(2026, 9, 16, 15, 30);

    test('calcula esta semana de segunda a segunda em horário local', () {
      final limites = calcularLimitesRelatorio(
        tipo: RelatorioPeriodoTipo.semana,
        agora: agora,
      );

      expect(limites.inicioLocal, DateTime(2026, 9, 14));
      expect(limites.fimExclusivoLocal, DateTime(2026, 9, 21));
      expect(limites.inicioUtc, limites.inicioLocal.toUtc());
      expect(limites.fimExclusivoUtc, limites.fimExclusivoLocal.toUtc());
    });

    test('calcula o mês inteiro em horário local', () {
      final limites = calcularLimitesRelatorio(
        tipo: RelatorioPeriodoTipo.mes,
        agora: agora,
      );

      expect(limites.inicioLocal, DateTime(2026, 9));
      expect(limites.fimExclusivoLocal, DateTime(2026, 10));
    });

    test('torna a data final personalizada inclusiva na UI', () {
      final limites = calcularLimitesRelatorio(
        tipo: RelatorioPeriodoTipo.personalizado,
        agora: agora,
        dataInicial: DateTime(2026, 9, 10),
        dataFinal: DateTime(2026, 9, 12),
      );

      expect(limites.inicioLocal, DateTime(2026, 9, 10));
      expect(limites.fimExclusivoLocal, DateTime(2026, 9, 13));
      expect(limites.fimExclusivoUtc, DateTime(2026, 9, 13).toUtc());
    });
  });

  test('envia período UTC e status/prioridade combinados', () async {
    final repository = _FakeRelatorioRepository();
    final viewModel = RelatoriosViewModel(
      repository: repository,
      relogio: () => DateTime(2026, 9, 16, 15),
    );

    viewModel.selecionarStatus(backend.DemandaStatus.emAndamento);
    viewModel.selecionarPrioridade(backend.Prioridade.alta);
    await viewModel.gerarRelatorio();

    final request = repository.ultimoRequest!;
    expect(request.inicioEm, DateTime(2026, 9, 14).toUtc());
    expect(request.fimExclusivo, DateTime(2026, 9, 21).toUtc());
    expect(request.status, backend.DemandaStatus.emAndamento);
    expect(request.prioridade, backend.Prioridade.alta);
    expect(viewModel.resposta, isNotNull);

    viewModel.dispose();
  });
}

class _FakeRelatorioRepository implements RelatorioRepository {
  backend.RelatorioDemandaRequest? ultimoRequest;

  @override
  Future<backend.RelatorioDemandasResponse> gerarRelatorio(
    backend.RelatorioDemandaRequest request,
  ) async {
    ultimoRequest = request;
    return backend.RelatorioDemandasResponse(
      inicioEm: request.inicioEm,
      fimExclusivo: request.fimExclusivo,
      tempoRealizadoTotalMinutos: 90,
      quantidadeDemandasComTempo: 1,
      itens: [
        backend.RelatorioDemandaItem(
          demandaId: 1,
          titulo: 'Demanda',
          nivelHierarquico: 0,
          status: backend.DemandaStatus.emAndamento,
          prioridade: backend.Prioridade.alta,
          tempoEstimadoMinutos: 120,
          tempoRealizadoProprioMinutos: 90,
          tempoRealizadoTotalArvoreMinutos: 90,
          apenasContexto: false,
        ),
      ],
    );
  }
}
