import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('create requests discard an externally supplied usuarioId', () {
    final demanda = DemandaCreateRequest.fromJson({
      ...DemandaCreateRequest(
        titulo: 'Demanda',
        tempoEstimadoMinutos: 60,
      ).toJson(),
      'usuarioId': 999,
    });
    final sprint = SprintCreateRequest.fromJson({
      ...SprintCreateRequest(
        nome: 'Sprint',
        dataInicio: DateTime.utc(2026, 10, 1),
        dataFim: DateTime.utc(2026, 10, 5),
      ).toJson(),
      'usuarioId': 999,
    });

    expect(demanda.toJson(), isNot(contains('usuarioId')));
    expect(sprint.toJson(), isNot(contains('usuarioId')));
  });
}
