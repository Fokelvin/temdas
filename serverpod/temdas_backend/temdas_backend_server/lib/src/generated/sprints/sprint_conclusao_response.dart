/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod/serverpod.dart' as _i1;
import '../sprints/sprint.dart' as _i2;
import '../sprints/sprint_indicadores.dart' as _i3;
import 'package:temdas_backend_server/src/generated/protocol.dart' as _i4;

abstract class SprintConclusaoResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SprintConclusaoResponse._({
    required this.sprint,
    required this.quantidadeDemandasNaoConcluidas,
    required this.indicadores,
  });

  factory SprintConclusaoResponse({
    required _i2.Sprint sprint,
    required int quantidadeDemandasNaoConcluidas,
    required _i3.SprintIndicadores indicadores,
  }) = _SprintConclusaoResponseImpl;

  factory SprintConclusaoResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SprintConclusaoResponse(
      sprint: _i4.Protocol().deserialize<_i2.Sprint>(
        jsonSerialization['sprint'],
      ),
      quantidadeDemandasNaoConcluidas:
          jsonSerialization['quantidadeDemandasNaoConcluidas'] as int,
      indicadores: _i4.Protocol().deserialize<_i3.SprintIndicadores>(
        jsonSerialization['indicadores'],
      ),
    );
  }

  _i2.Sprint sprint;

  int quantidadeDemandasNaoConcluidas;

  _i3.SprintIndicadores indicadores;

  /// Returns a shallow copy of this [SprintConclusaoResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SprintConclusaoResponse copyWith({
    _i2.Sprint? sprint,
    int? quantidadeDemandasNaoConcluidas,
    _i3.SprintIndicadores? indicadores,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SprintConclusaoResponse',
      'sprint': sprint.toJson(),
      'quantidadeDemandasNaoConcluidas': quantidadeDemandasNaoConcluidas,
      'indicadores': indicadores.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SprintConclusaoResponse',
      'sprint': sprint.toJsonForProtocol(),
      'quantidadeDemandasNaoConcluidas': quantidadeDemandasNaoConcluidas,
      'indicadores': indicadores.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SprintConclusaoResponseImpl extends SprintConclusaoResponse {
  _SprintConclusaoResponseImpl({
    required _i2.Sprint sprint,
    required int quantidadeDemandasNaoConcluidas,
    required _i3.SprintIndicadores indicadores,
  }) : super._(
         sprint: sprint,
         quantidadeDemandasNaoConcluidas: quantidadeDemandasNaoConcluidas,
         indicadores: indicadores,
       );

  /// Returns a shallow copy of this [SprintConclusaoResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SprintConclusaoResponse copyWith({
    _i2.Sprint? sprint,
    int? quantidadeDemandasNaoConcluidas,
    _i3.SprintIndicadores? indicadores,
  }) {
    return SprintConclusaoResponse(
      sprint: sprint ?? this.sprint.copyWith(),
      quantidadeDemandasNaoConcluidas:
          quantidadeDemandasNaoConcluidas ??
          this.quantidadeDemandasNaoConcluidas,
      indicadores: indicadores ?? this.indicadores.copyWith(),
    );
  }
}
