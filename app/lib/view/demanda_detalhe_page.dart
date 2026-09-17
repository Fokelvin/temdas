import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import '../app/nova_aba.dart';
import 'formatters/demanda_identificacao.dart';
import '../view_model/demanda_detalhe_view_model.dart';
import 'widgets/app_drawer.dart';
import 'widgets/tempo_comparacao.dart';

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
  int demandaId,
) => showDialog<void>(
  context: context,
  builder: (dialogContext) => Dialog(
    child: SizedBox(
      width: 1040,
      height: MediaQuery.sizeOf(dialogContext).height * .85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                const Expanded(child: Text('Detalhes da demanda')),
                IconButton(
                  tooltip: 'Fechar detalhes',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('abrir-demanda-nova-aba'),
                  onPressed: () =>
                      abrirRotaEmNovaAba(AppRoutes.detalheDaDemanda(demandaId)),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir em nova aba'),
                ),
              ),
            ),
          Expanded(
            child: _DemandaDetalheConteudo(
              demandaId: demandaId,
              onVoltar: () => Navigator.pop(dialogContext),
              onAbrirDemanda: (id) {
                if (id == null) return;
                mostrarDetalhesDemandaDialog(dialogContext, id);
              },
            ),
          ),
        ],
      ),
    ),
  ),
);

// A página e o popup compartilham carregamento e apresentação dos detalhes.
class _DemandaDetalheConteudo extends StatefulWidget {
  const _DemandaDetalheConteudo({
    required this.demandaId,
    required this.onVoltar,
    required this.onAbrirDemanda,
    this.viewModel,
  });

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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onVoltar,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar'),
                ),
              ),
              const SizedBox(height: 4),
              _Cabecalho(demanda: demanda),
              const SizedBox(height: 16),
              _Secao(
                titulo: 'Estimado x executado',
                child: TempoComparacao(
                  estimadoMinutos: demanda.tempoEstimadoMinutos,
                  executadoMinutos: _viewModel.tempoExecutadoMinutos,
                ),
              ),
              const SizedBox(height: 16),
              _Secao(
                titulo: 'Informações',
                child: _Informacoes(
                  demanda: demanda,
                  executadoMinutos: _viewModel.tempoExecutadoMinutos,
                ),
              ),
              const SizedBox(height: 16),
              _Secao(
                titulo: 'Demanda mãe',
                child: _DemandaMae(
                  demanda: demanda,
                  demandaMae: _viewModel.demandaMae,
                  onAbrir: widget.onAbrirDemanda,
                ),
              ),
              const SizedBox(height: 16),
              _Secao(
                titulo: 'Demandas filhas (${_viewModel.filhas.length})',
                child: _DemandasFilhas(
                  demandas: _viewModel.filhas,
                  onAbrir: widget.onAbrirDemanda,
                ),
              ),
              const SizedBox(height: 16),
              _Secao(
                titulo: 'Histórico de tempo (${_viewModel.registros.length})',
                child: _HistoricoTempo(registros: _viewModel.registros),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        label: 'Sprint',
        valor: _textoOuFallback(demanda.sprint, 'Não informada'),
      ),
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
      (
        label: 'Observações',
        valor: _textoOuFallback(demanda.observacoes, 'Não informadas'),
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
  const _HistoricoTempo({required this.registros});

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
            subtitle: Text(
              'Lançamento #${registros[index].id ?? '—'} · registrado em '
              '${_formatarDataHora(registros[index].criadoEm)}',
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
