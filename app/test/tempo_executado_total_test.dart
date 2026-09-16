import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view_model/tempo_executado_total.dart';

import 'support/fake_demanda_repository.dart';

void main() {
  test('sem descendentes usa apenas o tempo próprio', () {
    expect(calcularTemposExecutadosTotais([demandaFixture()]), {1: 30});
    expect(calcularTemposExecutadosTotais([]), isEmpty);
  });

  test(
    'mãe inclui uma filha sem alterar os valores persistidos ou estimados',
    () {
      final mae = demandaFixture(tempoEstimadoMinutos: 50);
      final filha = demandaFixture(
        id: 2,
        demandaPaiId: 1,
        tempoExecutadoMinutos: 60,
        tempoEstimadoMinutos: 100,
      );
      expect(calcularTemposExecutadosTotais([mae, filha]), {1: 90, 2: 60});
      expect(mae.tempoExecutadoMinutos, 30);
      expect(filha.tempoExecutadoMinutos, 60);
      expect(mae.tempoEstimadoMinutos, 50);
      expect(filha.tempoEstimadoMinutos, 100);
    },
  );

  test('soma várias filhas e neta, inclusive na subárvore da filha', () {
    final demandas = [
      demandaFixture(id: 4, demandaPaiId: 3, tempoExecutadoMinutos: 30),
      demandaFixture(id: 3, demandaPaiId: 1, tempoExecutadoMinutos: 90),
      demandaFixture(id: 1, tempoExecutadoMinutos: 30),
      demandaFixture(id: 2, demandaPaiId: 1, tempoExecutadoMinutos: 60),
      demandaFixture(id: 5, tempoExecutadoMinutos: 15),
    ];
    expect(calcularTemposExecutadosTotais(demandas), {
      1: 210,
      2: 60,
      3: 120,
      4: 30,
      5: 15,
    });
    expect(
      calcularTemposExecutadosTotais(demandas.reversed.toList()),
      calcularTemposExecutadosTotais(demandas),
    );
  });

  test('não limita a agregação a mãe, filha e neta', () {
    final demandas = [
      for (var id = 1; id <= 100; id++)
        demandaFixture(
          id: id,
          demandaPaiId: id == 1 ? null : id - 1,
          tempoExecutadoMinutos: 1,
        ),
    ];
    final totais = calcularTemposExecutadosTotais(demandas);
    for (var id = 1; id <= 100; id++) {
      expect(totais[id], 101 - id);
    }
  });

  test('relações ausentes e cíclicas não causam recursão infinita', () {
    expect(
      calcularTemposExecutadosTotais([
        demandaFixture(id: 1, demandaPaiId: 999),
        demandaFixture(id: 2, demandaPaiId: 2),
      ]),
      {1: 30, 2: 30},
    );
  });
}
