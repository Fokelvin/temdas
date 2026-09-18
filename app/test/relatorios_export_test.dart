import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/relatorios_export.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

void main() {
  final resposta = backend.RelatorioDemandasResponse(
    inicioEm: DateTime.utc(2026, 9, 14, 3),
    fimExclusivo: DateTime.utc(2026, 9, 21, 3),
    tempoRealizadoTotalMinutos: 90,
    quantidadeDemandasComTempo: 1,
    itens: [
      backend.RelatorioDemandaItem(
        demandaId: 2,
        titulo: 'Título, com acentuação e "aspas"',
        demandaMaeId: 1,
        nivelHierarquico: 1,
        status: backend.DemandaStatus.emAndamento,
        prioridade: backend.Prioridade.alta,
        tempoEstimadoMinutos: 120,
        tempoRealizadoProprioMinutos: 30,
        tempoRealizadoTotalArvoreMinutos: 90,
        apenasContexto: false,
      ),
    ],
  );

  test('CSV usa a response, minutos, UTF-8 e escape de campos', () {
    final csv = gerarCsvRelatorio(resposta);

    expect(csv, startsWith('\uFEFFdemanda_id,titulo'));
    expect(csv, contains('2,"Título, com acentuação e ""aspas""",1,1'));
    expect(csv, contains(',120,30,90,false'));
    expect(csv, isNot(contains('2h')));
  });

  test('nome do arquivo e HTML de impressão são determinísticos', () {
    expect(
      nomeArquivoRelatorio(
        inicioLocal: DateTime(2026, 9, 14),
        fimExclusivoLocal: DateTime(2026, 9, 21),
      ),
      'relatorio-demandas-20260914-a-20260920.csv',
    );

    final html = gerarHtmlRelatorio(
      resposta: resposta,
      periodo: 'Esta semana',
      status: 'Todos',
      prioridade: 'Todas',
    );
    expect(html, contains('@page { size: A4 landscape;'));
    expect(html, contains('window.print()'));
    expect(html, contains('TEMDAS / Relatório de demandas'));
    expect(html, contains('Título, com acentuação e &quot;aspas&quot;'));
    expect(html, contains('Realizado próprio'));
  });
}
