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
import '../demandas/prioridade.dart' as _i2;

abstract class DemandaCreateRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DemandaCreateRequest._({
    required this.titulo,
    this.descricao,
    this.prioridade,
    this.sprint,
    required this.tempoEstimadoMinutos,
    this.observacoes,
  });

  factory DemandaCreateRequest({
    required String titulo,
    String? descricao,
    _i2.Prioridade? prioridade,
    String? sprint,
    required int tempoEstimadoMinutos,
    String? observacoes,
  }) = _DemandaCreateRequestImpl;

  factory DemandaCreateRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DemandaCreateRequest(
      titulo: jsonSerialization['titulo'] as String,
      descricao: jsonSerialization['descricao'] as String?,
      prioridade: jsonSerialization['prioridade'] == null
          ? null
          : _i2.Prioridade.fromJson(
              (jsonSerialization['prioridade'] as String),
            ),
      sprint: jsonSerialization['sprint'] as String?,
      tempoEstimadoMinutos: jsonSerialization['tempoEstimadoMinutos'] as int,
      observacoes: jsonSerialization['observacoes'] as String?,
    );
  }

  String titulo;

  String? descricao;

  _i2.Prioridade? prioridade;

  String? sprint;

  int tempoEstimadoMinutos;

  String? observacoes;

  /// Returns a shallow copy of this [DemandaCreateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DemandaCreateRequest copyWith({
    String? titulo,
    String? descricao,
    _i2.Prioridade? prioridade,
    String? sprint,
    int? tempoEstimadoMinutos,
    String? observacoes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DemandaCreateRequest',
      'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      if (prioridade != null) 'prioridade': prioridade?.toJson(),
      if (sprint != null) 'sprint': sprint,
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      if (observacoes != null) 'observacoes': observacoes,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DemandaCreateRequest',
      'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      if (prioridade != null) 'prioridade': prioridade?.toJson(),
      if (sprint != null) 'sprint': sprint,
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      if (observacoes != null) 'observacoes': observacoes,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DemandaCreateRequestImpl extends DemandaCreateRequest {
  _DemandaCreateRequestImpl({
    required String titulo,
    String? descricao,
    _i2.Prioridade? prioridade,
    String? sprint,
    required int tempoEstimadoMinutos,
    String? observacoes,
  }) : super._(
         titulo: titulo,
         descricao: descricao,
         prioridade: prioridade,
         sprint: sprint,
         tempoEstimadoMinutos: tempoEstimadoMinutos,
         observacoes: observacoes,
       );

  /// Returns a shallow copy of this [DemandaCreateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DemandaCreateRequest copyWith({
    String? titulo,
    Object? descricao = _Undefined,
    Object? prioridade = _Undefined,
    Object? sprint = _Undefined,
    int? tempoEstimadoMinutos,
    Object? observacoes = _Undefined,
  }) {
    return DemandaCreateRequest(
      titulo: titulo ?? this.titulo,
      descricao: descricao is String? ? descricao : this.descricao,
      prioridade: prioridade is _i2.Prioridade? ? prioridade : this.prioridade,
      sprint: sprint is String? ? sprint : this.sprint,
      tempoEstimadoMinutos: tempoEstimadoMinutos ?? this.tempoEstimadoMinutos,
      observacoes: observacoes is String? ? observacoes : this.observacoes,
    );
  }
}
