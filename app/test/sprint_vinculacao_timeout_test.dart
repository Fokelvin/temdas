import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/data/serverpod_client.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_sprint_repository.dart';

void main() {
  late FakeSprintRepository repository;
  late SprintViewModel model;
  List<backend.SprintDemanda> links(List<int> ids, {int sprint = 2}) => [
    for (final id in ids)
      backend.SprintDemanda(id: id, sprintId: sprint, demandaId: id),
  ];
  setUp(() {
    repository = FakeSprintRepository(sprints: []);
    model = SprintViewModel(repository: repository);
  });
  tearDown(() => model.dispose());

  test('cliente compartilhado usa 60 segundos sem substituir autenticação', () {
    expect(serverpodClient.connectionTimeout, const Duration(seconds: 60));
  });

  test(
    'timeout com commit confirmado retorna sucesso sem reenviar mutação',
    () async {
      repository.erroVinculo = TimeoutException('synthetic');
      repository.vinculosPorSprint[2] = links([1, 2, 3]);
      expect(
        await model.vincularDemandas(sprintId: 2, demandaIds: [1, 2]),
        isTrue,
      );
      expect(repository.chamadasVinculoLote, 1);
      expect(repository.chamadasVinculos, 1);
      expect(model.vinculos, hasLength(3));
      expect(model.erro, isNull);
      expect(model.vinculacaoInconclusiva, isFalse);
    },
  );

  test(
    'resultado incompleto permanece inconclusivo; novo toque só consulta',
    () async {
      repository.erroVinculo = TimeoutException('synthetic');
      repository.vinculosPorSprint[2] = links([1]);
      expect(
        await model.vincularDemandas(sprintId: 2, demandaIds: [1, 2]),
        isFalse,
      );
      expect(model.erro, contains('inconclusivo'));
      expect(model.vinculacaoInconclusiva, isTrue);
      repository.vinculosPorSprint[2] = links([1, 2]);
      expect(
        await model.vincularDemandas(sprintId: 2, demandaIds: [2, 1]),
        isTrue,
      );
      expect(repository.chamadasVinculoLote, 1);
      expect(repository.chamadasVinculos, 2);
      expect(model.vinculacaoInconclusiva, isFalse);
    },
  );

  test(
    'falha também na reconciliação não vira falha definitiva nem retry',
    () async {
      repository.erroVinculo = TimeoutException('synthetic');
      repository.erroVinculos = StateError('read unavailable');
      expect(
        await model.vincularDemandas(sprintId: 2, demandaIds: [1]),
        isFalse,
      );
      expect(model.erro, contains('inconclusivo'));
      expect(model.enviando, isFalse);
      expect(model.vinculacaoInconclusiva, isTrue);
      expect(repository.chamadasVinculoLote, 1);
      expect(repository.chamadasVinculos, 1);
    },
  );

  test(
    'vínculo de outra Sprint não confirma operação; bloqueia nova seleção',
    () async {
      repository.erroVinculo = TimeoutException('synthetic');
      repository.vinculosPorSprint[2] = links([1], sprint: 3);
      expect(
        await model.vincularDemandas(sprintId: 2, demandaIds: [1]),
        isFalse,
      );
      expect(
        await model.vincularDemandas(sprintId: 3, demandaIds: [1]),
        isFalse,
      );
      expect(repository.chamadasVinculoLote, 1);
      expect(model.vinculacaoInconclusiva, isTrue);
    },
  );

  test('atualização manual confirma operação pendente por leitura', () async {
    repository.erroVinculo = TimeoutException('synthetic');
    expect(await model.vincularDemandas(sprintId: 2, demandaIds: [1]), isFalse);
    repository.vinculosPorSprint[2] = links([1]);
    expect(await model.carregarVinculos(2), isTrue);
    expect(model.vinculacaoInconclusiva, isFalse);
    expect(repository.chamadasVinculoLote, 1);
  });

  test(
    'atualização incompleta mantém aviso de resultado inconclusivo',
    () async {
      repository.erroVinculo = TimeoutException('synthetic');
      expect(
        await model.vincularDemandas(sprintId: 2, demandaIds: [1]),
        isFalse,
      );
      expect(await model.carregarVinculos(2), isTrue);
      expect(model.vinculacaoInconclusiva, isTrue);
      expect(model.erro, contains('inconclusivo'));
      expect(repository.chamadasVinculoLote, 1);
    },
  );

  test('timeout individual também reconcilia sem repetir a mutação', () async {
    repository.erroVinculo = TimeoutException('synthetic');
    repository.vinculosPorSprint[2] = links([1]);
    expect(await model.vincularDemanda(sprintId: 2, demandaId: 1), isTrue);
    expect(repository.chamadasVinculo, 1);
    expect(repository.chamadasVinculos, 1);
  });

  test('erro de domínio mantém mensagem específica e não reconcilia', () async {
    repository.erroVinculo = backend.SprintException(
      codigo: backend.SprintErroCodigo.periodoSobreposto,
    );
    expect(await model.vincularDemandas(sprintId: 2, demandaIds: [1]), isFalse);
    expect(model.erro, contains('conflito'));
    expect(repository.chamadasVinculos, 0);
    expect(model.vinculacaoInconclusiva, isFalse);
  });

  test('sucesso normal deduplica seleção e não faz leitura extra', () async {
    expect(
      await model.vincularDemandas(sprintId: 2, demandaIds: [1, 1, 2]),
      isTrue,
    );
    expect(repository.demandaIdsVinculadas, [1, 2]);
    expect(repository.chamadasVinculos, 0);
    expect(model.vinculos, hasLength(2));
  });
}
