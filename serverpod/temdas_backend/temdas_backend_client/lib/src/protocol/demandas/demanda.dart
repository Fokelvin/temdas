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
import '../demandas/demanda_status.dart' as _i2;
import '../demandas/prioridade.dart' as _i3;

abstract class Demanda implements _i1.SerializableModel {
  Demanda._({
    this.id,
    required this.titulo,
    this.descricao,
    required this.status,
    required this.prioridade,
    this.sprint,
    required this.tempoEstimadoMinutos,
    required this.tempoExecutadoMinutos,
    this.observacoes,
    required this.criadoEm,
    required this.atualizadoEm,
    this.concluidoEm,
  });

  factory Demanda({
    int? id,
    required String titulo,
    String? descricao,
    required _i2.DemandaStatus status,
    required _i3.Prioridade prioridade,
    String? sprint,
    required int tempoEstimadoMinutos,
    required int tempoExecutadoMinutos,
    String? observacoes,
    required DateTime criadoEm,
    required DateTime atualizadoEm,
    DateTime? concluidoEm,
  }) = _DemandaImpl;

  factory Demanda.fromJson(Map<String, dynamic> jsonSerialization) {
    return Demanda(
      id: jsonSerialization['id'] as int?,
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
      tempoExecutadoMinutos: jsonSerialization['tempoExecutadoMinutos'] as int,
      observacoes: jsonSerialization['observacoes'] as String?,
      criadoEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['criadoEm'],
      ),
      atualizadoEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['atualizadoEm'],
      ),
      concluidoEm: jsonSerialization['concluidoEm'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['concluidoEm'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String titulo;

  String? descricao;

  _i2.DemandaStatus status;

  _i3.Prioridade prioridade;

  String? sprint;

  int tempoEstimadoMinutos;

  int tempoExecutadoMinutos;

  String? observacoes;

  DateTime criadoEm;

  DateTime atualizadoEm;

  DateTime? concluidoEm;

  /// Returns a shallow copy of this [Demanda]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Demanda copyWith({
    int? id,
    String? titulo,
    String? descricao,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
    String? sprint,
    int? tempoEstimadoMinutos,
    int? tempoExecutadoMinutos,
    String? observacoes,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    DateTime? concluidoEm,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Demanda',
      if (id != null) 'id': id,
      'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      'status': status.toJson(),
      'prioridade': prioridade.toJson(),
      if (sprint != null) 'sprint': sprint,
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      'tempoExecutadoMinutos': tempoExecutadoMinutos,
      if (observacoes != null) 'observacoes': observacoes,
      'criadoEm': criadoEm.toJson(),
      'atualizadoEm': atualizadoEm.toJson(),
      if (concluidoEm != null) 'concluidoEm': concluidoEm?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DemandaImpl extends Demanda {
  _DemandaImpl({
    int? id,
    required String titulo,
    String? descricao,
    required _i2.DemandaStatus status,
    required _i3.Prioridade prioridade,
    String? sprint,
    required int tempoEstimadoMinutos,
    required int tempoExecutadoMinutos,
    String? observacoes,
    required DateTime criadoEm,
    required DateTime atualizadoEm,
    DateTime? concluidoEm,
  }) : super._(
         id: id,
         titulo: titulo,
         descricao: descricao,
         status: status,
         prioridade: prioridade,
         sprint: sprint,
         tempoEstimadoMinutos: tempoEstimadoMinutos,
         tempoExecutadoMinutos: tempoExecutadoMinutos,
         observacoes: observacoes,
         criadoEm: criadoEm,
         atualizadoEm: atualizadoEm,
         concluidoEm: concluidoEm,
       );

  /// Returns a shallow copy of this [Demanda]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Demanda copyWith({
    Object? id = _Undefined,
    String? titulo,
    Object? descricao = _Undefined,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
    Object? sprint = _Undefined,
    int? tempoEstimadoMinutos,
    int? tempoExecutadoMinutos,
    Object? observacoes = _Undefined,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    Object? concluidoEm = _Undefined,
  }) {
    return Demanda(
      id: id is int? ? id : this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao is String? ? descricao : this.descricao,
      status: status ?? this.status,
      prioridade: prioridade ?? this.prioridade,
      sprint: sprint is String? ? sprint : this.sprint,
      tempoEstimadoMinutos: tempoEstimadoMinutos ?? this.tempoEstimadoMinutos,
      tempoExecutadoMinutos:
          tempoExecutadoMinutos ?? this.tempoExecutadoMinutos,
      observacoes: observacoes is String? ? observacoes : this.observacoes,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      concluidoEm: concluidoEm is DateTime? ? concluidoEm : this.concluidoEm,
    );
  }
}
