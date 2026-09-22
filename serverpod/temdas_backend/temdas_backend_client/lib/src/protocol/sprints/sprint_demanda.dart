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

import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class SprintDemanda implements _i1.SerializableModel {
  SprintDemanda._({
    this.id,
    required this.sprintId,
    required this.demandaId,
  });

  factory SprintDemanda({
    int? id,
    required int sprintId,
    required int demandaId,
  }) = _SprintDemandaImpl;

  factory SprintDemanda.fromJson(Map<String, dynamic> jsonSerialization) {
    return SprintDemanda(
      id: jsonSerialization['id'] as int?,
      sprintId: jsonSerialization['sprintId'] as int,
      demandaId: jsonSerialization['demandaId'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int sprintId;

  int demandaId;

  /// Returns a shallow copy of this [SprintDemanda]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SprintDemanda copyWith({
    int? id,
    int? sprintId,
    int? demandaId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SprintDemanda',
      if (id != null) 'id': id,
      'sprintId': sprintId,
      'demandaId': demandaId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SprintDemandaImpl extends SprintDemanda {
  _SprintDemandaImpl({
    int? id,
    required int sprintId,
    required int demandaId,
  }) : super._(
         id: id,
         sprintId: sprintId,
         demandaId: demandaId,
       );

  /// Returns a shallow copy of this [SprintDemanda]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SprintDemanda copyWith({
    Object? id = _Undefined,
    int? sprintId,
    int? demandaId,
  }) {
    return SprintDemanda(
      id: id is int? ? id : this.id,
      sprintId: sprintId ?? this.sprintId,
      demandaId: demandaId ?? this.demandaId,
    );
  }
}
