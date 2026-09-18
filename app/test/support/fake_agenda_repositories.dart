import 'dart:async';
import 'dart:collection';

import 'package:temdas/data/repositories/demanda_repository.dart';
import 'package:temdas/data/repositories/registro_tempo_repository.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

class PeriodoConsultado {
  const PeriodoConsultado({required this.inicio, required this.fim});

  final DateTime inicio;
  final DateTime fim;
}

class RegistroCriadoCapturado {
  const RegistroCriadoCapturado({
    required this.demandaId,
    required this.inicioEm,
    required this.duracaoMinutos,
  });

  final int demandaId;
  final DateTime inicioEm;
  final int duracaoMinutos;
}

class RegistroEditadoCapturado {
  const RegistroEditadoCapturado({
    required this.id,
    required this.inicioEm,
    required this.duracaoMinutos,
  });

  final int id;
  final DateTime inicioEm;
  final int duracaoMinutos;
}

class FakeAgendaDemandaRepository extends DemandaRepository {
  FakeAgendaDemandaRepository({List<backend.Demanda>? demandas})
    : _demandas = List.of(demandas ?? const []),
      super();

  final List<backend.Demanda> _demandas;
  Object? erroAoListar;
  int chamadasListar = 0;

  @override
  Future<List<backend.Demanda>> listarDemandas() async {
    chamadasListar++;
    if (erroAoListar case final erro?) throw erro;
    return List.of(_demandas);
  }
}

class FakeRegistroTempoRepository extends RegistroTempoRepository {
  FakeRegistroTempoRepository({List<backend.RegistroTempo>? registros})
    : _registros = List.of(registros ?? const []),
      super();

  final List<backend.RegistroTempo> _registros;
  final Queue<Completer<List<backend.RegistroTempo>>> respostasPendentes =
      Queue();
  final List<PeriodoConsultado> periodosConsultados = [];
  final List<RegistroCriadoCapturado> registrosCriados = [];
  final List<RegistroEditadoCapturado> registrosEditados = [];
  final List<int> idsExcluidos = [];
  Object? erroAoListar;
  Object? erroAoRegistrar;
  Object? erroAoEditar;
  Completer<backend.RegistroTempo>? respostaEditarPendente;
  bool resultadoExclusao = true;
  int _proximoId = 100;

  List<backend.RegistroTempo> get registros => List.unmodifiable(_registros);

  @override
  Future<List<backend.RegistroTempo>> listarPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) {
    periodosConsultados.add(PeriodoConsultado(inicio: inicio, fim: fim));
    if (erroAoListar case final erro?) return Future.error(erro);
    if (respostasPendentes.isNotEmpty) {
      return respostasPendentes.removeFirst().future;
    }
    return Future.value(
      _registros
          .where(
            (registro) =>
                !registro.inicioEm.isBefore(inicio) &&
                registro.inicioEm.isBefore(fim),
          )
          .toList(),
    );
  }

  @override
  Future<backend.RegistroTempo> registrarTempo({
    required int demandaId,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) async {
    if (erroAoRegistrar case final erro?) throw erro;
    registrosCriados.add(
      RegistroCriadoCapturado(
        demandaId: demandaId,
        inicioEm: inicioEm,
        duracaoMinutos: duracaoMinutos,
      ),
    );
    final registro = backend.RegistroTempo(
      id: _proximoId++,
      demandaId: demandaId,
      inicioEm: inicioEm,
      duracaoMinutos: duracaoMinutos,
      criadoEm: DateTime.now().toUtc(),
    );
    _registros.add(registro);
    return registro;
  }

  @override
  Future<List<backend.RegistroTempo>> listarDaDemanda(int demandaId) async =>
      _registros.where((registro) => registro.demandaId == demandaId).toList();

  @override
  Future<backend.RegistroTempo> editarRegistroTempo({
    required int id,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) async {
    registrosEditados.add(
      RegistroEditadoCapturado(
        id: id,
        inicioEm: inicioEm,
        duracaoMinutos: duracaoMinutos,
      ),
    );
    if (erroAoEditar case final erro?) throw erro;

    final resposta = respostaEditarPendente;
    final atualizada = resposta == null
        ? _registros
              .firstWhere((registro) => registro.id == id)
              .copyWith(inicioEm: inicioEm, duracaoMinutos: duracaoMinutos)
        : await resposta.future;
    final index = _registros.indexWhere((registro) => registro.id == id);
    if (index == -1) throw StateError('Registro não encontrado.');
    _registros[index] = atualizada;
    return atualizada;
  }

  @override
  Future<bool> excluirRegistroTempo(int id) async {
    idsExcluidos.add(id);
    if (!resultadoExclusao) return false;
    final quantidade = _registros.length;
    _registros.removeWhere((registro) => registro.id == id);
    return quantidade != _registros.length;
  }
}

backend.Demanda demandaAgendaFixture({
  int id = 1,
  String titulo = 'Demanda da agenda',
  int tempoEstimadoMinutos = 120,
  int tempoExecutadoMinutos = 0,
}) {
  final agora = DateTime.utc(2026, 9, 9, 12);
  return backend.Demanda(
    id: id,
    titulo: titulo,
    status: backend.DemandaStatus.aberta,
    prioridade: backend.Prioridade.media,
    tempoEstimadoMinutos: tempoEstimadoMinutos,
    tempoExecutadoMinutos: tempoExecutadoMinutos,
    criadoEm: agora,
    atualizadoEm: agora,
  );
}

backend.RegistroTempo registroTempoFixture({
  int id = 1,
  int demandaId = 1,
  required DateTime inicioLocal,
  int duracaoMinutos = 30,
}) => backend.RegistroTempo(
  id: id,
  demandaId: demandaId,
  inicioEm: inicioLocal.toUtc(),
  duracaoMinutos: duracaoMinutos,
  criadoEm: DateTime.utc(2026, 9, 9, 12),
);
