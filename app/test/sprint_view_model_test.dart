import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/data/repositories/sprint_repository.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

void main() {
  test('cria e mantém a sprint no estado do view model', () async {
    final repository = _FakeSprintRepository();
    final viewModel = SprintViewModel(repository: repository);

    final criado = viewModel.criarSprint(
      nome: 'Entrega inicial',
      dataInicio: DateTime.utc(2026, 10, 5),
      dataFim: DateTime.utc(2026, 10, 9),
      tempoPrevistoMinutos: 240,
    );
    expect(viewModel.enviando, isTrue);
    expect(await criado, isTrue);

    expect(repository.nomeEnviado, 'Entrega inicial');
    expect(repository.tempoPrevistoEnviado, 240);
    expect(viewModel.sprints, hasLength(1));
    expect(viewModel.sprintSelecionada?.status, backend.SprintStatus.planejada);
    expect(viewModel.enviando, isFalse);
    expect(viewModel.erro, isNull);

    viewModel.dispose();
  });

  test(
    'carrega lista, detalhe e vínculos persistidos pelo repository',
    () async {
      final repository = _FakeSprintRepository();
      final persistida = await repository.criarSprint(
        nome: 'Persistida',
        dataInicio: DateTime.utc(2026, 10, 5),
        dataFim: DateTime.utc(2026, 10, 9),
      );
      final viewModel = SprintViewModel(repository: repository);

      expect(await viewModel.carregarSprints(), isTrue);
      expect(viewModel.sprints, [persistida]);

      expect(await viewModel.carregarSprint(persistida.id!), isTrue);
      expect(viewModel.sprintSelecionada?.id, persistida.id);

      await repository.vincularDemanda(sprintId: persistida.id!, demandaId: 31);
      expect(await viewModel.carregarVinculos(persistida.id!), isTrue);
      expect(viewModel.vinculos, hasLength(2));
      expect(viewModel.carregando, isFalse);

      viewModel.dispose();
    },
  );

  test('mantém estado carregando ao consultar a lista de sprints', () async {
    final repository = _FakeSprintRepository();
    final resposta = Completer<List<backend.Sprint>>();
    repository.sprintsPendentes = resposta;
    final viewModel = SprintViewModel(repository: repository);

    final carregamento = viewModel.carregarSprints();
    expect(viewModel.carregando, isTrue);
    resposta.complete([]);
    expect(await carregamento, isTrue);
    expect(viewModel.carregando, isFalse);

    viewModel.dispose();
  });

  test('atualiza a Sprint local após ativar, cancelar e reabrir', () async {
    final repository = _FakeSprintRepository();
    final viewModel = SprintViewModel(repository: repository);
    await viewModel.criarSprint(
      nome: 'Ciclo',
      dataInicio: DateTime.utc(2026, 10, 5),
      dataFim: DateTime.utc(2026, 10, 9),
      tempoPrevistoMinutos: 240,
    );
    final id = viewModel.sprintSelecionada!.id!;
    expect(
      await viewModel.atualizarSprint(
        id: id,
        nome: 'Ciclo editado',
        dataInicio: DateTime.utc(2026, 10, 6),
        dataFim: DateTime.utc(2026, 10, 10),
        tempoPrevistoMinutos: 300,
      ),
      isTrue,
    );
    expect(viewModel.sprintSelecionada?.nome, 'Ciclo editado');

    expect(await viewModel.ativarSprint(id), isTrue);
    expect(viewModel.sprintSelecionada?.status, backend.SprintStatus.ativa);
    await viewModel.vincularDemanda(sprintId: id, demandaId: 21);
    expect(viewModel.vinculos, hasLength(2));
    expect(await viewModel.cancelarSprint(id), isTrue);
    expect(viewModel.sprintSelecionada?.status, backend.SprintStatus.cancelada);
    expect(viewModel.vinculos, isEmpty);
    expect(await viewModel.reabrirSprint(id), isTrue);
    expect(viewModel.sprintSelecionada?.status, backend.SprintStatus.planejada);
    expect(viewModel.sprints, hasLength(1));

    viewModel.dispose();
  });

  test('carrega resumo, conclui e disponibiliza indicadores', () async {
    final repository = _FakeSprintRepository();
    final viewModel = SprintViewModel(repository: repository);
    await viewModel.criarSprint(
      nome: 'Conclusão',
      dataInicio: DateTime.utc(2026, 10, 5),
      dataFim: DateTime.utc(2026, 10, 9),
      tempoPrevistoMinutos: 240,
    );
    final id = viewModel.sprintSelecionada!.id!;

    expect(await viewModel.carregarResumoConclusao(id), isTrue);
    expect(viewModel.resumoConclusao?.quantidadeDemandasNaoConcluidas, 2);
    expect(viewModel.indicadores?.tempoTotalEstimadoMinutos, 180);

    expect(await viewModel.concluirSprint(id), isTrue);
    expect(viewModel.resultadoConclusao, isNotNull);
    expect(viewModel.sprintSelecionada?.status, backend.SprintStatus.concluida);
    expect(await viewModel.carregarIndicadores(id), isTrue);
    expect(viewModel.indicadores?.tempoExecutadoMinutos, 150);

    viewModel.dispose();
  });

  test(
    'vincula e desvincula Demandas sem manter cache potencialmente antigo',
    () async {
      final repository = _FakeSprintRepository();
      final viewModel = SprintViewModel(repository: repository);

      expect(
        await viewModel.vincularDemanda(sprintId: 7, demandaId: 12),
        isTrue,
      );
      expect(viewModel.vinculos, hasLength(2));
      expect(
        await viewModel.desvincularDemanda(sprintId: 7, demandaId: 12),
        isTrue,
      );
      expect(viewModel.vinculos, isEmpty);

      viewModel.dispose();
    },
  );

  test('vincula várias Demandas pelo contrato em lote', () async {
    final repository = _FakeSprintRepository();
    final viewModel = SprintViewModel(repository: repository);

    expect(
      await viewModel.vincularDemandas(sprintId: 7, demandaIds: [12, 13]),
      isTrue,
    );
    expect(viewModel.vinculos.map((vinculo) => vinculo.demandaId), [12, 13]);

    viewModel.dispose();
  });

  test(
    'converte códigos de negócio da Sprint em mensagens amigáveis',
    () async {
      final repository = _FakeSprintRepository()
        ..erro = backend.SprintException(
          codigo: backend.SprintErroCodigo.nomeDuplicado,
        );
      final viewModel = SprintViewModel(repository: repository);

      expect(
        await viewModel.criarSprint(
          nome: 'Duplicada',
          dataInicio: DateTime.utc(2026, 10, 5),
          dataFim: DateTime.utc(2026, 10, 9),
        ),
        isFalse,
      );
      expect(viewModel.erro, 'Já existe uma Sprint com esse nome.');

      viewModel.dispose();
    },
  );

  test(
    'traduz falha remota em erro amigável e libera estado de envio',
    () async {
      final repository = _FakeSprintRepository()
        ..erro = StateError('detalhe interno');
      final viewModel = SprintViewModel(repository: repository);

      expect(
        await viewModel.criarSprint(
          nome: 'Erro',
          dataInicio: DateTime.utc(2026, 10, 5),
          dataFim: DateTime.utc(2026, 10, 9),
        ),
        isFalse,
      );
      expect(
        viewModel.erro,
        'Não foi possível criar a sprint. Tente novamente.',
      );
      expect(viewModel.enviando, isFalse);
      expect(viewModel.sprints, isEmpty);

      viewModel.dispose();
    },
  );

  test(
    'estado carregando fica ativo enquanto indicadores são carregados',
    () async {
      final repository = _FakeSprintRepository();
      final resposta = Completer<backend.SprintIndicadores>();
      repository.indicadoresPendentes = resposta;
      final viewModel = SprintViewModel(repository: repository);

      final carregamento = viewModel.carregarIndicadores(4);
      expect(viewModel.carregando, isTrue);
      resposta.complete(repository.indicadores);
      expect(await carregamento, isTrue);
      expect(viewModel.carregando, isFalse);

      viewModel.dispose();
    },
  );

  test('excluir Sprint remove a entrada local e limpa seleção', () async {
    final repository = _FakeSprintRepository();
    final viewModel = SprintViewModel(repository: repository);
    await viewModel.criarSprint(
      nome: 'Excluir',
      dataInicio: DateTime.utc(2026, 10, 5),
      dataFim: DateTime.utc(2026, 10, 9),
    );
    final id = viewModel.sprintSelecionada!.id!;

    expect(await viewModel.excluirSprint(id), isTrue);
    expect(viewModel.sprints, isEmpty);
    expect(viewModel.sprintSelecionada, isNull);

    viewModel.dispose();
  });
}

class _FakeSprintRepository implements SprintRepository {
  Object? erro;
  Completer<backend.SprintIndicadores>? indicadoresPendentes;
  Completer<List<backend.Sprint>>? sprintsPendentes;
  String? nomeEnviado;
  int? tempoPrevistoEnviado;
  int _proximoId = 1;
  final Map<int, backend.Sprint> _sprints = {};
  final Map<int, List<backend.SprintDemanda>> _vinculos = {};

  final backend.SprintIndicadores indicadores = backend.SprintIndicadores(
    tempoPrevistoMinutos: 240,
    tempoTotalEstimadoMinutos: 180,
    tempoExecutadoMinutos: 150,
    diferencaExecutadoEstimadoMinutos: -30,
  );

  void _lancarSeConfigurado() {
    if (erro case final erro?) throw erro;
  }

  backend.Sprint _porId(int id) => _sprints[id]!;

  @override
  Future<List<backend.Sprint>> listarSprints() {
    _lancarSeConfigurado();
    return sprintsPendentes?.future ?? Future.value(_sprints.values.toList());
  }

  @override
  Future<backend.Sprint> buscarSprintPorId(int id) async {
    _lancarSeConfigurado();
    return _porId(id);
  }

  @override
  Future<List<backend.SprintDemanda>> listarDemandasDaSprint(int sprintId) {
    _lancarSeConfigurado();
    return Future.value(_vinculos[sprintId] ?? const []);
  }

  @override
  Future<backend.Sprint> criarSprint({
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) async {
    _lancarSeConfigurado();
    nomeEnviado = nome;
    tempoPrevistoEnviado = tempoPrevistoMinutos;
    final sprint = backend.Sprint(
      usuarioId: 1,
      id: _proximoId++,
      nome: nome,
      dataInicio: dataInicio,
      dataFim: dataFim,
      tempoPrevistoMinutos: tempoPrevistoMinutos,
      status: backend.SprintStatus.planejada,
    );
    _sprints[sprint.id!] = sprint;
    return sprint;
  }

  @override
  Future<backend.Sprint> atualizarSprint({
    required int id,
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) async {
    _lancarSeConfigurado();
    final atualizado = _porId(id).copyWith(
      nome: nome,
      dataInicio: dataInicio,
      dataFim: dataFim,
      tempoPrevistoMinutos: tempoPrevistoMinutos,
    );
    _sprints[id] = atualizado;
    return atualizado;
  }

  @override
  Future<backend.Sprint> ativarSprint(int id) =>
      _mudarStatus(id, backend.SprintStatus.ativa);

  @override
  Future<backend.Sprint> cancelarSprint(int id) =>
      _mudarStatus(id, backend.SprintStatus.cancelada);

  @override
  Future<backend.Sprint> reabrirSprint(int id) =>
      _mudarStatus(id, backend.SprintStatus.planejada);

  Future<backend.Sprint> _mudarStatus(
    int id,
    backend.SprintStatus status,
  ) async {
    _lancarSeConfigurado();
    final atualizado = _porId(id).copyWith(status: status);
    _sprints[id] = atualizado;
    return atualizado;
  }

  @override
  Future<backend.SprintConclusaoResponse> obterResumoConclusaoSprint(
    int id,
  ) async {
    _lancarSeConfigurado();
    return backend.SprintConclusaoResponse(
      sprint: _porId(id),
      quantidadeDemandasNaoConcluidas: 2,
      indicadores: indicadores,
    );
  }

  @override
  Future<backend.SprintConclusaoResponse> concluirSprint(int id) async {
    _lancarSeConfigurado();
    final concluida = _porId(
      id,
    ).copyWith(status: backend.SprintStatus.concluida);
    _sprints[id] = concluida;
    return backend.SprintConclusaoResponse(
      sprint: concluida,
      quantidadeDemandasNaoConcluidas: 2,
      indicadores: indicadores,
    );
  }

  @override
  Future<backend.SprintIndicadores> calcularIndicadoresSprint(int id) {
    _lancarSeConfigurado();
    return indicadoresPendentes?.future ?? Future.value(indicadores);
  }

  @override
  Future<bool> excluirSprint(int id) async {
    _lancarSeConfigurado();
    return _sprints.remove(id) != null;
  }

  @override
  Future<List<backend.SprintDemanda>> vincularDemanda({
    required int sprintId,
    required int demandaId,
  }) async {
    _lancarSeConfigurado();
    final vinculos = [
      backend.SprintDemanda(id: 1, sprintId: sprintId, demandaId: demandaId),
      backend.SprintDemanda(
        id: 2,
        sprintId: sprintId,
        demandaId: demandaId + 1,
      ),
    ];
    _vinculos[sprintId] = vinculos;
    return vinculos;
  }

  @override
  Future<List<backend.SprintDemanda>> vincularDemandas({
    required int sprintId,
    required List<int> demandaIds,
  }) async {
    _lancarSeConfigurado();
    final vinculos = [
      for (var i = 0; i < demandaIds.length; i++)
        backend.SprintDemanda(
          id: i + 1,
          sprintId: sprintId,
          demandaId: demandaIds[i],
        ),
    ];
    _vinculos[sprintId] = vinculos;
    return vinculos;
  }

  @override
  Future<bool> desvincularDemanda({
    required int sprintId,
    required int demandaId,
  }) async {
    _lancarSeConfigurado();
    _vinculos.remove(sprintId);
    return true;
  }
}
