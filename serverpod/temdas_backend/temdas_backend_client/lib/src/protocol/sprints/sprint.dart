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
import '../sprints/sprint_status.dart' as _i2;

abstract class Sprint implements _i1.SerializableModel {
  Sprint._({
    this.id,
    required this.nome,
    required this.dataInicio,
    required this.dataFim,
    this.tempoPrevistoMinutos,
    required this.status,
  });

  factory Sprint({
    int? id,
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
    required _i2.SprintStatus status,
  }) = _SprintImpl;

  factory Sprint.fromJson(Map<String, dynamic> jsonSerialization) {
    return Sprint(
      id: jsonSerialization['id'] as int?,
      nome: jsonSerialization['nome'] as String,
      dataInicio: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['dataInicio'],
      ),
      dataFim: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dataFim']),
      tempoPrevistoMinutos: jsonSerialization['tempoPrevistoMinutos'] as int?,
      status: _i2.SprintStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String nome;

  DateTime dataInicio;

  DateTime dataFim;

  int? tempoPrevistoMinutos;

  _i2.SprintStatus status;

  /// Returns a shallow copy of this [Sprint]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Sprint copyWith({
    int? id,
    String? nome,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? tempoPrevistoMinutos,
    _i2.SprintStatus? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Sprint',
      if (id != null) 'id': id,
      'nome': nome,
      'dataInicio': dataInicio.toJson(),
      'dataFim': dataFim.toJson(),
      if (tempoPrevistoMinutos != null)
        'tempoPrevistoMinutos': tempoPrevistoMinutos,
      'status': status.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SprintImpl extends Sprint {
  _SprintImpl({
    int? id,
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
    required _i2.SprintStatus status,
  }) : super._(
         id: id,
         nome: nome,
         dataInicio: dataInicio,
         dataFim: dataFim,
         tempoPrevistoMinutos: tempoPrevistoMinutos,
         status: status,
       );

  /// Returns a shallow copy of this [Sprint]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Sprint copyWith({
    Object? id = _Undefined,
    String? nome,
    DateTime? dataInicio,
    DateTime? dataFim,
    Object? tempoPrevistoMinutos = _Undefined,
    _i2.SprintStatus? status,
  }) {
    return Sprint(
      id: id is int? ? id : this.id,
      nome: nome ?? this.nome,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      tempoPrevistoMinutos: tempoPrevistoMinutos is int?
          ? tempoPrevistoMinutos
          : this.tempoPrevistoMinutos,
      status: status ?? this.status,
    );
  }
}
