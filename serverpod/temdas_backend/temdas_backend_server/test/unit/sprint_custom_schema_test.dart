import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:temdas_backend_server/src/sprints/sprint_custom_schema.dart';
import 'package:test/test.dart';

void main() {
  test('runtime schema registers only final per-user Sprint indexes once', () {
    final tables = Protocol.targetTableDefinitions;
    final position = tables.indexWhere((table) => table.name == 'sprints');
    final original = tables[position];
    addTearDown(() => tables[position] = original);

    registerSprintCustomIndexes();
    registerSprintCustomIndexes();

    final indexes = tables[position].indexes;
    expect(
      indexes.map((index) => index.indexName),
      unorderedEquals([
        'sprints_pkey',
        'sprints_nome_normalizado_idx',
        'sprints_uma_ativa_por_usuario_idx',
        'sprints_periodos_sem_sobreposicao_por_usuario',
      ]),
    );
    expect(
      indexes
          .singleWhere(
            (index) => index.indexName == 'sprints_uma_ativa_por_usuario_idx',
          )
          .predicate,
      "(status = 'ativa'::text)",
    );
    expect(
      indexes
          .singleWhere(
            (index) =>
                index.indexName ==
                'sprints_periodos_sem_sobreposicao_por_usuario',
          )
          .predicate,
      "(status = ANY (ARRAY['planejada'::text, 'ativa'::text, "
      "'concluida'::text]))",
    );
    for (final name in ['demandas', 'sprints']) {
      final table = tables.singleWhere((table) => table.name == name);
      expect(
        table.columns
            .singleWhere((column) => column.name == 'usuarioId')
            .isNullable,
        isFalse,
      );
    }
  });
}
