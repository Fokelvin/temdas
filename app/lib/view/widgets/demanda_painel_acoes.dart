import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;
import '../../view_model/demandas_view_model.dart';
import '../formatters/demanda_identificacao.dart';
import 'demanda_card.dart';
import 'demanda_dialog.dart';
import 'demanda_status_dialog.dart';
import 'densidade_demanda.dart';
import 'log_time_dialog.dart';

/// Reutiliza controles, validações e diálogos existentes também na URL direta.
class DemandaPainelAcoes extends StatefulWidget {
  const DemandaPainelAcoes({
    super.key,
    required this.demanda,
    required this.viewModel,
    required this.onAtualizar,
  });
  final backend.Demanda demanda;
  final DemandasViewModel viewModel;
  final Future<void> Function() onAtualizar;
  @override
  State<DemandaPainelAcoes> createState() => _DemandaPainelAcoesState();
}

class _DemandaPainelAcoesState extends State<DemandaPainelAcoes> {
  bool ocupado = false;
  DemandasViewModel get vm => widget.viewModel;
  backend.Demanda get demanda => widget.demanda;

  Future<void> executar(Future<void> Function() operacao) async {
    if (ocupado || vm.enviando || vm.carregando) return;
    setState(() => ocupado = true);
    try {
      await operacao();
      if (!mounted) return;
      final erro = vm.erroDaDemanda(demanda.id) ?? vm.erro;
      if (erro != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(erro)));
      }
      await widget.onAtualizar();
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> status(backend.DemandaStatus destino) async {
    if (destino == backend.DemandaStatus.cancelada) {
      await mostrarCancelamentoDemandaDialog(
        context,
        demanda: demanda,
        viewModel: vm,
      );
    } else if (destino == backend.DemandaStatus.concluida) {
      final sucesso = await vm.concluirDemanda(demanda);
      if (!sucesso &&
          mounted &&
          vm.erroTransicaoDaDemanda(demanda.id)?.podeConcluirEmCascata ==
              true) {
        await mostrarConclusaoEmCascataDialog(
          context,
          demanda: demanda,
          viewModel: vm,
        );
      }
    } else {
      await vm.alterarStatusDemanda(demanda: demanda, status: destino);
    }
  }

  Future<void> excluir() async {
    final descendentes = vm.descendentesDe(demanda).length;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir demanda?'),
        content: Text(
          'Excluir permanentemente a demanda, $descendentes descendentes e todos os registros vinculados? Esta ação não pode ser desfeita.',
        ),
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
    if (confirmado == true) {
      if (descendentes > 0) {
        await vm.excluirArvoreDemanda(demanda);
      } else {
        await vm.excluirDemanda(demanda);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) => DemandaCard(
      demanda: demanda,
      tempoExecutadoTotalMinutos: demanda.tempoExecutadoMinutos,
      apenasAcoes: true,
      densidade: DensidadeDemanda.compacta,
      acoesHabilitadas: !ocupado && !vm.enviando && !vm.carregando,
      onEditar: () => executar(() async {
        await showDialog<bool>(
          context: context,
          builder: (_) => EditarDemandaDialog(
            demanda: demanda,
            onSalvar: (dados) => vm.atualizarDemanda(
              demanda: demanda,
              titulo: dados.titulo,
              descricao: dados.descricao,
              tempoEstimadoHoras: dados.tempoEstimadoHoras,
              status: dados.status,
              prioridade: dados.prioridade,
            ),
          ),
        );
      }),
      onExcluir: () => executar(excluir),
      onAlterarStatus: (destino) => executar(() => status(destino)),
      onConcluir: () => executar(() => status(backend.DemandaStatus.concluida)),
      onReabrir: () => executar(() async {
        await mostrarReaberturaDemandaDialog(
          context,
          demanda: demanda,
          viewModel: vm,
        );
      }),
      onCriarFilha: () => executar(() async {
        await showDialog<bool>(
          context: context,
          builder: (_) => CriarDemandaFilhaDialog(
            demandaMae: demanda,
            onSalvar: (dados) => vm.criarDemanda(
              titulo: dados.titulo,
              descricao: dados.descricao,
              tempoEstimadoHoras: dados.tempoEstimadoHoras,
              prioridade: dados.prioridade,
              demandaPaiId: demanda.id,
            ),
          ),
        );
      }),
      onLancarTempo: () => executar(() async {
        await showDialog<LogTimeFormData>(
          context: context,
          barrierDismissible: false,
          builder: (_) => LogTimeDialog(
            demandaId: demanda.id,
            demandaTitulo: formatarIdentificacaoDemanda(demanda),
            dataInicial: DateTime.now(),
            onSalvar: (dados) async {
              final sucesso = await vm.registrarTempo(
                demanda: demanda,
                inicioEm: dados.inicioEm,
                duracaoMinutos: dados.duracaoMinutos,
                observacao: dados.observacao,
              );
              return sucesso
                  ? null
                  : vm.erroDaDemanda(demanda.id) ??
                        'Não foi possível lançar tempo.';
            },
          ),
        );
      }),
    ),
  );
}
