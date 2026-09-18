import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

String gerarCsvRelatorio(backend.RelatorioDemandasResponse resposta) {
  final linhas = <String>[
    '\uFEFFdemanda_id,titulo,demanda_mae_id,nivel,status,prioridade,'
        'tempo_estimado_minutos,tempo_realizado_proprio_minutos,'
        'tempo_realizado_total_arvore_minutos,apenas_contexto',
    ...resposta.itens.map(
      (item) => [
        '${item.demandaId}',
        _csvTexto(item.titulo),
        item.demandaMaeId?.toString() ?? '',
        '${item.nivelHierarquico}',
        _csvTexto(item.status.name),
        _csvTexto(item.prioridade.name),
        '${item.tempoEstimadoMinutos}',
        '${item.tempoRealizadoProprioMinutos}',
        '${item.tempoRealizadoTotalArvoreMinutos}',
        '${item.apenasContexto}',
      ].join(','),
    ),
  ];
  return '${linhas.join('\r\n')}\r\n';
}

String nomeArquivoRelatorio({
  required DateTime inicioLocal,
  required DateTime fimExclusivoLocal,
}) {
  final fimInclusivo = DateTime(
    fimExclusivoLocal.year,
    fimExclusivoLocal.month,
    fimExclusivoLocal.day - 1,
  );
  return 'relatorio-demandas-${_dataParaArquivo(inicioLocal)}-a-'
      '${_dataParaArquivo(fimInclusivo)}.csv';
}

String gerarHtmlRelatorio({
  required backend.RelatorioDemandasResponse resposta,
  required String periodo,
  required String status,
  required String prioridade,
}) {
  final linhas = resposta.itens.map((item) {
    final classe = item.apenasContexto ? ' class="contexto"' : '';
    final titulo = '${item.demandaId} - ${item.titulo}';
    return '''
      <tr$classe>
        <td style="padding-left: ${12 + item.nivelHierarquico * 22}px">
          ${item.apenasContexto ? '<span class="contexto-marca">↳ </span>' : ''}${_html(titulo)}
        </td>
        <td>${_html(statusLabelRelatorio(item.status))}</td>
        <td>${_html(prioridadeLabelRelatorio(item.prioridade))}</td>
        <td>${_html(formatarTempoRelatorio(item.tempoEstimadoMinutos))}</td>
        <td>${_html(formatarTempoRelatorio(item.tempoRealizadoProprioMinutos))}</td>
        <td>${_html(formatarTempoRelatorio(item.tempoRealizadoTotalArvoreMinutos))}</td>
      </tr>''';
  }).join();

  final inicio = resposta.inicioEm.toLocal();
  final fimExclusivo = resposta.fimExclusivo.toLocal();
  final fim = DateTime(
    fimExclusivo.year,
    fimExclusivo.month,
    fimExclusivo.day - 1,
  );
  return '''<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <title>TEMDAS - Relatório</title>
  <style>
    @page { size: A4 landscape; margin: 12mm; }
    * { box-sizing: border-box; }
    body { color: #1f2937; font: 10pt Arial, sans-serif; margin: 0; }
    h1 { font-size: 18pt; margin: 0 0 4pt; }
    .subtitulo { color: #4b5563; margin-bottom: 14pt; }
    .filtros { border-bottom: 1px solid #d1d5db; display: flex; gap: 22pt;
      margin-bottom: 12pt; padding-bottom: 8pt; }
    .filtro strong { display: block; font-size: 8pt; color: #6b7280;
      text-transform: uppercase; }
    .resumo { display: flex; gap: 12pt; margin-bottom: 14pt; }
    .resumo-item { border: 1px solid #d1d5db; min-width: 150pt; padding: 7pt 10pt; }
    .resumo-item strong { display: block; font-size: 8pt; color: #6b7280; }
    .resumo-item span { font-size: 13pt; font-weight: bold; }
    table { border-collapse: collapse; table-layout: fixed; width: 100%; }
    th, td { border-bottom: 1px solid #d1d5db; padding: 6pt 5pt; text-align: left;
      vertical-align: top; word-wrap: break-word; }
    th { background: #f3f4f6; border-top: 1px solid #d1d5db; font-size: 8.5pt; }
    td { font-size: 9pt; }
    th:first-child, td:first-child { width: 38%; }
    .contexto { color: #6b7280; font-style: italic; }
    .contexto-marca { color: #9ca3af; }
    tr { page-break-inside: avoid; }
  </style>
</head>
<body>
  <h1>TEMDAS / Relatório de demandas</h1>
  <div class="subtitulo">Período: ${_html(_formatarIntervalo(inicio, fim))}</div>
  <div class="filtros">
    <div class="filtro"><strong>Status</strong>${_html(status)}</div>
    <div class="filtro"><strong>Prioridade</strong>${_html(prioridade)}</div>
    <div class="filtro"><strong>Período selecionado</strong>${_html(periodo)}</div>
  </div>
  <div class="resumo">
    <div class="resumo-item"><strong>Tempo realizado total</strong>
      <span>${_html(formatarTempoRelatorio(resposta.tempoRealizadoTotalMinutos))}</span></div>
    <div class="resumo-item"><strong>Demandas com tempo</strong>
      <span>${resposta.quantidadeDemandasComTempo}</span></div>
  </div>
  <table>
    <thead><tr>
      <th>Demanda</th><th>Status</th><th>Prioridade</th><th>Estimado</th>
      <th>Realizado próprio</th><th>Total da árvore</th>
    </tr></thead>
    <tbody>$linhas</tbody>
  </table>
  <script>
    window.addEventListener('load', function() {
      setTimeout(function() { window.focus(); window.print(); }, 100);
    });
  </script>
</body>
</html>''';
}

String formatarTempoRelatorio(int minutos) {
  final horas = minutos ~/ 60;
  final restantes = minutos.remainder(60);
  if (horas == 0) return '${restantes}min';
  if (restantes == 0) return '${horas}h';
  return '${horas}h${restantes.toString().padLeft(2, '0')}';
}

String statusLabelRelatorio(backend.DemandaStatus status) => switch (status) {
  backend.DemandaStatus.aberta => 'Aberta',
  backend.DemandaStatus.emAndamento => 'Em andamento',
  backend.DemandaStatus.pausada => 'Pausada',
  backend.DemandaStatus.concluida => 'Concluída',
  backend.DemandaStatus.cancelada => 'Cancelada',
};

String prioridadeLabelRelatorio(backend.Prioridade prioridade) =>
    switch (prioridade) {
      backend.Prioridade.baixa => 'Baixa',
      backend.Prioridade.media => 'Média',
      backend.Prioridade.alta => 'Alta',
      backend.Prioridade.urgente => 'Urgente',
    };

String _csvTexto(String valor) => '"${valor.replaceAll('"', '""')}"';

String _html(String valor) => valor
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

String _dataParaArquivo(DateTime data) =>
    '${data.year.toString().padLeft(4, '0')}'
    '${data.month.toString().padLeft(2, '0')}'
    '${data.day.toString().padLeft(2, '0')}';

String _formatarIntervalo(DateTime inicio, DateTime fim) =>
    '${_dataParaArquivo(inicio)} a ${_dataParaArquivo(fim)}';
