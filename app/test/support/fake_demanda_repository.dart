import 'dart:async';

import 'package:temdas/data/repositories/demanda_repository.dart';
import 'package:temdas/data/repositories/registro_tempo_repository.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

class CriacaoDemandaCapturada {
  const CriacaoDemandaCapturada({
    required this.titulo,
    required this.tempoEstimadoMinutos,
    required this.demandaPaiId,
    required this.descricao,
    required this.prioridade,
  });

  final String titulo;
  final int tempoEstimadoMinutos;
  final int? demandaPaiId;
  final String? descricao;
  final backend.Prioridade? prioridade;
}

class AtualizacaoDemandaCapturada {
  const AtualizacaoDemandaCapturada({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.status,
    this.motivoCancelamento,
    required this.prioridade,
    required this.sprint,
    required this.tempoEstimadoMinutos,
    required this.observacoes,
  });

  final int id;
  final String titulo;
  final String? descricao;
  final backend.DemandaStatus status;
  final String? motivoCancelamento;
  final backend.Prioridade prioridade;
  final String? sprint;
  final int tempoEstimadoMinutos;
  final String? observacoes;
}

class MovimentacaoDemandaCapturada {
  const MovimentacaoDemandaCapturada({
    required this.demandaId,
    required this.statusDestino,
    required this.posicaoDestino,
  });

  final int demandaId;
  final backend.DemandaStatus statusDestino;
  final int posicaoDestino;
}

class FakeDemandaRepository implements DemandaRepository {
  FakeDemandaRepository({List<backend.Demanda>? demandas})
    : _demandas = List.of(demandas ?? const []);

  final List<backend.Demanda> _demandas;
  int chamadasCriar = 0;
  int chamadasListar = 0;
  int chamadasBuscar = 0;
  final idsBuscados = <int>[];
  Completer<backend.Demanda?>? respostaBuscarPendente;
  int chamadasAtualizar = 0;
  int chamadasAlterarStatus = 0;
  int chamadasMover = 0;
  int chamadasConcluirEmCascata = 0;
  int chamadasCancelarEmCascata = 0;
  int chamadasExcluir = 0;
  int chamadasExcluirArvore = 0;
  CriacaoDemandaCapturada? ultimaCriacao;
  AtualizacaoDemandaCapturada? ultimaAtualizacao;
  MovimentacaoDemandaCapturada? ultimaMovimentacao;
  ({int id, backend.DemandaStatus status, String? motivoCancelamento})?
  ultimaAlteracaoStatus;
  int? ultimoIdConclusaoEmCascata;
  ({int id, String motivo})? ultimoCancelamentoEmCascata;
  int? ultimoIdExcluido;
  int? ultimoIdArvoreExcluida;
  bool resultadoExclusao = true;
  bool resultadoExclusaoArvore = true;
  Object? erroAoListar;
  Completer<backend.Demanda>? respostaCriarPendente;
  Completer<backend.Demanda>? respostaAtualizarPendente;
  Completer<backend.Demanda>? respostaAlterarStatusPendente;
  Completer<backend.Demanda>? respostaMoverPendente;
  Completer<backend.Demanda>? respostaConcluirEmCascataPendente;
  Completer<backend.Demanda>? respostaCancelarEmCascataPendente;
  Completer<bool>? respostaExcluirPendente;
  Completer<bool>? respostaExcluirArvorePendente;
  final List<Completer<List<backend.Demanda>>> respostasListarPendentes = [];

  @override
  Future<backend.Demanda> criarDemanda({
    required String titulo,
    required int tempoEstimadoMinutos,
    int? demandaPaiId,
    String? descricao,
    backend.Prioridade? prioridade,
    String? sprint,
    String? observacoes,
  }) async {
    chamadasCriar++;
    ultimaCriacao = CriacaoDemandaCapturada(
      titulo: titulo,
      tempoEstimadoMinutos: tempoEstimadoMinutos,
      demandaPaiId: demandaPaiId,
      descricao: descricao,
      prioridade: prioridade,
    );
    if (respostaCriarPendente case final resposta?) return resposta.future;
    final agora = DateTime.utc(2026, 9, 9, 12);
    final maiorId = _demandas.fold<int>(
      0,
      (maior, demanda) => (demanda.id ?? 0) > maior ? demanda.id! : maior,
    );
    final demanda = backend.Demanda(
      id: maiorId + 1,
      demandaPaiId: demandaPaiId,
      titulo: titulo,
      descricao: descricao,
      status: backend.DemandaStatus.aberta,
      prioridade: prioridade ?? backend.Prioridade.media,
      sprint: sprint,
      tempoEstimadoMinutos: tempoEstimadoMinutos,
      tempoExecutadoMinutos: 0,
      observacoes: observacoes,
      criadoEm: agora,
      atualizadoEm: agora,
    );
    _demandas.add(demanda);
    return demanda;
  }

  @override
  Future<List<backend.Demanda>> listarDemandas() {
    chamadasListar++;
    if (erroAoListar case final erro?) return Future.error(erro);
    if (respostasListarPendentes.isNotEmpty) {
      return respostasListarPendentes.removeAt(0).future;
    }
    return Future.value(List.of(_demandas));
  }

  @override
  Future<backend.Demanda?> buscarDemandaPorId(int id) async {
    chamadasBuscar++;
    idsBuscados.add(id);
    if (respostaBuscarPendente case final resposta?) return resposta.future;
    for (final demanda in _demandas) {
      if (demanda.id == id) return demanda;
    }
    return null;
  }

  @override
  Future<backend.Demanda> atualizarDemanda({
    required int id,
    required String titulo,
    String? descricao,
    required backend.DemandaStatus status,
    String? motivoCancelamento,
    required backend.Prioridade prioridade,
    String? sprint,
    required int tempoEstimadoMinutos,
    String? observacoes,
  }) async {
    chamadasAtualizar++;
    ultimaAtualizacao = AtualizacaoDemandaCapturada(
      id: id,
      titulo: titulo,
      descricao: descricao,
      status: status,
      motivoCancelamento: motivoCancelamento,
      prioridade: prioridade,
      sprint: sprint,
      tempoEstimadoMinutos: tempoEstimadoMinutos,
      observacoes: observacoes,
    );
    if (respostaAtualizarPendente case final resposta?) return resposta.future;

    final index = _demandas.indexWhere((demanda) => demanda.id == id);
    if (index == -1) throw StateError('Demanda não encontrada.');

    final atual = _demandas[index];
    final atualizada = atual.copyWith(
      titulo: titulo,
      descricao: descricao,
      status: status,
      motivoCancelamento: motivoCancelamento ?? atual.motivoCancelamento,
      prioridade: prioridade,
      sprint: sprint,
      tempoEstimadoMinutos: tempoEstimadoMinutos,
      observacoes: observacoes,
      atualizadoEm: DateTime.utc(2026, 9, 9, 13),
      concluidoEm: status == backend.DemandaStatus.concluida
          ? atual.concluidoEm ?? DateTime.utc(2026, 9, 9, 13)
          : null,
    );
    _demandas[index] = atualizada;
    return atualizada;
  }

  @override
  Future<backend.Demanda> alterarStatusDemanda({
    required int id,
    required backend.DemandaStatus status,
    String? motivoCancelamento,
  }) {
    chamadasAlterarStatus++;
    ultimaAlteracaoStatus = (
      id: id,
      status: status,
      motivoCancelamento: motivoCancelamento,
    );
    return _responderTransicao(respostaAlterarStatusPendente);
  }

  @override
  Future<backend.Demanda> moverDemanda({
    required int demandaId,
    required backend.DemandaStatus statusDestino,
    required int posicaoDestino,
  }) async {
    chamadasMover++;
    ultimaMovimentacao = MovimentacaoDemandaCapturada(
      demandaId: demandaId,
      statusDestino: statusDestino,
      posicaoDestino: posicaoDestino,
    );
    final resposta = respostaMoverPendente;
    if (resposta == null) {
      throw StateError('Configure a resposta de movimentação no fake.');
    }
    final atualizada = await resposta.future;
    final index = _demandas.indexWhere((item) => item.id == atualizada.id);
    if (index != -1) _demandas[index] = atualizada;
    return atualizada;
  }

  @override
  Future<backend.Demanda> concluirDemanda(int id) =>
      alterarStatusDemanda(id: id, status: backend.DemandaStatus.concluida);

  @override
  Future<backend.Demanda> concluirDemandaEmCascata(int id) {
    chamadasConcluirEmCascata++;
    ultimoIdConclusaoEmCascata = id;
    return _responderTransicao(respostaConcluirEmCascataPendente);
  }

  @override
  Future<backend.Demanda> cancelarDemandaEmCascata(int id, String motivo) {
    chamadasCancelarEmCascata++;
    ultimoCancelamentoEmCascata = (id: id, motivo: motivo);
    return _responderTransicao(respostaCancelarEmCascataPendente);
  }

  Future<backend.Demanda> _responderTransicao(
    Completer<backend.Demanda>? resposta,
  ) async {
    if (resposta == null) {
      throw StateError('Configure a resposta de status do backend no fake.');
    }
    // Apenas aplica a resposta configurada; não simula validações ou cascatas.
    final atualizada = await resposta.future;
    final index = _demandas.indexWhere((item) => item.id == atualizada.id);
    if (index != -1) _demandas[index] = atualizada;
    return atualizada;
  }

  @override
  Future<bool> excluirDemanda(int id) async {
    chamadasExcluir++;
    ultimoIdExcluido = id;
    if (respostaExcluirPendente case final resposta?) return resposta.future;
    if (!resultadoExclusao) return false;

    final quantidadeAnterior = _demandas.length;
    _demandas.removeWhere((demanda) => demanda.id == id);
    return _demandas.length < quantidadeAnterior;
  }

  @override
  Future<bool> excluirArvoreDemanda(int id) async {
    chamadasExcluirArvore++;
    ultimoIdArvoreExcluida = id;
    if (respostaExcluirArvorePendente case final resposta?) {
      return resposta.future;
    }
    if (!resultadoExclusaoArvore) return false;

    final idsExcluidos = <int>{id};
    var encontrouNovos = true;
    while (encontrouNovos) {
      encontrouNovos = false;
      for (final demanda in _demandas) {
        final demandaId = demanda.id;
        if (demandaId != null &&
            idsExcluidos.contains(demanda.demandaPaiId) &&
            idsExcluidos.add(demandaId)) {
          encontrouNovos = true;
        }
      }
    }

    final quantidadeAnterior = _demandas.length;
    _demandas.removeWhere(
      (demanda) => demanda.id != null && idsExcluidos.contains(demanda.id),
    );
    return _demandas.length < quantidadeAnterior;
  }
}

class FakeRegistroTempoRepository implements RegistroTempoRepository {
  FakeRegistroTempoRepository({
    List<backend.RegistroTempo>? registros,
    this.demandaRepository,
  }) : _registros = List.of(registros ?? const []);

  final List<backend.RegistroTempo> _registros;
  final FakeDemandaRepository? demandaRepository;
  int chamadasRegistrar = 0;
  int chamadasListarPeriodo = 0;
  int chamadasListarDemanda = 0;
  int chamadasExcluir = 0;
  int? ultimaDemandaId;
  DateTime? ultimoInicioEm;
  int? ultimaDuracaoMinutos;
  Completer<backend.RegistroTempo>? respostaRegistrarPendente;

  @override
  Future<backend.RegistroTempo> editarRegistroTempo({
    required int id,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) async {
    throw UnsupportedError('Edição não configurada neste fake.');
  }

  @override
  Future<backend.RegistroTempo> registrarTempo({
    required int demandaId,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) async {
    chamadasRegistrar++;
    ultimaDemandaId = demandaId;
    ultimoInicioEm = inicioEm;
    ultimaDuracaoMinutos = duracaoMinutos;
    if (respostaRegistrarPendente case final resposta?) return resposta.future;

    final maiorId = _registros.fold<int>(
      0,
      (maior, registro) => (registro.id ?? 0) > maior ? registro.id! : maior,
    );
    final registro = backend.RegistroTempo(
      id: maiorId + 1,
      demandaId: demandaId,
      inicioEm: inicioEm,
      duracaoMinutos: duracaoMinutos,
      criadoEm: DateTime.utc(2026, 9, 9, 14),
    );
    _registros.add(registro);
    _somarTempoExecutado(demandaId, duracaoMinutos);
    return registro;
  }

  @override
  Future<List<backend.RegistroTempo>> listarPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    chamadasListarPeriodo++;
    return _registros
        .where(
          (registro) =>
              !registro.inicioEm.isBefore(inicio) &&
              registro.inicioEm.isBefore(fim),
        )
        .toList();
  }

  @override
  Future<List<backend.RegistroTempo>> listarDaDemanda(int id) async {
    chamadasListarDemanda++;
    return _registros.where((registro) => registro.demandaId == id).toList();
  }

  @override
  Future<bool> excluirRegistroTempo(int id) async {
    chamadasExcluir++;
    final index = _registros.indexWhere((registro) => registro.id == id);
    if (index == -1) return false;
    final removido = _registros.removeAt(index);
    _somarTempoExecutado(removido.demandaId, -removido.duracaoMinutos);
    return true;
  }

  void _somarTempoExecutado(int demandaId, int minutos) {
    final repository = demandaRepository;
    if (repository == null) return;
    final index = repository._demandas.indexWhere(
      (demanda) => demanda.id == demandaId,
    );
    if (index == -1) return;
    final demanda = repository._demandas[index];
    repository._demandas[index] = demanda.copyWith(
      tempoExecutadoMinutos: (demanda.tempoExecutadoMinutos + minutos)
          .clamp(0, 1 << 31)
          .toInt(),
    );
  }
}

backend.Demanda demandaFixture({
  int? id = 1,
  int? demandaPaiId,
  String titulo = 'Demanda inicial',
  String? descricao = 'Descrição inicial',
  backend.DemandaStatus status = backend.DemandaStatus.aberta,
  backend.Prioridade prioridade = backend.Prioridade.media,
  String? sprint = 'Sprint preservada',
  int tempoEstimadoMinutos = 60,
  int tempoExecutadoMinutos = 30,
  String? observacoes = 'Observação preservada',
}) {
  return backend.Demanda(
    id: id,
    demandaPaiId: demandaPaiId,
    titulo: titulo,
    descricao: descricao,
    status: status,
    prioridade: prioridade,
    sprint: sprint,
    tempoEstimadoMinutos: tempoEstimadoMinutos,
    tempoExecutadoMinutos: tempoExecutadoMinutos,
    observacoes: observacoes,
    criadoEm: DateTime.utc(2026, 9, 1),
    atualizadoEm: DateTime.utc(2026, 9, 1),
  );
}
