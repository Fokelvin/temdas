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

abstract class SprintCreateRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SprintCreateRequest._({
    required this.nome,
    required this.dataInicio,
    required this.dataFim,
    this.tempoPrevistoMinutos,
  });

  factory SprintCreateRequest({
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) = _SprintCreateRequestImpl;

  factory SprintCreateRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return SprintCreateRequest(
      nome: jsonSerialization['nome'] as String,
      dataInicio: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['dataInicio'],
      ),
      dataFim: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dataFim']),
      tempoPrevistoMinutos: jsonSerialization['tempoPrevistoMinutos'] as int?,
    );
  }

  String nome;

  DateTime dataInicio;

  DateTime dataFim;

  int? tempoPrevistoMinutos;

  /// Returns a shallow copy of this [SprintCreateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SprintCreateRequest copyWith({
    String? nome,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? tempoPrevistoMinutos,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SprintCreateRequest',
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
      '__className__': 'SprintCreateRequest',
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

class _SprintCreateRequestImpl extends SprintCreateRequest {
  _SprintCreateRequestImpl({
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) : super._(
         nome: nome,
         dataInicio: dataInicio,
         dataFim: dataFim,
         tempoPrevistoMinutos: tempoPrevistoMinutos,
       );

  /// Returns a shallow copy of this [SprintCreateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SprintCreateRequest copyWith({
    String? nome,
    DateTime? dataInicio,
    DateTime? dataFim,
    Object? tempoPrevistoMinutos = _Undefined,
  }) {
    return SprintCreateRequest(
      nome: nome ?? this.nome,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      tempoPrevistoMinutos: tempoPrevistoMinutos is int?
          ? tempoPrevistoMinutos
          : this.tempoPrevistoMinutos,
    );
  }
}
