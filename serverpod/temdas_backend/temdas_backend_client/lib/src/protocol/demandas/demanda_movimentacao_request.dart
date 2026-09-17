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

abstract class DemandaMovimentacaoRequest implements _i1.SerializableModel {
  DemandaMovimentacaoRequest._({
    required this.demandaId,
    required this.statusDestino,
    required this.posicaoDestino,
  });

  factory DemandaMovimentacaoRequest({
    required int demandaId,
    required _i2.DemandaStatus statusDestino,
    required int posicaoDestino,
  }) = _DemandaMovimentacaoRequestImpl;

  factory DemandaMovimentacaoRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DemandaMovimentacaoRequest(
      demandaId: jsonSerialization['demandaId'] as int,
      statusDestino: _i2.DemandaStatus.fromJson(
        (jsonSerialization['statusDestino'] as String),
      ),
      posicaoDestino: jsonSerialization['posicaoDestino'] as int,
    );
  }

  int demandaId;

  _i2.DemandaStatus statusDestino;

  int posicaoDestino;

  /// Returns a shallow copy of this [DemandaMovimentacaoRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DemandaMovimentacaoRequest copyWith({
    int? demandaId,
    _i2.DemandaStatus? statusDestino,
    int? posicaoDestino,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DemandaMovimentacaoRequest',
      'demandaId': demandaId,
      'statusDestino': statusDestino.toJson(),
      'posicaoDestino': posicaoDestino,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DemandaMovimentacaoRequestImpl extends DemandaMovimentacaoRequest {
  _DemandaMovimentacaoRequestImpl({
    required int demandaId,
    required _i2.DemandaStatus statusDestino,
    required int posicaoDestino,
  }) : super._(
         demandaId: demandaId,
         statusDestino: statusDestino,
         posicaoDestino: posicaoDestino,
       );

  /// Returns a shallow copy of this [DemandaMovimentacaoRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DemandaMovimentacaoRequest copyWith({
    int? demandaId,
    _i2.DemandaStatus? statusDestino,
    int? posicaoDestino,
  }) {
    return DemandaMovimentacaoRequest(
      demandaId: demandaId ?? this.demandaId,
      statusDestino: statusDestino ?? this.statusDestino,
      posicaoDestino: posicaoDestino ?? this.posicaoDestino,
    );
  }
}
