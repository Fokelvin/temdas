import 'dart:async';

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import '../app/relatorio_web.dart';
import '../view_model/relatorios_view_model.dart';
import 'formatters/demanda_identificacao.dart';
import 'relatorios_export.dart';
import 'widgets/app_drawer.dart';
import 'widgets/resumo_card.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key, this.viewModel});

  final RelatoriosViewModel? viewModel;

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  late final RelatoriosViewModel _viewModel;
  late final bool _possuiViewModel;

  @override
  void initState() {
    super.initState();
    _possuiViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? RelatoriosViewModel();
    unawaited(_viewModel.gerarRelatorio());
  }

  @override
  void dispose() {
    if (_possuiViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => PageScaffold(
      title: 'Relatórios',
      route: AppRoutes.relatorios,
      actions: [
        IconButton(
          key: const ValueKey('exportar-relatorio-csv'),
          tooltip: 'Exportar CSV',
          onPressed: _viewModel.resposta == null ? null : _exportarCsv,
          icon: const Icon(Icons.download_outlined),
        ),
        IconButton(
          key: const ValueKey('imprimir-relatorio'),
          tooltip: 'Imprimir / PDF',
          onPressed: _viewModel.resposta == null ? null : _imprimirRelatorio,
          icon: const Icon(Icons.print_outlined),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Filtros(
                  viewModel: _viewModel,
                  onGerar: _viewModel.gerarRelatorio,
                ),
                if (_viewModel.erro case final erro?) ...[
                  const SizedBox(height: 12),
                  _MensagemErro(mensagem: erro),
                ],
                if (_viewModel.resposta case final resposta?) ...[
                  const SizedBox(height: 16),
                  _Resumo(resposta: resposta),
                ],
                const SizedBox(height: 20),
                Expanded(child: _conteudo()),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _conteudo() {
    if (_viewModel.carregando) {
      return const Center(
        child: CircularProgressIndicator(key: ValueKey('relatorio-carregando')),
      );
    }
    if (_viewModel.erro != null) {
      return Center(
        child: OutlinedButton.icon(
          key: const ValueKey('tentar-carregar-relatorio'),
          onPressed: _viewModel.gerarRelatorio,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      );
    }
    final resposta = _viewModel.resposta;
    if (resposta == null || resposta.itens.isEmpty) {
      return const _EstadoVazio();
    }
    return _TabelaRelatorio(itens: resposta.itens);
  }

  void _exportarCsv() {
    final resposta = _viewModel.resposta;
    if (resposta == null) return;
    baixarTexto(
      nomeArquivoRelatorio(
        inicioLocal: resposta.inicioEm.toLocal(),
        fimExclusivoLocal: resposta.fimExclusivo.toLocal(),
      ),
      gerarCsvRelatorio(resposta),
      'text/csv',
    );
  }

  void _imprimirRelatorio() {
    final resposta = _viewModel.resposta;
    if (resposta == null) return;
    imprimirHtml(
      gerarHtmlRelatorio(
        resposta: resposta,
        periodo: _periodoLabel(_viewModel.tipo),
        status: _viewModel.status == null
            ? 'Todos'
            : statusLabelRelatorio(_viewModel.status!),
        prioridade: _viewModel.prioridade == null
            ? 'Todas'
            : prioridadeLabelRelatorio(_viewModel.prioridade!),
      ),
      'TEMDAS - Relatório',
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.viewModel, required this.onGerar});

  final RelatoriosViewModel viewModel;
  final VoidCallback onGerar;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filtros do relatório',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<RelatorioPeriodoTipo>(
                  key: const ValueKey('relatorio-periodo'),
                  initialValue: viewModel.tipo,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Período'),
                  items: const [
                    DropdownMenuItem(
                      value: RelatorioPeriodoTipo.semana,
                      child: Text('Esta semana'),
                    ),
                    DropdownMenuItem(
                      value: RelatorioPeriodoTipo.mes,
                      child: Text('Este mês'),
                    ),
                    DropdownMenuItem(
                      value: RelatorioPeriodoTipo.personalizado,
                      child: Text('Personalizado'),
                    ),
                  ],
                  onChanged: (tipo) {
                    if (tipo != null) viewModel.selecionarTipo(tipo);
                  },
                ),
              ),
              if (viewModel.tipo == RelatorioPeriodoTipo.personalizado) ...[
                _DataButton(
                  key: const ValueKey('relatorio-data-inicial'),
                  label: 'Data inicial',
                  data: viewModel.dataInicialPersonalizada,
                  onPressed: () => _selecionarData(
                    context,
                    dataInicial: true,
                    viewModel: viewModel,
                  ),
                ),
                _DataButton(
                  key: const ValueKey('relatorio-data-final'),
                  label: 'Data final',
                  data: viewModel.dataFinalPersonalizada,
                  onPressed: () => _selecionarData(
                    context,
                    dataInicial: false,
                    viewModel: viewModel,
                  ),
                ),
              ],
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<backend.DemandaStatus?>(
                  key: const ValueKey('relatorio-status'),
                  initialValue: viewModel.status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem<backend.DemandaStatus?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...backend.DemandaStatus.values.map(
                      (status) => DropdownMenuItem<backend.DemandaStatus?>(
                        value: status,
                        child: Text(statusLabelRelatorio(status)),
                      ),
                    ),
                  ],
                  onChanged: viewModel.selecionarStatus,
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<backend.Prioridade?>(
                  key: const ValueKey('relatorio-prioridade'),
                  initialValue: viewModel.prioridade,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Prioridade'),
                  items: [
                    const DropdownMenuItem<backend.Prioridade?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...backend.Prioridade.values.map(
                      (prioridade) => DropdownMenuItem<backend.Prioridade?>(
                        value: prioridade,
                        child: Text(prioridadeLabelRelatorio(prioridade)),
                      ),
                    ),
                  ],
                  onChanged: viewModel.selecionarPrioridade,
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('gerar-relatorio'),
                onPressed: viewModel.carregando ? null : onGerar,
                icon: viewModel.carregando
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  viewModel.carregando ? 'Carregando...' : 'Gerar relatório',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _selecionarData(
    BuildContext context, {
    required bool dataInicial,
    required RelatoriosViewModel viewModel,
  }) async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataInicial
          ? viewModel.dataInicialPersonalizada
          : viewModel.dataFinalPersonalizada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: dataInicial
          ? 'Selecione a data inicial'
          : 'Selecione a data final',
    );
    if (data == null) return;
    if (dataInicial) {
      viewModel.selecionarDataInicial(data);
    } else {
      viewModel.selecionarDataFinal(data);
    }
  }
}

class _DataButton extends StatelessWidget {
  const _DataButton({
    super.key,
    required this.label,
    required this.data,
    required this.onPressed,
  });

  final String label;
  final DateTime data;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_today_outlined, size: 18),
    label: Text('$label: ${_formatarData(data)}'),
  );
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.resposta});

  final backend.RelatorioDemandasResponse resposta;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 700
          ? constraints.maxWidth
          : (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: width,
            child: ResumoCard(
              titulo: 'Tempo realizado total',
              valor: formatDuration(
                Duration(minutes: resposta.tempoRealizadoTotalMinutos),
              ),
              icone: Icons.timer_outlined,
            ),
          ),
          SizedBox(
            width: width,
            child: ResumoCard(
              titulo: 'Demandas com tempo',
              valor: '${resposta.quantidadeDemandasComTempo}',
              icone: Icons.task_alt_outlined,
            ),
          ),
        ],
      );
    },
  );
}

class _TabelaRelatorio extends StatelessWidget {
  const _TabelaRelatorio({required this.itens});

  final List<backend.RelatorioDemandaItem> itens;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth < 1200 ? 1200 : constraints.maxWidth,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 24,
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              columns: const [
                DataColumn(label: Text('Demanda')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Prioridade')),
                DataColumn(label: Text('Estimado')),
                DataColumn(label: Text('Realizado próprio')),
                DataColumn(label: Text('Total da árvore')),
              ],
              rows: itens.map((item) => _linha(context, item)).toList(),
            ),
          ),
        ),
      ),
    ),
  );

  DataRow _linha(BuildContext context, backend.RelatorioDemandaItem item) {
    final estilo = item.apenasContexto
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )
        : null;
    return DataRow(
      color: item.apenasContexto
          ? WidgetStatePropertyAll(
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: .28),
            )
          : null,
      cells: [
        DataCell(
          Padding(
            padding: EdgeInsets.only(left: item.nivelHierarquico * 22),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.apenasContexto) ...[
                  Icon(
                    Icons.subdirectory_arrow_right,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  formatarIdentificacaoDemandaPorId(
                    id: item.demandaId,
                    titulo: item.titulo,
                  ),
                  style: estilo?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        DataCell(Text(statusLabelRelatorio(item.status), style: estilo)),
        DataCell(
          Text(prioridadeLabelRelatorio(item.prioridade), style: estilo),
        ),
        DataCell(
          Text(_formatarMinutos(item.tempoEstimadoMinutos), style: estilo),
        ),
        DataCell(
          Text(
            _formatarMinutos(item.tempoRealizadoProprioMinutos),
            style: estilo,
          ),
        ),
        DataCell(
          Text(
            _formatarMinutos(item.tempoRealizadoTotalArvoreMinutos),
            style: estilo,
          ),
        ),
      ],
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.assessment_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          'Nenhuma demanda encontrada no período.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'Ajuste o período ou os filtros e gere o relatório novamente.',
        ),
      ],
    ),
  );
}

class _MensagemErro extends StatelessWidget {
  const _MensagemErro({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('erro-relatorio'),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 10),
        Expanded(child: Text(mensagem)),
      ],
    ),
  );
}

String _formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/${data.year}';

String _formatarMinutos(int minutos) =>
    formatDuration(Duration(minutes: minutos));

String _periodoLabel(RelatorioPeriodoTipo tipo) => switch (tipo) {
  RelatorioPeriodoTipo.semana => 'Esta semana',
  RelatorioPeriodoTipo.mes => 'Este mês',
  RelatorioPeriodoTipo.personalizado => 'Personalizado',
};
