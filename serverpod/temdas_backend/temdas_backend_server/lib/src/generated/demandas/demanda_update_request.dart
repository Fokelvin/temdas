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
import '../demandas/demanda_status.dart' as _i2;
import '../demandas/prioridade.dart' as _i3;

abstract class DemandaUpdateRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DemandaUpdateRequest._({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.status,
    required this.prioridade,
    this.sprint,
    required this.tempoEstimadoMinutos,
    this.observacoes,
  });

  factory DemandaUpdateRequest({
    required int id,
    required String titulo,
    String? descricao,
    required _i2.DemandaStatus status,
    required _i3.Prioridade prioridade,
    String? sprint,
    required int tempoEstimadoMinutos,
    String? observacoes,
  }) = _DemandaUpdateRequestImpl;

  factory DemandaUpdateRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DemandaUpdateRequest(
      id: jsonSerialization['id'] as int,
      titulo: jsonSerialization['titulo'] as String,
      descricao: jsonSerialization['descricao'] as String?,
      status: _i2.DemandaStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      prioridade: _i3.Prioridade.fromJson(
        (jsonSerialization['prioridade'] as String),
      ),
      sprint: jsonSerialization['sprint'] as String?,
      tempoEstimadoMinutos: jsonSerialization['tempoEstimadoMinutos'] as int,
      observacoes: jsonSerialization['observacoes'] as String?,
    );
  }

  int id;

  String titulo;

  String? descricao;

  _i2.DemandaStatus status;

  _i3.Prioridade prioridade;

  String? sprint;

  int tempoEstimadoMinutos;

  String? observacoes;

  /// Returns a shallow copy of this [DemandaUpdateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DemandaUpdateRequest copyWith({
    int? id,
    String? titulo,
    String? descricao,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
    String? sprint,
    int? tempoEstimadoMinutos,
    String? observacoes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DemandaUpdateRequest',
      'id': id,
      'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      'status': status.toJson(),
      'prioridade': prioridade.toJson(),
      if (sprint != null) 'sprint': sprint,
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      if (observacoes != null) 'observacoes': observacoes,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DemandaUpdateRequest',
      'id': id,
      'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      'status': status.toJson(),
      'prioridade': prioridade.toJson(),
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

class _DemandaUpdateRequestImpl extends DemandaUpdateRequest {
  _DemandaUpdateRequestImpl({
    required int id,
    required String titulo,
    String? descricao,
    required _i2.DemandaStatus status,
    required _i3.Prioridade prioridade,
    String? sprint,
    required int tempoEstimadoMinutos,
    String? observacoes,
  }) : super._(
         id: id,
         titulo: titulo,
         descricao: descricao,
         status: status,
         prioridade: prioridade,
         sprint: sprint,
         tempoEstimadoMinutos: tempoEstimadoMinutos,
         observacoes: observacoes,
       );

  /// Returns a shallow copy of this [DemandaUpdateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DemandaUpdateRequest copyWith({
    int? id,
    String? titulo,
    Object? descricao = _Undefined,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
    Object? sprint = _Undefined,
    int? tempoEstimadoMinutos,
    Object? observacoes = _Undefined,
  }) {
    return DemandaUpdateRequest(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao is String? ? descricao : this.descricao,
      status: status ?? this.status,
      prioridade: prioridade ?? this.prioridade,
      sprint: sprint is String? ? sprint : this.sprint,
      tempoEstimadoMinutos: tempoEstimadoMinutos ?? this.tempoEstimadoMinutos,
      observacoes: observacoes is String? ? observacoes : this.observacoes,
    );
  }
}
