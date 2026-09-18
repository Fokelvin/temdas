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

abstract class RelatorioDemandaRequest implements _i1.SerializableModel {
  RelatorioDemandaRequest._({
    required this.inicioEm,
    required this.fimExclusivo,
    this.status,
    this.prioridade,
  });

  factory RelatorioDemandaRequest({
    required DateTime inicioEm,
    required DateTime fimExclusivo,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
  }) = _RelatorioDemandaRequestImpl;

  factory RelatorioDemandaRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RelatorioDemandaRequest(
      inicioEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['inicioEm'],
      ),
      fimExclusivo: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['fimExclusivo'],
      ),
      status: jsonSerialization['status'] == null
          ? null
          : _i2.DemandaStatus.fromJson((jsonSerialization['status'] as String)),
      prioridade: jsonSerialization['prioridade'] == null
          ? null
          : _i3.Prioridade.fromJson(
              (jsonSerialization['prioridade'] as String),
            ),
    );
  }

  DateTime inicioEm;

  DateTime fimExclusivo;

  _i2.DemandaStatus? status;

  _i3.Prioridade? prioridade;

  /// Returns a shallow copy of this [RelatorioDemandaRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RelatorioDemandaRequest copyWith({
    DateTime? inicioEm,
    DateTime? fimExclusivo,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RelatorioDemandaRequest',
      'inicioEm': inicioEm.toJson(),
      'fimExclusivo': fimExclusivo.toJson(),
      if (status != null) 'status': status?.toJson(),
      if (prioridade != null) 'prioridade': prioridade?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RelatorioDemandaRequestImpl extends RelatorioDemandaRequest {
  _RelatorioDemandaRequestImpl({
    required DateTime inicioEm,
    required DateTime fimExclusivo,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
  }) : super._(
         inicioEm: inicioEm,
         fimExclusivo: fimExclusivo,
         status: status,
         prioridade: prioridade,
       );

  /// Returns a shallow copy of this [RelatorioDemandaRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RelatorioDemandaRequest copyWith({
    DateTime? inicioEm,
    DateTime? fimExclusivo,
    Object? status = _Undefined,
    Object? prioridade = _Undefined,
  }) {
    return RelatorioDemandaRequest(
      inicioEm: inicioEm ?? this.inicioEm,
      fimExclusivo: fimExclusivo ?? this.fimExclusivo,
      status: status is _i2.DemandaStatus? ? status : this.status,
      prioridade: prioridade is _i3.Prioridade? ? prioridade : this.prioridade,
    );
  }
}
