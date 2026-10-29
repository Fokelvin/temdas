import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import '../app/nova_aba.dart';
import 'formatters/demanda_identificacao.dart';
import '../view_model/demanda_detalhe_view_model.dart';
import 'widgets/app_drawer.dart';
import 'widgets/tempo_comparacao.dart';
import 'widgets/demanda_painel_acoes.dart';
import 'widgets/demanda_texto_dialog.dart';
import 'widgets/registro_tempo_observacoes.dart';

class DemandaDetalhePage extends StatelessWidget {
  const DemandaDetalhePage({
    super.key,
    required this.demandaId,
    this.viewModel,
  });

  final int demandaId;
  final DemandaDetalheViewModel? viewModel;

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Detalhes da demanda',
    route: AppRoutes.demandaDetalhe,
    body: _DemandaDetalheConteudo(
      demandaId: demandaId,
      viewModel: viewModel,
      onVoltar: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          navigator.pushReplacementNamed(AppRoutes.demandas);
        }
      },
      onAbrirDemanda: (id) {
        if (id == null) return;
        Navigator.pushNamed(context, AppRoutes.demandaDetalhe, arguments: id);
      },
    ),
  );
}

Future<void> mostrarDetalhesDemandaDialog(
  BuildContext context,
  int demandaId, {
  DemandaDetalheViewModel? viewModel,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Fechar detalhes da demanda',
  pageBuilder: (dialogContext, _, _) {
    final size = MediaQuery.sizeOf(dialogContext);
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: size.width < 840 ? size.width : size.width * .5,
        height: size.height,
        child: Material(
          key: const ValueKey('demanda-detalhe-dialog'),
          color: Theme.of(dialogContext).colorScheme.surface,
          elevation: 12,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Demanda #$demandaId',
                          style: Theme.of(dialogContext).textTheme.titleLarge,
                        ),
                      ),
                      if (kIsWeb)
                        IconButton(
                          key: const ValueKey('abrir-demanda-nova-aba'),
                          tooltip: 'Abrir em nova aba',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => abrirRotaEmNovaAba(
                            AppRoutes.detalheDaDemanda(demandaId),
                          ),
                        ),
                      IconButton(
                        tooltip: 'Fechar detalhes',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _DemandaDetalheConteudo(
                    demandaId: demandaId,
                    viewModel: viewModel,
                    painel: true,
                    onVoltar: () => Navigator.pop(dialogContext),
                    onAbrirDemanda: (id) {
                      if (id != null) {
                        mostrarDetalhesDemandaDialog(dialogContext, id);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);

// A página e o popup compartilham carregamento e apresentação dos detalhes.
class _DemandaDetalheConteudo extends StatefulWidget {
  const _DemandaDetalheConteudo({
    required this.demandaId,
    required this.onVoltar,
    required this.onAbrirDemanda,
    this.viewModel,
    this.painel = false,
  });

  final bool painel;
  final int demandaId;
  final VoidCallback onVoltar;
  final ValueChanged<int?> onAbrirDemanda;
  final DemandaDetalheViewModel? viewModel;

  @override
  State<_DemandaDetalheConteudo> createState() =>
      _DemandaDetalheConteudoState();
}

class _DemandaDetalheConteudoState extends State<_DemandaDetalheConteudo> {
  late final DemandaDetalheViewModel _viewModel;
  late final bool _possuiViewModel;
  int _aba = 0;
  bool _anotacoesIniciadas = false;

  @override
  void initState() {
    super.initState();
    _possuiViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? DemandaDetalheViewModel();
    _viewModel.carregar(widget.demandaId);
  }

  @override
  void didUpdateWidget(covariant _DemandaDetalheConteudo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.demandaId != oldWidget.demandaId) {
      _aba = 0;
      _anotacoesIniciadas = false;
      _viewModel.carregar(widget.demandaId);
    }
  }

  @override
  void dispose() {
    if (_possuiViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => _conteudo(),
  );

  Widget _conteudo() {
    if (_viewModel.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.erro case final erro?) {
      return _EstadoMensagem(
        icon: Icons.cloud_off_outlined,
        titulo: 'Não foi possível carregar a demanda',
        mensagem: erro,
        acao: FilledButton.icon(
          onPressed: () => _viewModel.carregar(widget.demandaId),
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      );
    }

    final demanda = _viewModel.demanda;
    if (demanda == null) {
      return _EstadoMensagem(
        icon: Icons.search_off_outlined,
        titulo: 'Demanda não encontrada',
        mensagem: 'A demanda #${widget.demandaId} não foi encontrada.',
        acao: OutlinedButton.icon(
          onPressed: widget.onVoltar,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar'),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      initialIndex: _aba,
      child: Column(
        children: [
          TabBar(
            isScrollable: MediaQuery.textScalerOf(context).scale(1) > 1.3,
            onTap: (aba) {
              _aba = aba;
              if (aba == 1 && !_anotacoesIniciadas) {
                _anotacoesIniciadas = true;
                _viewModel.carregarAnotacoes(widget.demandaId);
              }
            },
            tabs: const [
              Tab(text: 'Visão geral'),
              Tab(text: 'Anotações'),
              Tab(text: 'Horas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [_visaoGeral(demanda), _anotacoes(demanda), _horas()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _visaoGeral(backend.Demanda demanda) => SelectionArea(
    child: ListView(
      key: const PageStorageKey('demanda-visao-geral'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (!widget.painel)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onVoltar,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
            ),
          ),
        _Cabecalho(demanda: demanda),
        if (_viewModel.acoesViewModel case final vm?)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: DemandaPainelAcoes(
              demanda: demanda,
              viewModel: vm,
              onAtualizar: () => _viewModel.carregar(widget.demandaId),
            ),
          ),
        _Secao(
          titulo: 'Estimado x executado',
          child: TempoComparacao(
            estimadoMinutos: demanda.tempoEstimadoMinutos,
            executadoMinutos: _viewModel.tempoExecutadoMinutos,
          ),
        ),
        const SizedBox(height: 12),
        _Secao(
          titulo: 'Sprint',
          child: _viewModel.carregandoSprint
              ? const LinearProgressIndicator()
              : _viewModel.erroSprint != null
              ? TextButton(
                  onPressed: () => _viewModel.carregarSprint(widget.demandaId),
                  child: const Text('Tentar consultar Sprint novamente'),
                )
              : TextButton.icon(
                  icon: const Icon(Icons.directions_run),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.sprint),
                  label: Text(_viewModel.sprint?.nome ?? 'Sem Sprint'),
                ),
        ),
        const SizedBox(height: 12),
        _Secao(
          titulo: 'Informações',
          child: _Informacoes(
            demanda: demanda,
            executadoMinutos: _viewModel.tempoExecutadoMinutos,
          ),
        ),
        const SizedBox(height: 12),
        _Secao(
          titulo: 'Demanda mãe',
          child: _DemandaMae(
            demanda: demanda,
            demandaMae: _viewModel.demandaMae,
            onAbrir: widget.onAbrirDemanda,
          ),
        ),
        const SizedBox(height: 12),
        _Secao(
          titulo: 'Demandas filhas (${_viewModel.filhas.length})',
          child: _DemandasFilhas(
            demandas: _viewModel.filhas,
            onAbrir: widget.onAbrirDemanda,
          ),
        ),
      ],
    ),
  );

  Widget _anotacoes(backend.Demanda demanda) => ListView(
    key: PageStorageKey('demanda-${widget.demandaId}-anotacoes'),
    padding: const EdgeInsets.all(16),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: _viewModel.salvando ? null : () => _editarAnotacao(),
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('Nova anotação'),
        ),
      ),
      if (_viewModel.carregandoAnotacoes) const LinearProgressIndicator(),
      if (_viewModel.erroAnotacoes case final erro?) ...[
        Text(erro),
        TextButton(
          onPressed: () => _viewModel.carregarAnotacoes(widget.demandaId),
          child: const Text('Tentar novamente'),
        ),
      ] else if (!_viewModel.carregandoAnotacoes &&
          _viewModel.anotacoes.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhuma anotação nesta demanda.'),
        ),
      for (final anotacao in _viewModel.anotacoes)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Autor #${anotacao.autorId} · ${_formatarDataHora(anotacao.criadoEm)}',
                ),
                if (anotacao.editadoEm != null)
                  Text('Editada em ${_formatarDataHora(anotacao.editadoEm!)}'),
                const SizedBox(height: 8),
                SelectableText(anotacao.conteudo),
                if (anotacao.autorId == demanda.usuarioId)
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: _viewModel.salvando
                            ? null
                            : () => _editarAnotacao(anotacao),
                        child: const Text('Editar anotação'),
                      ),
                      TextButton(
                        onPressed: _viewModel.salvando
                            ? null
                            : () => _excluirAnotacao(anotacao),
                        child: const Text('Excluir anotação'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
    ],
  );

  Future<void> _editarAnotacao([backend.AnotacaoDemanda? anotacao]) =>
      mostrarTextoDemandaDialog(
        context,
        titulo: anotacao == null ? 'Nova anotação' : 'Editar anotação',
        texto: anotacao?.conteudo,
        obrigatorio: true,
        salvar: (texto) => _viewModel.salvarAnotacao(
          widget.demandaId,
          texto,
          id: anotacao?.id,
        ),
      );

  Future<void> _excluirAnotacao(backend.AnotacaoDemanda anotacao) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir anotação?'),
        content: const Text('A anotação será removida do histórico visível.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final sucesso = await _viewModel.excluirAnotacao(
      widget.demandaId,
      anotacao.id!,
    );
    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir. Tente novamente.'),
        ),
      );
    }
  }

  Widget _horas() => ListView(
    key: const PageStorageKey('demanda-horas'),
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Total: ${_formatarDuracao(_viewModel.registros.fold<int>(0, (t, r) => t + r.duracaoMinutos))}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Correções de horários e exclusões estão disponíveis na tela Log Time.',
        ),
      ),
      _HistoricoTempo(
        registros: _viewModel.registros,
        editarObservacao: (registro) => mostrarTextoDemandaDialog(
          context,
          titulo: 'Editar observação',
          texto: registro.observacao,
          complemento: RegistroTempoObservacoes(
            originais: registro.observacoesOriginais,
            mostrarTextos: false,
          ),
          salvar: (texto) => texto == (registro.observacao ?? '')
              ? Future.value(true)
              : _viewModel.salvarObservacao(registro.id!, texto),
        ),
      ),
    ],
  );
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.demanda});

  final backend.Demanda demanda;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatarIdentificacaoDemanda(demanda),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Chip(label: Text(_statusLabel(demanda.status))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _textoOuFallback(demanda.descricao, 'Descrição não informada.'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    ),
  );
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _Informacoes extends StatelessWidget {
  const _Informacoes({required this.demanda, required this.executadoMinutos});

  final backend.Demanda demanda;
  final int executadoMinutos;

  @override
  Widget build(BuildContext context) {
    final itens = <({String label, String valor})>[
      (label: 'ID', valor: '#${demanda.id ?? '—'}'),
      (label: 'Status', valor: _statusLabel(demanda.status)),
      (label: 'Prioridade', valor: _prioridadeLabel(demanda.prioridade)),
      (
        label: 'Tempo estimado',
        valor: _formatarDuracao(demanda.tempoEstimadoMinutos),
      ),
      (label: 'Tempo executado', valor: _formatarDuracao(executadoMinutos)),
      (label: 'Criada em', valor: _formatarDataHora(demanda.criadoEm)),
      (label: 'Atualizada em', valor: _formatarDataHora(demanda.atualizadoEm)),
      (
        label: 'Concluída em',
        valor: demanda.concluidoEm == null
            ? 'Não concluída'
            : _formatarDataHora(demanda.concluidoEm!),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth >= 680
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 18,
          children: itens
              .map(
                (item) => SizedBox(
                  width: largura,
                  child: _CampoInformacao(label: item.label, valor: item.valor),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CampoInformacao extends StatelessWidget {
  const _CampoInformacao({required this.label, required this.valor});

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 3),
      Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

class _DemandaMae extends StatelessWidget {
  const _DemandaMae({
    required this.demanda,
    required this.demandaMae,
    required this.onAbrir,
  });

  final backend.Demanda demanda;
  final backend.Demanda? demandaMae;
  final ValueChanged<int?> onAbrir;

  @override
  Widget build(BuildContext context) {
    final demandaPaiId = demanda.demandaPaiId;
    if (demandaPaiId == null) {
      return const Text('Esta é uma demanda raiz.');
    }
    if (demandaMae == null) {
      return Text('A demanda mãe #$demandaPaiId não foi encontrada.');
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.account_tree_outlined),
      title: Text(
        formatarIdentificacaoDemanda(demandaMae!),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '#${demandaMae!.id} · ${_statusLabel(demandaMae!.status)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onAbrir(demandaMae!.id),
    );
  }
}

class _DemandasFilhas extends StatelessWidget {
  const _DemandasFilhas({required this.demandas, required this.onAbrir});

  final List<backend.Demanda> demandas;
  final ValueChanged<int?> onAbrir;

  @override
  Widget build(BuildContext context) {
    if (demandas.isEmpty) {
      return const Text('Nenhuma demanda filha cadastrada.');
    }

    return Column(
      children: [
        for (var index = 0; index < demandas.length; index++) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.subdirectory_arrow_right),
            title: Text(
              formatarIdentificacaoDemanda(demandas[index]),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${_statusLabel(demandas[index].status)} · '
              '${_formatarDuracao(demandas[index].tempoExecutadoMinutos)} executado',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onAbrir(demandas[index].id),
          ),
          if (index < demandas.length - 1) const Divider(),
        ],
      ],
    );
  }
}

class _HistoricoTempo extends StatelessWidget {
  const _HistoricoTempo({
    required this.registros,
    required this.editarObservacao,
  });

  final ValueChanged<backend.RegistroTempo> editarObservacao;

  final List<backend.RegistroTempo> registros;

  @override
  Widget build(BuildContext context) {
    if (registros.isEmpty) {
      return const Text('Nenhum tempo lançado nesta demanda.');
    }

    return Column(
      children: [
        for (var index = 0; index < registros.length; index++) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(_formatarDataHora(registros[index].inicioEm)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Até ${_formatarDataHora(registros[index].inicioEm.add(Duration(minutes: registros[index].duracaoMinutos)))}',
                ),
                Text(
                  'Lançamento #${registros[index].id ?? '—'} · registrado em ${_formatarDataHora(registros[index].criadoEm)}',
                ),
                RegistroTempoObservacoes(
                  texto: registros[index].observacao,
                  originais: registros[index].observacoesOriginais,
                ),
                TextButton(
                  onPressed: () => editarObservacao(registros[index]),
                  child: const Text('Editar observação'),
                ),
              ],
            ),
            trailing: Text(
              _formatarDuracao(registros[index].duracaoMinutos),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (index < registros.length - 1) const Divider(),
        ],
      ],
    );
  }
}

class _EstadoMensagem extends StatelessWidget {
  const _EstadoMensagem({
    required this.icon,
    required this.titulo,
    required this.mensagem,
    required this.acao,
  });

  final IconData icon;
  final String titulo;
  final String mensagem;
  final Widget acao;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(mensagem, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              acao,
            ],
          ),
        ),
      ),
    ),
  );
}

String _textoOuFallback(String? valor, String fallback) {
  final texto = valor?.trim();
  return texto == null || texto.isEmpty ? fallback : texto;
}

String _statusLabel(backend.DemandaStatus status) => switch (status) {
  backend.DemandaStatus.aberta => 'Aberta',
  backend.DemandaStatus.emAndamento => 'Em andamento',
  backend.DemandaStatus.pausada => 'Pausada',
  backend.DemandaStatus.concluida => 'Concluída',
  backend.DemandaStatus.cancelada => 'Cancelada',
};

String _prioridadeLabel(backend.Prioridade prioridade) => switch (prioridade) {
  backend.Prioridade.baixa => 'Baixa',
  backend.Prioridade.media => 'Média',
  backend.Prioridade.alta => 'Alta',
  backend.Prioridade.urgente => 'Urgente',
};

String _formatarDuracao(int minutos) {
  final horas = minutos ~/ 60;
  final restante = minutos.remainder(60);
  if (horas == 0) return '$restante min';
  if (restante == 0) return '${horas}h';
  return '${horas}h ${restante}min';
}

String _formatarDataHora(DateTime valor) {
  final local = valor.toLocal();
  return '${_doisDigitos(local.day)}/${_doisDigitos(local.month)}/${local.year} '
      'às ${_doisDigitos(local.hour)}:${_doisDigitos(local.minute)}';
}

String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');
