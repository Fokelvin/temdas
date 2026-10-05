import 'package:serverpod/protocol.dart' hide Protocol;

import '../generated/protocol.dart';

/// Adds the PostgreSQL indexes created by custom SQL to Serverpod's runtime
/// target schema. Serverpod 3.4.11 cannot express partial or expression indexes
/// in .spy.yaml, nor can it express exclusion constraints there. PostgreSQL
/// exposes exclusion constraints as GiST indexes during schema introspection.
///
/// The SQL remains owned by the migration. This only tells the startup schema
/// comparison what that SQL creates; it does not create or alter database objects.
void registerSprintCustomIndexes() {
  final tables = Protocol.targetTableDefinitions;
  final position = tables.indexWhere((table) => table.name == 'sprints');
  if (position < 0) {
    throw StateError('Target schema does not contain the sprints table.');
  }

  final table = tables[position];
  final existingNames = table.indexes.map((index) => index.indexName).toSet();
  final customIndexes = <IndexDefinition>[
    IndexDefinition(
      indexName: 'sprints_nome_normalizado_sem_usuario_idx',
      elements: [_column('nomeNormalizado')],
      type: 'btree',
      isUnique: true,
      isPrimary: false,
      predicate: '("usuarioId" IS NULL)',
    ),
    IndexDefinition(
      indexName: 'sprints_uma_ativa_por_usuario_idx',
      elements: [_column('usuarioId')],
      type: 'btree',
      isUnique: true,
      isPrimary: false,
      predicate: "((status = 'ativa'::text) AND (\"usuarioId\" IS NOT NULL))",
    ),
    IndexDefinition(
      indexName: 'sprints_uma_ativa_sem_usuario_idx',
      elements: [_expression('(1)')],
      type: 'btree',
      isUnique: true,
      isPrimary: false,
      predicate: "((status = 'ativa'::text) AND (\"usuarioId\" IS NULL))",
    ),
    IndexDefinition(
      indexName: 'sprints_periodos_sem_sobreposicao_por_usuario',
      elements: [
        _column('usuarioId'),
        _expression(
          'daterange("dataInicio"::date, "dataFim"::date, \'[]\'::text)',
        ),
      ],
      type: 'gist',
      isUnique: false,
      isPrimary: false,
      predicate: _activePeriodPredicate(isLegacy: false),
    ),
    IndexDefinition(
      indexName: 'sprints_periodos_sem_sobreposicao_sem_usuario',
      elements: [
        _expression(
          'daterange("dataInicio"::date, "dataFim"::date, \'[]\'::text)',
        ),
      ],
      type: 'gist',
      isUnique: false,
      isPrimary: false,
      predicate: _activePeriodPredicate(isLegacy: true),
    ),
  ];

  tables[position] = table.copyWith(
    indexes: [
      ...table.indexes,
      ...customIndexes.where(
        (index) => !existingNames.contains(index.indexName),
      ),
    ],
  );
}

IndexElementDefinition _column(String name) => IndexElementDefinition(
  type: IndexElementDefinitionType.column,
  definition: name,
);

IndexElementDefinition _expression(String sql) => IndexElementDefinition(
  type: IndexElementDefinitionType.expression,
  definition: sql,
);

String _activePeriodPredicate({required bool isLegacy}) =>
    '(("usuarioId" IS ${isLegacy ? '' : 'NOT '}NULL) AND '
    "(status = ANY (ARRAY['planejada'::text, 'ativa'::text, "
    "'concluida'::text])))";
