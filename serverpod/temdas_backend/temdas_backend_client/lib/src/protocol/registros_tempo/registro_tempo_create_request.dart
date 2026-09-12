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

abstract class RegistroTempoCreateRequest implements _i1.SerializableModel {
  RegistroTempoCreateRequest._({
    required this.demandaId,
    required this.inicioEm,
    required this.duracaoMinutos,
  });

  factory RegistroTempoCreateRequest({
    required int demandaId,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) = _RegistroTempoCreateRequestImpl;

  factory RegistroTempoCreateRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RegistroTempoCreateRequest(
      demandaId: jsonSerialization['demandaId'] as int,
      inicioEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['inicioEm'],
      ),
      duracaoMinutos: jsonSerialization['duracaoMinutos'] as int,
    );
  }

  int demandaId;

  DateTime inicioEm;

  int duracaoMinutos;

  /// Returns a shallow copy of this [RegistroTempoCreateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RegistroTempoCreateRequest copyWith({
    int? demandaId,
    DateTime? inicioEm,
    int? duracaoMinutos,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RegistroTempoCreateRequest',
      'demandaId': demandaId,
      'inicioEm': inicioEm.toJson(),
      'duracaoMinutos': duracaoMinutos,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RegistroTempoCreateRequestImpl extends RegistroTempoCreateRequest {
  _RegistroTempoCreateRequestImpl({
    required int demandaId,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) : super._(
         demandaId: demandaId,
         inicioEm: inicioEm,
         duracaoMinutos: duracaoMinutos,
       );

  /// Returns a shallow copy of this [RegistroTempoCreateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RegistroTempoCreateRequest copyWith({
    int? demandaId,
    DateTime? inicioEm,
    int? duracaoMinutos,
  }) {
    return RegistroTempoCreateRequest(
      demandaId: demandaId ?? this.demandaId,
      inicioEm: inicioEm ?? this.inicioEm,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
    );
  }
}
