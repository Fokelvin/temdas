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

abstract class SprintUpdateRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SprintUpdateRequest._({
    required this.id,
    required this.nome,
    required this.dataInicio,
    required this.dataFim,
    this.tempoPrevistoMinutos,
  });

  factory SprintUpdateRequest({
    required int id,
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) = _SprintUpdateRequestImpl;

  factory SprintUpdateRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return SprintUpdateRequest(
      id: jsonSerialization['id'] as int,
      nome: jsonSerialization['nome'] as String,
      dataInicio: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['dataInicio'],
      ),
      dataFim: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dataFim']),
      tempoPrevistoMinutos: jsonSerialization['tempoPrevistoMinutos'] as int?,
    );
  }

  int id;

  String nome;

  DateTime dataInicio;

  DateTime dataFim;

  int? tempoPrevistoMinutos;

  /// Returns a shallow copy of this [SprintUpdateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SprintUpdateRequest copyWith({
    int? id,
    String? nome,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? tempoPrevistoMinutos,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SprintUpdateRequest',
      'id': id,
      'nome': nome,
      'dataInicio': dataInicio.toJson(),
      'dataFim': dataFim.toJson(),
      if (tempoPrevistoMinutos != null)
        'tempoPrevistoMinutos': tempoPrevistoMinutos,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SprintUpdateRequest',
      'id': id,
      'nome': nome,
      'dataInicio': dataInicio.toJson(),
      'dataFim': dataFim.toJson(),
      if (tempoPrevistoMinutos != null)
        'tempoPrevistoMinutos': tempoPrevistoMinutos,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SprintUpdateRequestImpl extends SprintUpdateRequest {
  _SprintUpdateRequestImpl({
    required int id,
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) : super._(
         id: id,
         nome: nome,
         dataInicio: dataInicio,
         dataFim: dataFim,
         tempoPrevistoMinutos: tempoPrevistoMinutos,
       );

  /// Returns a shallow copy of this [SprintUpdateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SprintUpdateRequest copyWith({
    int? id,
    String? nome,
    DateTime? dataInicio,
    DateTime? dataFim,
    Object? tempoPrevistoMinutos = _Undefined,
  }) {
    return SprintUpdateRequest(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      tempoPrevistoMinutos: tempoPrevistoMinutos is int?
          ? tempoPrevistoMinutos
          : this.tempoPrevistoMinutos,
    );
  }
}
