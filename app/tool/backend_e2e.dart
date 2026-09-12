import 'dart:io';

import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

Future<void> main() async {
  final client = backend.Client('http://localhost:8080/');
  final marcador = DateTime.now().toUtc().microsecondsSinceEpoch;
  int? raizId;
  int? folhaIdPendente;

  try {
    await _auditarTotaisExistentes(client);

    final raiz = await _criarDemanda(client, 'E2E raiz $marcador');
    raizId = _id(raiz);
    final filha = await _criarDemanda(
      client,
      'E2E filha $marcador',
      demandaPaiId: raizId,
    );
    final filhaId = _id(filha);
    final neta = await _criarDemanda(
      client,
      'E2E neta $marcador',
      demandaPaiId: filhaId,
    );
    final netaId = _id(neta);

    _verificar(filha.demandaPaiId == raizId, 'A filha não preservou a mãe.');
    _verificar(neta.demandaPaiId == filhaId, 'A neta não preservou a mãe.');

    final concluida = await client.demanda.atualizarDemanda(
      backend.DemandaUpdateRequest(
        id: filhaId,
        titulo: filha.titulo,
        descricao: filha.descricao,
        status: backend.DemandaStatus.concluida,
        prioridade: filha.prioridade,
        sprint: filha.sprint,
        tempoEstimadoMinutos: filha.tempoEstimadoMinutos,
        observacoes: filha.observacoes,
      ),
    );
    _verificar(concluida.concluidoEm != null, 'Conclusão sem concluidoEm.');

    final reaberta = await client.demanda.atualizarDemanda(
      backend.DemandaUpdateRequest(
        id: filhaId,
        titulo: concluida.titulo,
        descricao: concluida.descricao,
        status: backend.DemandaStatus.aberta,
        prioridade: concluida.prioridade,
        sprint: concluida.sprint,
        tempoEstimadoMinutos: concluida.tempoEstimadoMinutos,
        observacoes: concluida.observacoes,
      ),
    );
    _verificar(reaberta.concluidoEm == null, 'Reabertura manteve concluidoEm.');

    final inicioPeriodo = DateTime.utc(2026, 9, 8);
    final primeiroRegistro = await client.registroTempo.registrarTempo(
      backend.RegistroTempoCreateRequest(
        demandaId: filhaId,
        inicioEm: inicioPeriodo.add(const Duration(hours: 12)),
        duracaoMinutos: 45,
      ),
    );
    await client.registroTempo.registrarTempo(
      backend.RegistroTempoCreateRequest(
        demandaId: filhaId,
        inicioEm: inicioPeriodo.add(const Duration(days: 1, hours: 15)),
        duracaoMinutos: 30,
      ),
    );
    await client.registroTempo.registrarTempo(
      backend.RegistroTempoCreateRequest(
        demandaId: netaId,
        inicioEm: inicioPeriodo.add(const Duration(hours: 16)),
        duracaoMinutos: 20,
      ),
    );

    var filhaPersistida = await client.demanda.buscarDemandaPorId(filhaId);
    _verificar(
      filhaPersistida?.tempoExecutadoMinutos == 75,
      'Total executado da filha deveria ser 75 minutos.',
    );

    final registrosDoPeriodo = await client.registroTempo
        .listarRegistrosTempoPorPeriodo(
          inicioPeriodo,
          inicioPeriodo.add(const Duration(days: 2)),
        );
    _verificar(
      registrosDoPeriodo.where((item) => item.demandaId == filhaId).length == 2,
      'Consulta por período não retornou os dois registros da filha.',
    );

    final primeiroRegistroId = _idRegistro(primeiroRegistro);
    _verificar(
      await client.registroTempo.excluirRegistroTempo(primeiroRegistroId),
      'Exclusão do registro de tempo falhou.',
    );
    filhaPersistida = await client.demanda.buscarDemandaPorId(filhaId);
    _verificar(
      filhaPersistida?.tempoExecutadoMinutos == 30,
      'Total executado não foi recalculado após excluir um registro.',
    );

    var exclusaoFolhaBloqueada = false;
    try {
      await client.demanda.excluirDemanda(raizId);
    } on backend.ServerpodClientInternalServerError {
      exclusaoFolhaBloqueada = true;
    }
    _verificar(
      exclusaoFolhaBloqueada,
      'A exclusão comum deveria recusar uma demanda com descendentes.',
    );
    _verificar(
      await client.demanda.buscarDemandaPorId(raizId) != null,
      'A árvore foi alterada após a exclusão recusada.',
    );

    final folha = await _criarDemanda(client, 'E2E folha $marcador');
    final folhaId = _id(folha);
    folhaIdPendente = folhaId;
    _verificar(
      await client.demanda.excluirDemanda(folhaId),
      'Exclusão física de folha falhou.',
    );
    _verificar(
      await client.demanda.buscarDemandaPorId(folhaId) == null,
      'A folha continuou persistida após exclusão.',
    );
    folhaIdPendente = null;

    _verificar(
      await client.demanda.excluirArvoreDemanda(raizId),
      'Exclusão da árvore falhou.',
    );
    for (final id in [raiz.id!, filhaId, netaId]) {
      _verificar(
        await client.demanda.buscarDemandaPorId(id) == null,
        'A demanda $id permaneceu após a exclusão recursiva.',
      );
    }
    _verificar(
      (await client.registroTempo.listarRegistrosTempoDaDemanda(
        filhaId,
      )).isEmpty,
      'Registros da filha permaneceram após a exclusão recursiva.',
    );
    _verificar(
      (await client.registroTempo.listarRegistrosTempoDaDemanda(
        netaId,
      )).isEmpty,
      'Registros da neta permaneceram após a exclusão recursiva.',
    );
    raizId = null;

    stdout.writeln('E2E backend V1 concluído com sucesso.');
  } finally {
    if (raizId case final id?) {
      try {
        await client.demanda.excluirArvoreDemanda(id);
      } catch (_) {
        // A falha original deve continuar sendo a informação principal.
      }
    }
    if (folhaIdPendente case final id?) {
      try {
        await client.demanda.excluirDemanda(id);
      } catch (_) {
        // A falha original deve continuar sendo a informação principal.
      }
    }
    client.close();
  }
}

Future<void> _auditarTotaisExistentes(backend.Client client) async {
  final inconsistentes = <int>[];
  final demandas = await client.demanda.listarDemandas();

  for (final demanda in demandas) {
    final id = demanda.id;
    if (id == null) continue;
    final registros = await client.registroTempo.listarRegistrosTempoDaDemanda(
      id,
    );
    final total = registros.fold<int>(
      0,
      (soma, registro) => soma + registro.duracaoMinutos,
    );
    if (total != demanda.tempoExecutadoMinutos) {
      inconsistentes.add(id);
    }
  }

  _verificar(
    inconsistentes.isEmpty,
    'Totais executados divergentes dos registros nas demandas: '
    '${inconsistentes.join(', ')}.',
  );
}

Future<backend.Demanda> _criarDemanda(
  backend.Client client,
  String titulo, {
  int? demandaPaiId,
}) {
  return client.demanda.criarDemanda(
    backend.DemandaCreateRequest(
      demandaPaiId: demandaPaiId,
      titulo: titulo,
      tempoEstimadoMinutos: 60,
      prioridade: backend.Prioridade.media,
    ),
  );
}

int _id(backend.Demanda demanda) {
  return demanda.id ?? (throw StateError('Demanda criada sem ID.'));
}

int _idRegistro(backend.RegistroTempo registro) {
  return registro.id ?? (throw StateError('Registro criado sem ID.'));
}

void _verificar(bool condicao, String mensagem) {
  if (!condicao) throw StateError(mensagem);
}
