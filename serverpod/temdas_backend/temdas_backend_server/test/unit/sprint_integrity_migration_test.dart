import 'dart:convert';
import 'dart:io';

import 'package:serverpod/protocol.dart' show DatabaseDefinition;
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'latest migration preserves the complete managed backend target',
    () {
      final definition = DatabaseDefinition.fromJson(
        jsonDecode(
              File(
                'migrations/20261029183226724-pacote4-demandas/definition.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );

      // Partial/exclusion indexes are intentionally registered separately by
      // sprint_custom_schema.dart, not added to the generator's JSON artifacts.
      expect(
        {for (final table in definition.tables) table.name: table.toJson()},
        {
          for (final table in Protocol.targetTableDefinitions)
            table.name: table.toJson(),
        },
      );
      expect(
        definition.installedModules
            .singleWhere((module) => module.module == 'temdas_backend')
            .version,
        '20261029183226724-pacote4-demandas',
      );
    },
  );
}
