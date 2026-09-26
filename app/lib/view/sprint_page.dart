import 'dart:async';

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import '../theme/app_theme.dart';
import '../theme/temdas_semantic_colors.dart';
import '../view_model/demanda_detalhe_view_model.dart';
import '../view_model/demandas_view_model.dart';
import '../view_model/sprint_view_model.dart';
import 'formatters/demanda_identificacao.dart';
import 'demanda_detalhe_page.dart';
import 'widgets/app_drawer.dart';
import 'widgets/resumo_card.dart';

class SprintPage extends StatefulWidget {
  const SprintPage({
    super.key,
    this.viewModel,
    this.demandasViewModel,
    this.demandaDetalheViewModel,
  });

  final SprintViewModel? viewModel;
  final DemandasViewModel? demandasViewModel;
  final DemandaDetalheViewModel? demandaDetalheViewModel;

  @override
  State<SprintPage> createState() => _SprintPageState();
}

class _SprintPageState extends State<SprintPage> {
  late final SprintViewModel _viewModel;
  late final bool _possuiViewModel;
  late final DemandasViewModel _demandasViewModel;
  late final bool _possuiDemandasViewModel;

  @override
  void initState() {
    super.initState();
    _possuiViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? SprintViewModel();
    _possuiDemandasViewModel = widget.demandasViewModel == null;
    _demandasViewModel = widget.demandasViewModel ?? DemandasViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_carregar());
    });
  }

  @override
  void dispose() {
    if (_possuiViewModel) _viewModel.dispose();
    if (_possuiDemandasViewModel) _demandasViewModel.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final carregada = await _viewModel.carregarSprints();
    if (!mounted || !carregada || _viewModel.sprints.isEmpty) return;
    await _viewModel.carregarIndicadoresDaLista();
  }

  Future<void> _abrirResumo(backend.Sprint sprint) async {
    final id = sprint.id;
    if (id == null) return;
    _viewModel.selecionarSprint(sprint);
    await Future.wait<Object?>([
      _viewModel.carregarVinculos(id),
      _demandasViewModel.carregarDemandas(),
    ]);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _SprintResumoDialog(
        sprint: sprint,
        viewModel: _viewModel,
        demandasViewModel: _demandasViewModel,
        onAbrirDemanda: _abrirDetalhesDemanda,
        onMostrarTodas: () => _mostrarPainelDemandas(
          sprint,
          viewModel: _viewModel,
          permiteAcoes: _permiteGerenciarVinculos(sprint),
          aoAcionar: (demandaId, demanda, acao) =>
              _removerDemandaResumo(sprint, demanda, demandaId, acao),
        ),
        onAbrirSprint: () {
          final navigator = Navigator.of(dialogContext);
          navigator.pop();
          navigator.pushNamed(AppRoutes.detalheDaSprint(id));
        },
        onRecarregarVinculos: () => _viewModel.carregarVinculos(id),
      ),
    );
  }

  bool _permiteGerenciarVinculos(backend.Sprint sprint) =>
      sprint.status == backend.SprintStatus.planejada ||
      sprint.status == backend.SprintStatus.ativa;

  void _abrirDetalhesDemanda(int demandaId) {
    unawaited(
      mostrarDetalhesDemandaDialog(
        context,
        demandaId,
        viewModel: widget.demandaDetalheViewModel,
      ),
    );
  }

  Future<void> _mostrarPainelDemandas(
    backend.Sprint sprint, {
    required SprintViewModel viewModel,
    required bool permiteAcoes,
    required void Function(
      int demandaId,
      backend.Demanda? demanda,
      _AcaoDemandaSprint acao,
    )
    aoAcionar,
  }) => _mostrarPainelLateralDemandas(
    context,
    titulo: 'Demandas da Sprint',
    child: ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => _DemandasVinculadasSprint(
        vinculos: viewModel.vinculos,
        demandas: _demandasViewModel.demandas,
        permiteAcoes: permiteAcoes,
        aoAbrir: _abrirDetalhesDemanda,
        aoAcionar: aoAcionar,
        mensagemVazia: 'Nenhuma Demanda vinculada à Sprint.',
      ),
    ),
  );

  Future<void> _removerDemandaResumo(
    backend.Sprint sprint,
    backend.Demanda? demanda,
    int demandaId,
    _AcaoDemandaSprint acao,
  ) async {
    final sprintId = sprint.id;
    if (sprintId == null || !_permiteGerenciarVinculos(sprint)) return;

    if (acao == _AcaoDemandaSprint.desvincular) {
      final temDescendentes =
          demanda != null &&
          _demandasViewModel
              .descendentesDe(demanda)
              .any(
                (filha) => _viewModel.vinculos.any(
                  (vinculo) => vinculo.demandaId == filha.id,
                ),
              );
      final confirmado = await _confirmarRemocaoResumo(
        titulo: 'Desvincular da Sprint?',
        mensagem: temDescendentes
            ? 'A Demanda e suas filhas serão desvinculadas desta Sprint.'
            : 'A Demanda será desvinculada desta Sprint.',
        rotulo: 'Desvincular',
      );
      if (!confirmado || !mounted) return;
      final sucesso = await _viewModel.desvincularDemanda(
        sprintId: sprintId,
        demandaId: demandaId,
      );
      if (!mounted) return;
      if (!sucesso) {
        _mostrarFeedbackResumo(
          _viewModel.erro ?? 'Não foi possível desvincular a Demanda.',
        );
        return;
      }
    } else if (acao == _AcaoDemandaSprint.excluir && demanda != null) {
      final excluirArvore = _demandasViewModel.possuiDescendentes(demanda);
      final confirmado = await _confirmarRemocaoResumo(
        titulo: excluirArvore
            ? 'Excluir árvore de Demandas?'
            : 'Excluir Demanda?',
        mensagem: excluirArvore
            ? 'A Demanda e todas as suas filhas serão excluídas permanentemente.'
            : 'A Demanda será excluída permanentemente.',
        rotulo: 'Excluir permanentemente',
        destrutiva: true,
      );
      if (!confirmado || !mounted) return;
      final excluida = excluirArvore
          ? await _demandasViewModel.excluirArvoreDemanda(demanda)
          : await _demandasViewModel.excluirDemanda(demanda);
      if (!mounted) return;
      if (!excluida) {
        _mostrarFeedbackResumo(
          _demandasViewModel.erro ?? 'Não foi possível excluir a Demanda.',
        );
        return;
      }
    } else {
      return;
    }

    await _viewModel.carregarVinculos(sprintId);
    if (!mounted) return;
    await _viewModel.carregarIndicadores(sprintId);
    if (mounted) _mostrarFeedbackResumo('Demandas vinculadas atualizadas.');
  }

  Future<bool> _confirmarRemocaoResumo({
    required String titulo,
    required String mensagem,
    required String rotulo,
    bool destrutiva = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: destrutiva
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    )
                  : null,
              child: Text(rotulo),
            ),
          ],
        ),
      ) ==
      true;

  void _mostrarFeedbackResumo(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _abrirFormularioCriacao() async {
    final criada = await showDialog<bool>(
      context: context,
      builder: (_) => _CriarSprintDialog(
        onSalvar:
            ({
              required nome,
              required dataInicio,
              required dataFim,
              tempoPrevistoMinutos,
            }) async {
              final sucesso = await _viewModel.criarSprint(
                nome: nome,
                dataInicio: dataInicio,
                dataFim: dataFim,
                tempoPrevistoMinutos: tempoPrevistoMinutos,
              );
              return sucesso
                  ? null
                  : _viewModel.erro ?? 'Não foi possível criar a Sprint.';
            },
      ),
    );
    if (!mounted || criada != true) return;

    final sprintCriada = _viewModel.sprintSelecionada;
    final idCriado = sprintCriada?.id;
    if (idCriado == null) return;

    await _carregar();
    if (!mounted) return;
    final sprintsAtualizadas = _viewModel.sprints.where(
      (sprint) => sprint.id == idCriado,
    );
    final sprintAtualizada = sprintsAtualizadas.isEmpty
        ? sprintCriada
        : sprintsAtualizadas.first;
    if (sprintAtualizada != null) await _abrirResumo(sprintAtualizada);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => PageScaffold(
      title: 'Sprints',
      route: AppRoutes.sprint,
      actions: [
        IconButton(
          key: const ValueKey('recarregar-sprints'),
          tooltip: 'Recarregar Sprints',
          onPressed: _viewModel.carregando ? null : _carregar,
          icon: const Icon(Icons.refresh),
        ),
        Padding(
          padding: const EdgeInsets.only(right: TemdasTokens.contentGap),
          child: FilledButton.icon(
            key: const ValueKey('nova-sprint'),
            onPressed: _abrirFormularioCriacao,
            icon: const Icon(Icons.add),
            label: const Text('Nova Sprint'),
          ),
        ),
      ],
      body: _conteudo(context),
    ),
  );

  Widget _conteudo(BuildContext context) {
    if (_viewModel.carregando && _viewModel.sprints.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(key: ValueKey('carregando-sprints')),
      );
    }

    if (_viewModel.erro != null && _viewModel.sprints.isEmpty) {
      return _EstadoSprint(
        icone: Icons.cloud_off_outlined,
        titulo: 'Não foi possível carregar as Sprints',
        mensagem: _viewModel.erro!,
        acao: FilledButton.icon(
          key: const ValueKey('tentar-carregar-sprints'),
          onPressed: _viewModel.carregando ? null : _carregar,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      );
    }

    if (_viewModel.sprints.isEmpty) {
      return _EstadoSprint(
        icone: Icons.directions_run_outlined,
        titulo: 'Nenhuma Sprint cadastrada',
        mensagem: 'As Sprints criadas aparecerão nesta lista.',
        acao: FilledButton.icon(
          key: const ValueKey('nova-sprint-vazia'),
          onPressed: _abrirFormularioCriacao,
          icon: const Icon(Icons.add),
          label: const Text('Nova Sprint'),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: ListView(
          key: const ValueKey('sprints-lista'),
          padding: const EdgeInsets.all(TemdasTokens.pagePadding),
          children: [
            if (_viewModel.erro != null) ...[
              _AvisoErro(mensagem: _viewModel.erro!, onTentar: _carregar),
              const SizedBox(height: TemdasTokens.contentGap),
            ],
            Text(
              'Planejamento de Sprints',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: TemdasTokens.contentGap),
            for (final sprint in _viewModel.sprints) ...[
              _SprintListaCard(
                sprint: sprint,
                indicadores: sprint.id == null
                    ? null
                    : _viewModel.indicadoresDaSprint(sprint.id!),
                onTap: _viewModel.carregando
                    ? null
                    : () => _abrirResumo(sprint),
              ),
              const SizedBox(height: TemdasTokens.smallGap),
            ],
          ],
        ),
      ),
    );
  }
}

typedef _SalvarSprint =
    Future<String?> Function({
      required String nome,
      required DateTime dataInicio,
      required DateTime dataFim,
      int? tempoPrevistoMinutos,
    });

class _CriarSprintDialog extends StatefulWidget {
  const _CriarSprintDialog({required this.onSalvar, this.sprint});

  final _SalvarSprint onSalvar;
  final backend.Sprint? sprint;

  @override
  State<_CriarSprintDialog> createState() => _CriarSprintDialogState();
}

class _CriarSprintDialogState extends State<_CriarSprintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();
  final _tempoController = TextEditingController();
  bool _enviando = false;
  String? _erro;
  String? _erroPeriodo;

  bool get _edicao => widget.sprint != null;

  @override
  void initState() {
    super.initState();
    final sprint = widget.sprint;
    if (sprint == null) return;
    _nomeController.text = sprint.nome;
    _dataInicioController.text = _formatarDataCalendario(sprint.dataInicio);
    _dataFimController.text = _formatarDataCalendario(sprint.dataFim);
    _tempoController.text = _formatarTempoSprint(sprint.tempoPrevistoMinutos);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_enviando,
    child: AlertDialog(
      key: ValueKey(_edicao ? 'editar-sprint-dialog' : 'criar-sprint-dialog'),
      scrollable: true,
      title: Text(_edicao ? 'Editar Sprint' : 'Nova Sprint'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const ValueKey('criar-sprint-nome'),
                controller: _nomeController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome da Sprint.'
                    : null,
              ),
              const SizedBox(height: TemdasTokens.contentGap),
              TextFormField(
                key: const ValueKey('criar-sprint-data-inicio'),
                controller: _dataInicioController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'Data início',
                  hintText: 'dd/mm/aaaa',
                  suffixIcon: IconButton(
                    tooltip: 'Selecionar data de início',
                    onPressed: _enviando ? null : () => _selecionarData(true),
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                ),
                validator: (value) => _parseDataCalendario(value) == null
                    ? 'Informe uma data de início válida.'
                    : null,
                onChanged: (_) => setState(() => _erroPeriodo = null),
              ),
              const SizedBox(height: TemdasTokens.contentGap),
              TextFormField(
                key: const ValueKey('criar-sprint-data-fim'),
                controller: _dataFimController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'Data fim',
                  hintText: 'dd/mm/aaaa',
                  suffixIcon: IconButton(
                    tooltip: 'Selecionar data de fim',
                    onPressed: _enviando ? null : () => _selecionarData(false),
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                ),
                validator: (value) => _parseDataCalendario(value) == null
                    ? 'Informe uma data de fim válida.'
                    : null,
                onChanged: (_) => setState(() => _erroPeriodo = null),
              ),
              if (_erroPeriodo case final erro?) ...[
                const SizedBox(height: 8),
                Text(
                  erro,
                  key: const ValueKey('criar-sprint-erro-periodo'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: TemdasTokens.contentGap),
              TextFormField(
                key: const ValueKey('criar-sprint-tempo'),
                controller: _tempoController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Tempo previsto',
                  hintText: 'Opcional · ex.: 45min, 1h15, 2h10 ou 1,5h',
                ),
                validator: _validarTempoPrevisto,
              ),
              if (_erro case final erro?) ...[
                const SizedBox(height: TemdasTokens.contentGap),
                Text(
                  erro,
                  key: const ValueKey('criar-sprint-erro'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: ValueKey(_edicao ? 'salvar-edicao-sprint' : 'salvar-sprint'),
          onPressed: _enviando ? null : _salvar,
          icon: _enviando
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_edicao ? Icons.save_outlined : Icons.add),
          label: Text(
            _enviando
                ? _edicao
                      ? 'Salvando...'
                      : 'Criando...'
                : _edicao
                ? 'Salvar'
                : 'Criar Sprint',
          ),
        ),
      ],
    ),
  );

  Future<void> _selecionarData(bool inicio) async {
    final controller = inicio ? _dataInicioController : _dataFimController;
    final inicialInformada = _parseDataCalendario(controller.text);
    final outraData = _parseDataCalendario(
      inicio ? _dataFimController.text : _dataInicioController.text,
    );
    final hoje = DateTime.now();
    final inicial = inicialInformada ?? outraData ?? hoje;
    final primeiraData = inicial.year < 1900
        ? DateTime(inicial.year)
        : DateTime(1900);
    final ultimaData = inicial.year > 2100
        ? DateTime(inicial.year, 12, 31)
        : DateTime(2100, 12, 31);
    final selecionada = await showDatePicker(
      context: context,
      initialDate: DateTime(inicial.year, inicial.month, inicial.day),
      firstDate: primeiraData,
      lastDate: ultimaData,
    );
    if (selecionada == null || !mounted) return;
    controller.text = _formatarDataCalendario(selecionada);
    setState(() {
      _erro = null;
      _erroPeriodo = null;
    });
  }

  Future<void> _salvar() async {
    if (_enviando || !_formKey.currentState!.validate()) return;
    final dataInicio = _parseDataCalendario(_dataInicioController.text)!;
    final dataFim = _parseDataCalendario(_dataFimController.text)!;
    if (dataInicio.isAfter(dataFim)) {
      setState(() {
        _erroPeriodo = 'A data de início não pode ser posterior à data fim.';
        _erro = null;
      });
      return;
    }

    final tempoPrevistoMinutos = _parseTempoPrevistoMinutos(
      _tempoController.text,
    );
    setState(() {
      _enviando = true;
      _erro = null;
      _erroPeriodo = null;
    });
    try {
      final erro = await widget.onSalvar(
        nome: _nomeController.text.trim(),
        dataInicio: dataInicio,
        dataFim: dataFim,
        tempoPrevistoMinutos: tempoPrevistoMinutos,
      );
      if (!mounted) return;
      if (erro == null) {
        Navigator.pop(context, true);
      } else {
        setState(() => _erro = erro);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _erro = 'Não foi possível criar a Sprint. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}

int? _parseTempoPrevistoMinutos(String? value) {
  final texto = (value ?? '').trim().toLowerCase();
  if (texto.isEmpty) return null;

  final somenteMinutos = RegExp(
    r'^(\d+)\s*(?:min(?:uto(?:s)?)?|m)$',
  ).firstMatch(texto);
  if (somenteMinutos != null) return int.tryParse(somenteMinutos[1]!);

  final horasEMinutos = RegExp(
    r'^(\d+)\s*h(?:\s*(\d{1,2})\s*(?:min(?:uto(?:s)?)?|m)?)?$',
  ).firstMatch(texto);
  if (horasEMinutos != null) {
    final horas = int.tryParse(horasEMinutos[1]!);
    final minutos = int.tryParse(horasEMinutos[2] ?? '0');
    if (horas == null || minutos == null || minutos >= 60) return null;
    return horas * 60 + minutos;
  }

  // Números sem unidade e horas decimais seguem o padrão já usado no app.
  final horasDecimais = RegExp(
    r'^(\d+(?:[,.]\d+)?)\s*(?:h|horas?)?$',
  ).firstMatch(texto);
  if (horasDecimais == null) return null;
  final horas = double.tryParse(horasDecimais[1]!.replaceAll(',', '.'));
  if (horas == null || !horas.isFinite) return null;
  return (horas * 60).round();
}

String? _validarTempoPrevisto(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final minutos = _parseTempoPrevistoMinutos(value);
  if (minutos == null) {
    return 'Informe um tempo válido.';
  }
  if (minutos <= 0) return 'Informe um tempo previsto maior que zero.';
  return null;
}

DateTime? _parseDataCalendario(String? value) {
  final partes = (value ?? '').trim().split('/');
  if (partes.length != 3) return null;
  final dia = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final ano = int.tryParse(partes[2]);
  if (dia == null || mes == null || ano == null || ano < 1) return null;
  final data = DateTime(ano, mes, dia);
  if (data.year != ano || data.month != mes || data.day != dia) return null;
  return data;
}

String _formatarDataCalendario(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/'
    '${data.year.toString().padLeft(4, '0')}';

String _formatarTempoSprint(int? minutos) {
  if (minutos == null) return '';
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  if (horas == 0) return '${resto}min';
  return resto == 0 ? '${horas}h' : '${horas}h$resto';
}

class _SprintListaCard extends StatelessWidget {
  const _SprintListaCard({
    required this.sprint,
    required this.indicadores,
    required this.onTap,
  });

  final backend.Sprint sprint;
  final backend.SprintIndicadores? indicadores;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final id = sprint.id;
    final atrasada = _sprintAtrasada(sprint);
    return Card(
      child: InkWell(
        key: ValueKey('sprint-card-$id'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(TemdasTokens.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: TemdasTokens.smallGap,
                runSpacing: TemdasTokens.smallGap,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Sprint ${sprint.nome}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _SprintStatusChip(status: sprint.status),
                  if (atrasada) const _AtrasadaChip(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _periodo(sprint),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 10,
                children: [
                  _MetricaCompacta(
                    titulo: 'Tempo previsto',
                    valor: _duracao(sprint.tempoPrevistoMinutos),
                    icone: Icons.flag_outlined,
                  ),
                  _MetricaCompacta(
                    titulo: 'Total estimado',
                    valor: _duracao(indicadores?.tempoTotalEstimadoMinutos),
                    icone: Icons.hourglass_empty,
                  ),
                  _MetricaCompacta(
                    titulo: 'Executado',
                    valor: _duracao(indicadores?.tempoExecutadoMinutos),
                    icone: Icons.timer_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SprintResumoDialog extends StatelessWidget {
  const _SprintResumoDialog({
    required this.sprint,
    required this.viewModel,
    required this.demandasViewModel,
    required this.onAbrirDemanda,
    required this.onMostrarTodas,
    required this.onAbrirSprint,
    required this.onRecarregarVinculos,
  });

  final backend.Sprint sprint;
  final SprintViewModel viewModel;
  final DemandasViewModel demandasViewModel;
  final ValueChanged<int> onAbrirDemanda;
  final VoidCallback onMostrarTodas;
  final VoidCallback onAbrirSprint;
  final VoidCallback onRecarregarVinculos;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final indicadores = sprint.id == null
          ? null
          : viewModel.indicadoresDaSprint(sprint.id!);
      final falhaVinculos = viewModel.erro != null && !viewModel.carregando;
      return AlertDialog(
        key: const ValueKey('resumo-sprint-dialog'),
        title: Text('Sprint ${sprint.nome}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _SprintStatusChip(status: sprint.status),
                    if (_sprintAtrasada(sprint)) const _AtrasadaChip(),
                  ],
                ),
                const SizedBox(height: 16),
                _LinhaResumo(
                  icone: Icons.calendar_month_outlined,
                  texto: _periodo(sprint),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricaResumo(
                      titulo: 'Previsto',
                      valor: _duracao(sprint.tempoPrevistoMinutos),
                      icone: Icons.flag_outlined,
                    ),
                    _MetricaResumo(
                      titulo: 'Estimado',
                      valor: _duracao(indicadores?.tempoTotalEstimadoMinutos),
                      icone: Icons.hourglass_empty,
                    ),
                    _MetricaResumo(
                      titulo: 'Executado',
                      valor: _duracao(indicadores?.tempoExecutadoMinutos),
                      icone: Icons.timer_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Demandas vinculadas (${viewModel.vinculos.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                if (viewModel.carregando)
                  const SizedBox(
                    height: 32,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (falhaVinculos)
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Não foi possível carregar a quantidade.'),
                      ),
                      IconButton(
                        tooltip: 'Tentar carregar demandas novamente',
                        onPressed: onRecarregarVinculos,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  )
                else
                  _DemandasVinculadasSprint(
                    vinculos: viewModel.vinculos,
                    demandas: demandasViewModel.demandas,
                    limite: 5,
                    permiteAcoes: false,
                    mostrarEstimativa: false,
                    aoAbrir: onAbrirDemanda,
                    aoAcionar: (_, _, _) {},
                    aoMostrarTodas: onMostrarTodas,
                    chaveMostrarTodas: 'mostrar-tudo-demandas-sprint-resumo',
                    mensagemVazia: 'Nenhuma Demanda vinculada à Sprint.',
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          FilledButton.icon(
            key: const ValueKey('abrir-sprint-completa'),
            onPressed: onAbrirSprint,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir Sprint'),
          ),
        ],
      );
    },
  );
}

class SprintDetalhePage extends StatefulWidget {
  const SprintDetalhePage({
    super.key,
    required this.sprintId,
    this.viewModel,
    this.demandasViewModel,
    this.demandaDetalheViewModel,
  });

  final int sprintId;
  final SprintViewModel? viewModel;
  final DemandasViewModel? demandasViewModel;
  final DemandaDetalheViewModel? demandaDetalheViewModel;

  @override
  State<SprintDetalhePage> createState() => _SprintDetalhePageState();
}

class _SprintDetalhePageState extends State<SprintDetalhePage> {
  late final SprintViewModel _viewModel;
  late final bool _possuiViewModel;
  late final DemandasViewModel _demandasViewModel;
  late final bool _possuiDemandasViewModel;
  bool _mutacaoDemandaEmAndamento = false;

  @override
  void initState() {
    super.initState();
    _possuiViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? SprintViewModel();
    _possuiDemandasViewModel = widget.demandasViewModel == null;
    _demandasViewModel = widget.demandasViewModel ?? DemandasViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_carregar());
    });
  }

  @override
  void didUpdateWidget(covariant SprintDetalhePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sprintId != oldWidget.sprintId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_carregar());
      });
    }
  }

  @override
  void dispose() {
    if (_possuiViewModel) _viewModel.dispose();
    if (_possuiDemandasViewModel) _demandasViewModel.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final carregada = await _viewModel.carregarSprint(widget.sprintId);
    if (!mounted || !carregada) return;
    await _viewModel.carregarIndicadores(widget.sprintId);
    if (!mounted) return;
    await _viewModel.carregarVinculos(widget.sprintId);
    if (!mounted) return;
    await _demandasViewModel.carregarDemandas();
    if (mounted) setState(() {});
  }

  bool _permiteGerenciarVinculos(backend.Sprint sprint) =>
      sprint.status == backend.SprintStatus.planejada ||
      sprint.status == backend.SprintStatus.ativa;

  Future<void> _adicionarDemanda(backend.Sprint sprint) async {
    final sprintId = sprint.id;
    if (sprintId == null || !_permiteGerenciarVinculos(sprint)) return;
    final vinculada = await showDialog<bool>(
      context: context,
      builder: (_) => _SelecionarDemandaSprintDialog(
        demandas: _demandasViewModel.demandas,
        idsJaVinculados: _viewModel.vinculos
            .map((vinculo) => vinculo.demandaId)
            .toSet(),
        carregarIndisponiveis: () =>
            _viewModel.carregarDemandasDeOutrasSprintsAbertas(sprintId),
        onVincular: (demandaIds) async {
          final sucesso = await _viewModel.vincularDemandas(
            sprintId: sprintId,
            demandaIds: demandaIds,
          );
          return sucesso
              ? null
              : _viewModel.erro ?? 'Não foi possível vincular a Demanda.';
        },
      ),
    );
    if (vinculada != true || !mounted) return;
    await _carregar();
    if (mounted) _mostrarFeedback('Demanda vinculada à Sprint.');
  }

  void _abrirDetalhesDemanda(int demandaId) {
    unawaited(
      mostrarDetalhesDemandaDialog(
        context,
        demandaId,
        viewModel: widget.demandaDetalheViewModel,
      ),
    );
  }

  Future<void> _mostrarPainelDemandas(backend.Sprint sprint) async {
    await _mostrarPainelLateralDemandas(
      context,
      titulo: 'Demandas da Sprint',
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _DemandasVinculadasSprint(
          vinculos: _viewModel.vinculos,
          demandas: _demandasViewModel.demandas,
          permiteAcoes:
              _permiteGerenciarVinculos(sprint) && !_mutacaoDemandaEmAndamento,
          aoAbrir: _abrirDetalhesDemanda,
          aoAcionar: (id, demanda, acao) =>
              _removerDemanda(sprint, demanda, id, acao),
          mensagemVazia: 'Nenhuma Demanda vinculada à Sprint.',
        ),
      ),
    );
  }

  Future<void> _removerDemanda(
    backend.Sprint sprint,
    backend.Demanda? demanda,
    int demandaId,
    _AcaoDemandaSprint acao,
  ) async {
    final sprintId = sprint.id;
    if (sprintId == null || !_permiteGerenciarVinculos(sprint)) return;
    if (acao == _AcaoDemandaSprint.desvincular) {
      final temDescendentes =
          demanda != null &&
          _demandasViewModel
              .descendentesDe(demanda)
              .any(
                (filha) => _viewModel.vinculos.any(
                  (vinculo) => vinculo.demandaId == filha.id,
                ),
              );
      final confirmado = await _confirmarOperacao(
        chave: 'confirmar-desvincular-demanda-$demandaId',
        titulo: 'Desvincular da Sprint?',
        mensagem: temDescendentes
            ? 'A Demanda e suas filhas serão desvinculadas desta Sprint.'
            : 'A Demanda será desvinculada desta Sprint.',
        acao: 'Desvincular',
      );
      if (!confirmado || !mounted) return;
      setState(() => _mutacaoDemandaEmAndamento = true);
      try {
        final sucesso = await _viewModel.desvincularDemanda(
          sprintId: sprintId,
          demandaId: demandaId,
        );
        if (!mounted) return;
        if (!sucesso) {
          _mostrarFeedback(
            _viewModel.erro ?? 'Não foi possível desvincular a Demanda.',
            erro: true,
          );
          return;
        }
        await _carregar();
        if (mounted) _mostrarFeedback('Demanda desvinculada da Sprint.');
      } finally {
        if (mounted) setState(() => _mutacaoDemandaEmAndamento = false);
      }
      return;
    }

    if (acao != _AcaoDemandaSprint.excluir || demanda == null) return;
    final excluirArvore = _demandasViewModel.possuiDescendentes(demanda);
    final confirmado = await _confirmarOperacao(
      chave: 'confirmar-excluir-demanda-sprint-$demandaId',
      titulo: excluirArvore
          ? 'Excluir árvore de Demandas?'
          : 'Excluir Demanda?',
      mensagem: excluirArvore
          ? 'A Demanda e todas as suas filhas serão excluídas permanentemente.'
          : 'A Demanda será excluída permanentemente.',
      acao: 'Excluir permanentemente',
      destrutiva: true,
    );
    if (!confirmado || !mounted) return;
    setState(() => _mutacaoDemandaEmAndamento = true);
    try {
      final excluida = excluirArvore
          ? await _demandasViewModel.excluirArvoreDemanda(demanda)
          : await _demandasViewModel.excluirDemanda(demanda);
      if (!mounted) return;
      if (!excluida) {
        _mostrarFeedback(
          _demandasViewModel.erro ?? 'Não foi possível excluir a Demanda.',
          erro: true,
        );
        return;
      }
      await _carregar();
      if (mounted) _mostrarFeedback('Demanda excluída permanentemente.');
    } finally {
      if (mounted) setState(() => _mutacaoDemandaEmAndamento = false);
    }
  }

  Widget _arvoreDemandasVinculadas(backend.Sprint sprint, {int? limite}) =>
      _DemandasVinculadasSprint(
        vinculos: _viewModel.vinculos,
        demandas: _demandasViewModel.demandas,
        limite: limite,
        permiteAcoes:
            _permiteGerenciarVinculos(sprint) && !_mutacaoDemandaEmAndamento,
        aoAbrir: _abrirDetalhesDemanda,
        aoAcionar: (id, demanda, acao) =>
            _removerDemanda(sprint, demanda, id, acao),
        aoMostrarTodas: () => _mostrarPainelDemandas(sprint),
        chaveMostrarTodas: 'mostrar-tudo-demandas-sprint',
        mensagemVazia: 'Nenhuma Demanda vinculada à Sprint.',
      );

  Future<void> _editarSprint(backend.Sprint sprint) async {
    final id = sprint.id;
    if (id == null) return;
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _CriarSprintDialog(
        sprint: sprint,
        onSalvar:
            ({
              required nome,
              required dataInicio,
              required dataFim,
              tempoPrevistoMinutos,
            }) async {
              final sucesso = await _viewModel.atualizarSprint(
                id: id,
                nome: nome,
                dataInicio: dataInicio,
                dataFim: dataFim,
                tempoPrevistoMinutos: tempoPrevistoMinutos,
              );
              return sucesso
                  ? null
                  : _viewModel.erro ?? 'Não foi possível editar a Sprint.';
            },
      ),
    );
    if (salvo == true) {
      await _recarregarAposAcao('Sprint atualizada.');
    }
  }

  Future<void> _iniciarSprint(backend.Sprint sprint) async {
    final id = sprint.id;
    if (id == null) return;

    final listaCarregada = await _viewModel.carregarSprints();
    if (!mounted) return;
    if (!listaCarregada) {
      _mostrarFeedback(
        _viewModel.erro ?? 'Não foi possível verificar as Sprints ativas.',
        erro: true,
      );
      return;
    }

    final ativa = _outraSprintAtiva(id);
    if (ativa != null) {
      await _mostrarSprintAtivaExistente(ativa);
      return;
    }

    final confirmado = await _confirmarOperacao(
      chave: 'confirmar-inicio-sprint-dialog',
      titulo: 'Iniciar Sprint?',
      mensagem: 'A Sprint ficará ativa a partir de agora.',
      acao: 'Iniciar Sprint',
    );
    if (!confirmado || !mounted) return;

    final sucesso = await _viewModel.ativarSprint(id);
    if (!mounted) return;
    if (sucesso) {
      await _recarregarAposAcao('Sprint iniciada.');
      return;
    }

    final erro = _viewModel.erro ?? 'Não foi possível iniciar a Sprint.';
    final listaAtualizada = await _viewModel.carregarSprints();
    if (!mounted) return;
    final sprintAtiva = listaAtualizada ? _outraSprintAtiva(id) : null;
    if (sprintAtiva != null) {
      await _mostrarSprintAtivaExistente(sprintAtiva);
      return;
    }
    await _carregar();
    if (mounted) _mostrarFeedback(erro, erro: true);
  }

  Future<void> _cancelarSprint(backend.Sprint sprint) async {
    final id = sprint.id;
    if (id == null) return;
    final confirmado = await _confirmarOperacao(
      chave: 'confirmar-cancelamento-sprint-dialog',
      titulo: 'Cancelar Sprint?',
      mensagem:
          'Os vínculos com Demandas serão removidos. As Demandas e seus '
          'registros de tempo serão preservados.',
      acao: 'Cancelar Sprint',
      destrutiva: true,
    );
    if (!confirmado || !mounted) return;
    await _executarAcao(
      () => _viewModel.cancelarSprint(id),
      sucesso: 'Sprint cancelada.',
      erroPadrao: 'Não foi possível cancelar a Sprint.',
    );
  }

  Future<void> _reabrirSprint(backend.Sprint sprint) async {
    final id = sprint.id;
    if (id == null) return;
    final confirmado = await _confirmarOperacao(
      chave: 'confirmar-reabertura-sprint-dialog',
      titulo: 'Reabrir Sprint?',
      mensagem: 'A Sprint voltará ao status Planejada.',
      acao: 'Reabrir Sprint',
    );
    if (!confirmado || !mounted) return;
    await _executarAcao(
      () => _viewModel.reabrirSprint(id),
      sucesso: 'Sprint reaberta.',
      erroPadrao: 'Não foi possível reabrir a Sprint.',
    );
  }

  Future<void> _concluirSprint(backend.Sprint sprint) async {
    final id = sprint.id;
    if (id == null) return;
    final carregouResumo = await _viewModel.carregarResumoConclusao(id);
    if (!mounted) return;
    if (!carregouResumo || _viewModel.resumoConclusao == null) {
      _mostrarFeedback(
        _viewModel.erro ?? 'Não foi possível carregar o resumo da Sprint.',
        erro: true,
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _ConfirmarConclusaoSprintDialog(resumo: _viewModel.resumoConclusao!),
    );
    if (confirmado != true || !mounted) return;
    await _executarAcao(
      () => _viewModel.concluirSprint(id),
      sucesso: 'Sprint concluída.',
      erroPadrao: 'Não foi possível concluir a Sprint.',
    );
  }

  Future<void> _excluirSprint(backend.Sprint sprint) async {
    final id = sprint.id;
    if (id == null) return;
    final confirmado = await _confirmarOperacao(
      chave: 'confirmar-exclusao-sprint-dialog',
      titulo: 'Excluir Sprint?',
      mensagem:
          'A Sprint e seus vínculos serão excluídos permanentemente. '
          'As Demandas e os registros de tempo não serão excluídos.',
      acao: 'Excluir Sprint',
      destrutiva: true,
    );
    if (!confirmado || !mounted) return;

    final excluida = await _viewModel.excluirSprint(id);
    if (!mounted) return;
    if (!excluida) {
      final erro = _viewModel.erro ?? 'Não foi possível excluir a Sprint.';
      await _carregar();
      if (mounted) _mostrarFeedback(erro, erro: true);
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.sprint);
  }

  Future<void> _executarAcao(
    Future<bool> Function() executar, {
    required String sucesso,
    required String erroPadrao,
  }) async {
    final realizada = await executar();
    if (!mounted) return;
    final erro = realizada ? null : _viewModel.erro ?? erroPadrao;
    await _carregar();
    if (!mounted) return;
    _mostrarFeedback(realizada ? sucesso : erro!, erro: !realizada);
  }

  Future<void> _recarregarAposAcao(String mensagem) async {
    await _carregar();
    if (mounted) _mostrarFeedback(mensagem);
  }

  Future<bool> _confirmarOperacao({
    required String chave,
    required String titulo,
    required String mensagem,
    required String acao,
    bool destrutiva = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          key: ValueKey(chave),
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              key: ValueKey('$chave-cancelar'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              key: ValueKey('$chave-confirmar'),
              onPressed: () => Navigator.pop(dialogContext, true),
              style: destrutiva
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        dialogContext,
                      ).colorScheme.error,
                    )
                  : null,
              child: Text(acao),
            ),
          ],
        ),
      ) ==
      true;

  backend.Sprint? _outraSprintAtiva(int sprintId) {
    for (final sprint in _viewModel.sprints) {
      if (sprint.id != sprintId &&
          sprint.status == backend.SprintStatus.ativa) {
        return sprint;
      }
    }
    return null;
  }

  Future<void> _mostrarSprintAtivaExistente(backend.Sprint ativa) async {
    final id = ativa.id;
    if (id == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('sprint-ativa-existente-dialog'),
        title: const Text('Já existe uma Sprint ativa'),
        content: Text(
          'Sprint ${ativa.nome} está ativa. Abra-a para continuar.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('ajustar-sprint-ativa'),
            onPressed: () => _navegarParaSprintAtiva(dialogContext, id),
            child: const Text('Ajustar Sprint atual'),
          ),
          OutlinedButton(
            key: const ValueKey('finalizar-sprint-ativa'),
            onPressed: () => _navegarParaSprintAtiva(dialogContext, id),
            child: const Text('Finalizar Sprint atual'),
          ),
          FilledButton(
            key: const ValueKey('cancelar-sprint-ativa'),
            onPressed: () => _navegarParaSprintAtiva(dialogContext, id),
            child: const Text('Cancelar Sprint atual'),
          ),
        ],
      ),
    );
  }

  void _navegarParaSprintAtiva(BuildContext dialogContext, int id) {
    final navigator = Navigator.of(dialogContext);
    navigator.pop();
    navigator.pushNamed(AppRoutes.detalheDaSprint(id));
  }

  void _mostrarFeedback(String mensagem, {bool erro = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: erro ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  Widget _acoesCabecalho(backend.Sprint sprint) {
    final ocupado = _viewModel.carregando || _viewModel.enviando;
    final botoes = <Widget>[
      OutlinedButton.icon(
        key: const ValueKey('editar-sprint'),
        onPressed: ocupado ? null : () => _editarSprint(sprint),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Editar'),
      ),
      if (sprint.status == backend.SprintStatus.planejada)
        FilledButton.icon(
          key: const ValueKey('iniciar-sprint'),
          onPressed: ocupado ? null : () => _iniciarSprint(sprint),
          icon: _viewModel.enviando
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: const Text('Iniciar Sprint'),
        ),
      if (sprint.status == backend.SprintStatus.ativa)
        FilledButton.icon(
          key: const ValueKey('concluir-sprint'),
          onPressed: ocupado ? null : () => _concluirSprint(sprint),
          icon: _viewModel.enviando
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Concluir Sprint'),
        ),
      if (sprint.status == backend.SprintStatus.cancelada)
        FilledButton.icon(
          key: const ValueKey('reabrir-sprint'),
          onPressed: ocupado ? null : () => _reabrirSprint(sprint),
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Reabrir Sprint'),
        ),
      if (sprint.status == backend.SprintStatus.planejada ||
          sprint.status == backend.SprintStatus.ativa ||
          sprint.status == backend.SprintStatus.cancelada)
        PopupMenuButton<_AcaoMenuSprint>(
          key: const ValueKey('acoes-sprint'),
          tooltip: 'Mais ações da Sprint',
          enabled: !ocupado,
          onSelected: (acao) {
            switch (acao) {
              case _AcaoMenuSprint.cancelar:
                _cancelarSprint(sprint);
              case _AcaoMenuSprint.excluir:
                _excluirSprint(sprint);
            }
          },
          itemBuilder: (_) => [
            if (sprint.status == backend.SprintStatus.planejada ||
                sprint.status == backend.SprintStatus.ativa)
              const PopupMenuItem(
                key: ValueKey('menu-cancelar-sprint'),
                value: _AcaoMenuSprint.cancelar,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cancel_outlined),
                  title: Text('Cancelar Sprint'),
                ),
              ),
            if (sprint.status == backend.SprintStatus.planejada ||
                sprint.status == backend.SprintStatus.ativa)
              const PopupMenuDivider(),
            PopupMenuItem(
              key: const ValueKey('menu-excluir-sprint'),
              value: _AcaoMenuSprint.excluir,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Excluir Sprint',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
        ),
    ];
    return Wrap(
      spacing: TemdasTokens.smallGap,
      runSpacing: TemdasTokens.smallGap,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: botoes,
    );
  }

  void _voltar() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.sprint);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => PageScaffold(
      title: 'Sprint',
      route: AppRoutes.sprint,
      body: _conteudo(context),
    ),
  );

  Widget _conteudo(BuildContext context) {
    final sprint = _viewModel.sprintSelecionada?.id == widget.sprintId
        ? _viewModel.sprintSelecionada
        : null;

    if (_viewModel.carregando && sprint == null) {
      return const Center(
        child: CircularProgressIndicator(key: ValueKey('carregando-sprint')),
      );
    }

    if (_viewModel.erro != null && sprint == null) {
      return _EstadoSprint(
        icone: Icons.cloud_off_outlined,
        titulo: 'Não foi possível carregar a Sprint',
        mensagem: _viewModel.erro!,
        acao: FilledButton.icon(
          key: const ValueKey('tentar-carregar-sprint'),
          onPressed: _viewModel.carregando ? null : _carregar,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      );
    }

    if (sprint == null) {
      return _EstadoSprint(
        icone: Icons.search_off_outlined,
        titulo: 'Sprint não encontrada',
        mensagem: 'A Sprint #${widget.sprintId} não foi encontrada.',
        acao: OutlinedButton.icon(
          onPressed: _voltar,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar para Sprints'),
        ),
      );
    }

    final indicadores = _viewModel.indicadores;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: ListView(
          key: const ValueKey('sprint-detalhe-scroll'),
          padding: const EdgeInsets.all(TemdasTokens.pagePadding),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _voltar,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para Sprints'),
              ),
            ),
            const SizedBox(height: 4),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: TemdasTokens.contentGap,
                      runSpacing: TemdasTokens.contentGap,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Sprint ${sprint.nome}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            _SprintStatusChip(status: sprint.status),
                            if (_sprintAtrasada(sprint)) const _AtrasadaChip(),
                          ],
                        ),
                        _acoesCabecalho(sprint),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _LinhaResumo(
                      icone: Icons.calendar_month_outlined,
                      texto: _periodo(sprint),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TemdasTokens.contentGap),
            LayoutBuilder(
              builder: (context, constraints) {
                final largura = constraints.maxWidth >= 700
                    ? (constraints.maxWidth - 2 * TemdasTokens.contentGap) / 3
                    : (constraints.maxWidth - TemdasTokens.contentGap) / 2;
                return Wrap(
                  spacing: TemdasTokens.contentGap,
                  runSpacing: TemdasTokens.contentGap,
                  children: [
                    SizedBox(
                      width: largura,
                      child: ResumoCard(
                        titulo: 'Tempo previsto',
                        valor: _duracao(sprint.tempoPrevistoMinutos),
                        icone: Icons.flag_outlined,
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: ResumoCard(
                        titulo: 'Tempo total estimado',
                        valor: _duracao(indicadores?.tempoTotalEstimadoMinutos),
                        icone: Icons.hourglass_empty,
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: ResumoCard(
                        titulo: 'Tempo executado',
                        valor: _duracao(indicadores?.tempoExecutadoMinutos),
                        icone: Icons.timer_outlined,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: TemdasTokens.contentGap),
            _SecaoSprint(
              titulo: 'Demandas vinculadas (${_viewModel.vinculos.length})',
              icone: Icons.account_tree_outlined,
              acao: _permiteGerenciarVinculos(sprint)
                  ? OutlinedButton.icon(
                      key: const ValueKey('adicionar-demanda-sprint'),
                      onPressed:
                          _viewModel.enviando ||
                              _demandasViewModel.enviando ||
                              _mutacaoDemandaEmAndamento
                          ? null
                          : () => _adicionarDemanda(sprint),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar demanda'),
                    )
                  : null,
              child: _arvoreDemandasVinculadas(sprint, limite: 5),
            ),
            const SizedBox(height: TemdasTokens.contentGap),
            if (_viewModel.erro != null) ...[
              const SizedBox(height: TemdasTokens.contentGap),
              _AvisoErro(mensagem: _viewModel.erro!, onTentar: _carregar),
            ],
          ],
        ),
      ),
    );
  }
}

enum _AcaoMenuSprint { cancelar, excluir }

class _SelecionarDemandaSprintDialog extends StatefulWidget {
  const _SelecionarDemandaSprintDialog({
    required this.demandas,
    required this.idsJaVinculados,
    required this.carregarIndisponiveis,
    required this.onVincular,
  });

  final List<backend.Demanda> demandas;
  final Set<int> idsJaVinculados;
  final Future<Map<int, backend.Sprint>?> Function() carregarIndisponiveis;
  final Future<String?> Function(List<int> demandaIds) onVincular;

  @override
  State<_SelecionarDemandaSprintDialog> createState() =>
      _SelecionarDemandaSprintDialogState();
}

class _SelecionarDemandaSprintDialogState
    extends State<_SelecionarDemandaSprintDialog> {
  final _buscaController = TextEditingController();
  Map<int, backend.Sprint> _indisponiveis = const {};
  bool _verificandoDisponibilidade = true;
  bool _falhouDisponibilidade = false;
  bool _enviando = false;
  String _busca = '';
  String? _erro;
  final Set<int> _selecionadas = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_carregarIndisponiveis());
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarIndisponiveis() async {
    try {
      final indisponiveis = await widget.carregarIndisponiveis();
      if (!mounted) return;
      setState(() {
        _indisponiveis = indisponiveis ?? const {};
        _verificandoDisponibilidade = false;
        _falhouDisponibilidade = indisponiveis == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verificandoDisponibilidade = false;
        _falhouDisponibilidade = true;
      });
    }
  }

  List<({backend.Demanda demanda, Set<int> idsDaArvore, int descendentes})>
  _demandasVisiveis() {
    final porId = <int, backend.Demanda>{
      for (final demanda in widget.demandas)
        if (demanda.id != null) demanda.id!: demanda,
    };
    final consulta = _busca.trim().toLowerCase();
    final filhosPorPai = <int, List<int>>{};
    for (final id in porId.keys) {
      final paiId = porId[id]?.demandaPaiId;
      if (paiId != null && porId.containsKey(paiId)) {
        filhosPorPai.putIfAbsent(paiId, () => []).add(id);
      }
    }

    final resultado =
        <({backend.Demanda demanda, Set<int> idsDaArvore, int descendentes})>[];
    for (final demanda in widget.demandas) {
      final id = demanda.id;
      if (id == null) continue;
      final paiId = demanda.demandaPaiId;
      if (paiId != null && porId.containsKey(paiId)) continue;

      final texto = '${demanda.id} ${demanda.titulo}'.toLowerCase();
      if (consulta.isNotEmpty && !texto.contains(consulta)) continue;

      final idsDaArvore = <int>{};
      void adicionar(int atualId) {
        if (!idsDaArvore.add(atualId)) return;
        for (final filha in filhosPorPai[atualId] ?? const <int>[]) {
          adicionar(filha);
        }
      }

      adicionar(id);
      if (idsDaArvore.any(widget.idsJaVinculados.contains)) continue;
      resultado.add((
        demanda: demanda,
        idsDaArvore: idsDaArvore,
        descendentes: idsDaArvore.length - 1,
      ));
    }
    return resultado;
  }

  Future<void> _vincular() async {
    if (_enviando || _selecionadas.isEmpty) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final erro = await widget.onVincular(_selecionadas.toList());
      if (!mounted) return;
      if (erro == null) {
        Navigator.pop(context, true);
      } else {
        setState(() => _erro = erro);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _erro = 'Não foi possível vincular a Demanda. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linhas = _demandasVisiveis();
    return AlertDialog(
      key: const ValueKey('selecionar-demanda-sprint-dialog'),
      title: const Text('Adicionar demanda'),
      content: SizedBox(
        width: 560,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('buscar-demanda-sprint'),
              controller: _buscaController,
              onChanged: (valor) => setState(() => _busca = valor),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar Demanda',
              ),
            ),
            if (_verificandoDisponibilidade)
              const LinearProgressIndicator(
                key: ValueKey('verificando-vinculos-outras-sprints'),
              ),
            if (_falhouDisponibilidade)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Não foi possível verificar outras Sprints. O backend validará a tentativa.',
                  key: ValueKey('aviso-disponibilidade-demanda'),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: linhas.isEmpty
                  ? const Center(child: Text('Nenhuma Demanda encontrada.'))
                  : ListView.builder(
                      key: const ValueKey('arvore-selecao-demandas-sprint'),
                      itemCount: linhas.length,
                      itemBuilder: (context, index) {
                        final linha = linhas[index];
                        final demanda = linha.demanda;
                        final id = demanda.id!;
                        backend.Sprint? outraSprint;
                        for (final idDaArvore in linha.idsDaArvore) {
                          outraSprint ??= _indisponiveis[idDaArvore];
                        }
                        final selecionavel =
                            outraSprint == null && !_verificandoDisponibilidade;
                        final selecionada = _selecionadas.contains(id);
                        final tooltip = outraSprint != null
                            ? 'Já pertence à Sprint ${outraSprint.nome}'
                            : demanda.tempoEstimadoMinutos > 0
                            ? 'Estimativa própria: ${_duracao(demanda.tempoEstimadoMinutos)}'
                            : null;
                        return ListTile(
                          key: ValueKey('candidata-demanda-sprint-$id'),
                          enabled: selecionavel && !_enviando,
                          selected: selecionada,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          leading: Checkbox(
                            value: selecionada,
                            onChanged: selecionavel && !_enviando
                                ? (marcada) => setState(() {
                                    if (marcada == true) {
                                      _selecionadas.add(id);
                                    } else {
                                      _selecionadas.remove(id);
                                    }
                                    _erro = null;
                                  })
                                : null,
                          ),
                          title: Text(formatarIdentificacaoDemanda(demanda)),
                          subtitle: outraSprint != null
                              ? Text('Já pertence à Sprint ${outraSprint.nome}')
                              : demanda.tempoEstimadoMinutos > 0
                              ? Text(
                                  'Estimativa própria: ${_duracao(demanda.tempoEstimadoMinutos)}',
                                )
                              : tooltip == null
                              ? null
                              : Text(tooltip),
                          trailing:
                              outraSprint == null &&
                                  demanda.tempoEstimadoMinutos > 0
                              ? Text(
                                  _tempoDemandaRaiz(
                                    demanda.tempoEstimadoMinutos,
                                    linha.descendentes,
                                  ),
                                )
                              : null,
                          onTap: selecionavel && !_enviando
                              ? () => setState(() {
                                  if (_selecionadas.contains(id)) {
                                    _selecionadas.remove(id);
                                  } else {
                                    _selecionadas.add(id);
                                  }
                                  _erro = null;
                                })
                              : null,
                        );
                      },
                    ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 8),
              Text(
                _erro!,
                key: const ValueKey('erro-vinculo-demanda-sprint'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: const ValueKey('confirmar-vinculo-demanda-sprint'),
          onPressed: _enviando || _selecionadas.isEmpty ? null : _vincular,
          icon: _enviando
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link),
          label: Text(
            _enviando
                ? 'Vinculando...'
                : _selecionadas.isEmpty
                ? 'Vincular'
                : 'Vincular (${_selecionadas.length})',
          ),
        ),
      ],
    );
  }

  String _tempoDemandaRaiz(int minutos, int descendentes) {
    final tempo = _duracao(minutos);
    if (descendentes == 0) return tempo;
    final rotulo = descendentes == 1 ? 'demanda filha' : 'demandas filhas';
    return '$tempo | + $descendentes $rotulo';
  }
}

enum _AcaoDemandaSprint { excluir, backlog, desvincular }

class _DemandasVinculadasSprint extends StatelessWidget {
  const _DemandasVinculadasSprint({
    required this.vinculos,
    required this.demandas,
    required this.permiteAcoes,
    this.mostrarEstimativa = true,
    required this.aoAbrir,
    required this.aoAcionar,
    required this.mensagemVazia,
    this.limite,
    this.aoMostrarTodas,
    this.chaveMostrarTodas = 'mostrar-tudo-demandas-sprint',
  });

  final List<backend.SprintDemanda> vinculos;
  final List<backend.Demanda> demandas;
  final int? limite;
  final bool permiteAcoes;
  final bool mostrarEstimativa;
  final ValueChanged<int> aoAbrir;
  final void Function(
    int demandaId,
    backend.Demanda? demanda,
    _AcaoDemandaSprint acao,
  )
  aoAcionar;
  final VoidCallback? aoMostrarTodas;
  final String chaveMostrarTodas;
  final String mensagemVazia;

  @override
  Widget build(BuildContext context) {
    if (vinculos.isEmpty) return Text(mensagemVazia);
    final demandasPorId = {
      for (final demanda in demandas)
        if (demanda.id != null) demanda.id!: demanda,
    };
    final linhas = _hierarquiaDemandasVinculadas(vinculos, demandasPorId);
    final quantidade = limite == null || limite! > linhas.length
        ? linhas.length
        : limite!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final linha in linhas.take(quantidade))
          _LinhaDemandaSprint(
            demandaId: linha.id,
            demanda: demandasPorId[linha.id],
            nivel: linha.nivel,
            permiteMenu: permiteAcoes,
            mostrarEstimativa: mostrarEstimativa,
            onAbrir: () => aoAbrir(linha.id),
            onAcao: (acao) =>
                aoAcionar(linha.id, demandasPorId[linha.id], acao),
          ),
        if (limite != null &&
            vinculos.length > limite! &&
            aoMostrarTodas != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ValueKey(chaveMostrarTodas),
              onPressed: aoMostrarTodas,
              icon: const Icon(Icons.open_in_full),
              label: const Text('Mostrar tudo'),
            ),
          ),
      ],
    );
  }
}

List<({int id, int nivel})> _hierarquiaDemandasVinculadas(
  List<backend.SprintDemanda> vinculos,
  Map<int, backend.Demanda> demandasPorId,
) {
  final idsVinculados = vinculos.map((vinculo) => vinculo.demandaId).toSet();
  final filhosPorPai = <int, List<int>>{};
  for (final id in idsVinculados) {
    final paiId = demandasPorId[id]?.demandaPaiId;
    if (paiId != null && idsVinculados.contains(paiId)) {
      filhosPorPai.putIfAbsent(paiId, () => []).add(id);
    }
  }
  final raizes = idsVinculados.where((id) {
    final paiId = demandasPorId[id]?.demandaPaiId;
    return paiId == null || !idsVinculados.contains(paiId);
  }).toList();
  final linhas = <({int id, int nivel})>[];
  final visitados = <int>{};
  void adicionar(int id, int nivel) {
    if (!visitados.add(id)) return;
    linhas.add((id: id, nivel: nivel));
    for (final filha in filhosPorPai[id] ?? const <int>[]) {
      adicionar(filha, nivel + 1);
    }
  }

  for (final raiz in raizes) {
    adicionar(raiz, 0);
  }
  for (final id in idsVinculados) {
    adicionar(id, 0);
  }
  return linhas;
}

Future<void> _mostrarPainelLateralDemandas(
  BuildContext context, {
  required String titulo,
  required Widget child,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Fechar Demandas vinculadas',
  barrierColor: Colors.black54,
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (dialogContext, _, _) {
    final tamanho = MediaQuery.sizeOf(dialogContext);
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        key: const ValueKey('painel-lateral-demandas-sprint'),
        color: Theme.of(dialogContext).colorScheme.surface,
        elevation: 16,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(TemdasTokens.cardRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: tamanho.width < 560 ? tamanho.width : 560,
          height: tamanho.height,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: Theme.of(dialogContext).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('fechar-painel-demandas-sprint'),
                        tooltip: 'Fechar lista',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
  transitionBuilder: (context, animation, secondaryAnimation, child) =>
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
);

class _LinhaDemandaSprint extends StatelessWidget {
  const _LinhaDemandaSprint({
    required this.demandaId,
    required this.demanda,
    required this.nivel,
    required this.permiteMenu,
    required this.mostrarEstimativa,
    required this.onAbrir,
    required this.onAcao,
  });

  final int demandaId;
  final backend.Demanda? demanda;
  final int nivel;
  final bool permiteMenu;
  final bool mostrarEstimativa;
  final VoidCallback onAbrir;
  final ValueChanged<_AcaoDemandaSprint> onAcao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estimativa = demanda?.tempoEstimadoMinutos;
    return Padding(
      padding: EdgeInsets.only(left: nivel * 24, bottom: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: nivel == 0
              ? null
              : Border(
                  left: BorderSide(
                    color: tema.colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
        ),
        child: ListTile(
          key: ValueKey('demanda-vinculada-sprint-$demandaId'),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: onAbrir,
          leading: Icon(
            nivel == 0
                ? Icons.task_alt_outlined
                : Icons.subdirectory_arrow_right,
            color: tema.colorScheme.primary,
          ),
          title: Text(
            demanda == null
                ? 'Demanda #$demandaId'
                : formatarIdentificacaoDemanda(demanda!),
          ),
          subtitle: mostrarEstimativa && estimativa != null && estimativa > 0
              ? Text('Estimativa própria: ${_duracao(estimativa)}')
              : null,
          trailing: permiteMenu
              ? PopupMenuButton<_AcaoDemandaSprint>(
                  key: ValueKey('menu-demanda-sprint-$demandaId'),
                  tooltip: 'Ações da Demanda',
                  onSelected: onAcao,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _AcaoDemandaSprint.excluir,
                      enabled: demanda != null,
                      key: ValueKey('menu-excluir-demanda-sprint-$demandaId'),
                      child: const Text('Excluir permanentemente'),
                    ),
                    PopupMenuItem(
                      value: _AcaoDemandaSprint.backlog,
                      enabled: false,
                      key: ValueKey('menu-backlog-demanda-sprint-$demandaId'),
                      child: const Text('Enviar para Backlog'),
                    ),
                    PopupMenuItem(
                      value: _AcaoDemandaSprint.desvincular,
                      key: ValueKey(
                        'menu-desvincular-demanda-sprint-$demandaId',
                      ),
                      child: const Text('Desvincular da Sprint'),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class _ConfirmarConclusaoSprintDialog extends StatelessWidget {
  const _ConfirmarConclusaoSprintDialog({required this.resumo});

  final backend.SprintConclusaoResponse resumo;

  @override
  Widget build(BuildContext context) {
    final pendentes = resumo.quantidadeDemandasNaoConcluidas;
    final diferenca = resumo.indicadores.diferencaExecutadoEstimadoMinutos;
    final comparacao = switch (diferenca.sign) {
      1 => 'Executado acima do estimado em ${_duracao(diferenca.abs())}.',
      -1 => 'Executado abaixo do estimado em ${_duracao(diferenca.abs())}.',
      _ => null,
    };
    final corAlerta = diferenca > 0
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.tertiaryContainer;

    return AlertDialog(
      key: const ValueKey('confirmar-conclusao-sprint-dialog'),
      scrollable: true,
      title: const Text('Concluir Sprint?'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              pendentes == 1
                  ? 'Há 1 Demanda não concluída.'
                  : 'Há $pendentes Demandas não concluídas.',
              key: const ValueKey('demandas-pendentes-conclusao'),
            ),
            const SizedBox(height: 12),
            Text(
              'Tempo executado: ${_duracao(resumo.indicadores.tempoExecutadoMinutos)}',
            ),
            Text(
              'Tempo estimado: ${_duracao(resumo.indicadores.tempoTotalEstimadoMinutos)}',
            ),
            if (comparacao != null) ...[
              const SizedBox(height: 12),
              Card(
                color: corAlerta,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          comparacao,
                          key: const ValueKey('comparacao-tempo-conclusao'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text('Essa diferença não impede a conclusão da Sprint.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('voltar-conclusao-sprint'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Voltar'),
        ),
        FilledButton(
          key: const ValueKey('confirmar-conclusao-sprint'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Concluir Sprint'),
        ),
      ],
    );
  }
}

class _EstadoSprint extends StatelessWidget {
  const _EstadoSprint({
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 52, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center),
            if (acao != null) ...[const SizedBox(height: 20), acao!],
          ],
        ),
      ),
    ),
  );
}

class _SprintStatusChip extends StatelessWidget {
  const _SprintStatusChip({required this.status});

  final backend.SprintStatus status;

  @override
  Widget build(BuildContext context) {
    final semantic = TemdasSemanticColors.of(context);
    final cor = switch (status) {
      backend.SprintStatus.planejada => semantic.aberta,
      backend.SprintStatus.ativa => semantic.emAndamento,
      backend.SprintStatus.concluida => semantic.concluida,
      backend.SprintStatus.cancelada => semantic.cancelada,
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: cor.withValues(alpha: .12),
      avatar: Icon(_iconeStatus(status), size: 16, color: cor),
      label: Text(_rotuloStatus(status), style: TextStyle(color: cor)),
    );
  }
}

class _AtrasadaChip extends StatelessWidget {
  const _AtrasadaChip();

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.error;
    return Chip(
      key: const ValueKey('sprint-atrasada'),
      visualDensity: VisualDensity.compact,
      backgroundColor: cor.withValues(alpha: .12),
      avatar: Icon(Icons.warning_amber_rounded, size: 16, color: cor),
      label: Text('Atrasada', style: TextStyle(color: cor)),
    );
  }
}

class _MetricaCompacta extends StatelessWidget {
  const _MetricaCompacta({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  final String titulo;
  final String valor;
  final IconData icone;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icone,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 6),
      Text('$titulo: ', style: Theme.of(context).textTheme.bodySmall),
      Text(valor, style: Theme.of(context).textTheme.labelLarge),
    ],
  );
}

class _MetricaResumo extends StatelessWidget {
  const _MetricaResumo({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  final String titulo;
  final String valor;
  final IconData icone;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 145),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(TemdasTokens.controlRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        Text(titulo, style: Theme.of(context).textTheme.bodySmall),
        Text(
          valor,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _LinhaResumo extends StatelessWidget {
  const _LinhaResumo({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icone, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Flexible(child: Text(texto)),
    ],
  );
}

class _SecaoSprint extends StatelessWidget {
  const _SecaoSprint({
    required this.titulo,
    required this.icone,
    required this.child,
    this.acao,
  });

  final String titulo;
  final IconData icone;
  final Widget child;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: TemdasTokens.contentGap,
            runSpacing: TemdasTokens.smallGap,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              ?acao,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _AvisoErro extends StatelessWidget {
  const _AvisoErro({required this.mensagem, required this.onTentar});

  final String mensagem;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: Text(mensagem)),
          IconButton(
            tooltip: 'Tentar carregar novamente',
            onPressed: onTentar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    ),
  );
}

String _duracao(int? minutos) =>
    minutos == null ? '—' : formatDuration(Duration(minutes: minutos));

String _periodo(backend.Sprint sprint) =>
    '${_data(sprint.dataInicio)} – ${_data(sprint.dataFim)}';

String _data(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/${data.year}';

String _rotuloStatus(backend.SprintStatus status) => switch (status) {
  backend.SprintStatus.planejada => 'Planejada',
  backend.SprintStatus.ativa => 'Ativa',
  backend.SprintStatus.concluida => 'Concluída',
  backend.SprintStatus.cancelada => 'Cancelada',
};

IconData _iconeStatus(backend.SprintStatus status) => switch (status) {
  backend.SprintStatus.planejada => Icons.event_note_outlined,
  backend.SprintStatus.ativa => Icons.play_circle_outline,
  backend.SprintStatus.concluida => Icons.check_circle_outline,
  backend.SprintStatus.cancelada => Icons.cancel_outlined,
};

bool _sprintAtrasada(backend.Sprint sprint) {
  if (sprint.status == backend.SprintStatus.concluida ||
      sprint.status == backend.SprintStatus.cancelada) {
    return false;
  }
  final hoje = DateTime.now();
  final dataAtual = DateTime(hoje.year, hoje.month, hoje.day);
  final fim = DateTime(
    sprint.dataFim.year,
    sprint.dataFim.month,
    sprint.dataFim.day,
  );
  return fim.isBefore(dataAtual);
}
