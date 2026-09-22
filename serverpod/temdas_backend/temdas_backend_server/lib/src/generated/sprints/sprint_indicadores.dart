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

abstract class SprintIndicadores
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SprintIndicadores._({
    this.tempoPrevistoMinutos,
    required this.tempoTotalEstimadoMinutos,
    required this.tempoExecutadoMinutos,
    required this.diferencaExecutadoEstimadoMinutos,
  });

  factory SprintIndicadores({
    int? tempoPrevistoMinutos,
    required int tempoTotalEstimadoMinutos,
    required int tempoExecutadoMinutos,
    required int diferencaExecutadoEstimadoMinutos,
  }) = _SprintIndicadoresImpl;

  factory SprintIndicadores.fromJson(Map<String, dynamic> jsonSerialization) {
    return SprintIndicadores(
      tempoPrevistoMinutos: jsonSerialization['tempoPrevistoMinutos'] as int?,
      tempoTotalEstimadoMinutos:
          jsonSerialization['tempoTotalEstimadoMinutos'] as int,
      tempoExecutadoMinutos: jsonSerialization['tempoExecutadoMinutos'] as int,
      diferencaExecutadoEstimadoMinutos:
          jsonSerialization['diferencaExecutadoEstimadoMinutos'] as int,
    );
  }

  int? tempoPrevistoMinutos;

  int tempoTotalEstimadoMinutos;

  int tempoExecutadoMinutos;

  int diferencaExecutadoEstimadoMinutos;

  /// Returns a shallow copy of this [SprintIndicadores]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SprintIndicadores copyWith({
    int? tempoPrevistoMinutos,
    int? tempoTotalEstimadoMinutos,
    int? tempoExecutadoMinutos,
    int? diferencaExecutadoEstimadoMinutos,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SprintIndicadores',
      if (tempoPrevistoMinutos != null)
        'tempoPrevistoMinutos': tempoPrevistoMinutos,
      'tempoTotalEstimadoMinutos': tempoTotalEstimadoMinutos,
      'tempoExecutadoMinutos': tempoExecutadoMinutos,
      'diferencaExecutadoEstimadoMinutos': diferencaExecutadoEstimadoMinutos,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SprintIndicadores',
      if (tempoPrevistoMinutos != null)
        'tempoPrevistoMinutos': tempoPrevistoMinutos,
      'tempoTotalEstimadoMinutos': tempoTotalEstimadoMinutos,
      'tempoExecutadoMinutos': tempoExecutadoMinutos,
      'diferencaExecutadoEstimadoMinutos': diferencaExecutadoEstimadoMinutos,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SprintIndicadoresImpl extends SprintIndicadores {
  _SprintIndicadoresImpl({
    int? tempoPrevistoMinutos,
    required int tempoTotalEstimadoMinutos,
    required int tempoExecutadoMinutos,
    required int diferencaExecutadoEstimadoMinutos,
  }) : super._(
         tempoPrevistoMinutos: tempoPrevistoMinutos,
         tempoTotalEstimadoMinutos: tempoTotalEstimadoMinutos,
         tempoExecutadoMinutos: tempoExecutadoMinutos,
         diferencaExecutadoEstimadoMinutos: diferencaExecutadoEstimadoMinutos,
       );

  /// Returns a shallow copy of this [SprintIndicadores]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SprintIndicadores copyWith({
    Object? tempoPrevistoMinutos = _Undefined,
    int? tempoTotalEstimadoMinutos,
    int? tempoExecutadoMinutos,
    int? diferencaExecutadoEstimadoMinutos,
  }) {
    return SprintIndicadores(
      tempoPrevistoMinutos: tempoPrevistoMinutos is int?
          ? tempoPrevistoMinutos
          : this.tempoPrevistoMinutos,
      tempoTotalEstimadoMinutos:
          tempoTotalEstimadoMinutos ?? this.tempoTotalEstimadoMinutos,
      tempoExecutadoMinutos:
          tempoExecutadoMinutos ?? this.tempoExecutadoMinutos,
      diferencaExecutadoEstimadoMinutos:
          diferencaExecutadoEstimadoMinutos ??
          this.diferencaExecutadoEstimadoMinutos,
    );
  }
}
