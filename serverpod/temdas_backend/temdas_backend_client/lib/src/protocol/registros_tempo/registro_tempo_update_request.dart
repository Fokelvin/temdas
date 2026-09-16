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

abstract class RegistroTempoUpdateRequest implements _i1.SerializableModel {
  RegistroTempoUpdateRequest._({
    required this.id,
    required this.inicioEm,
    required this.duracaoMinutos,
  });

  factory RegistroTempoUpdateRequest({
    required int id,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) = _RegistroTempoUpdateRequestImpl;

  factory RegistroTempoUpdateRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RegistroTempoUpdateRequest(
      id: jsonSerialization['id'] as int,
      inicioEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['inicioEm'],
      ),
      duracaoMinutos: jsonSerialization['duracaoMinutos'] as int,
    );
  }

  int id;

  DateTime inicioEm;

  int duracaoMinutos;

  /// Returns a shallow copy of this [RegistroTempoUpdateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RegistroTempoUpdateRequest copyWith({
    int? id,
    DateTime? inicioEm,
    int? duracaoMinutos,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RegistroTempoUpdateRequest',
      'id': id,
      'inicioEm': inicioEm.toJson(),
      'duracaoMinutos': duracaoMinutos,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RegistroTempoUpdateRequestImpl extends RegistroTempoUpdateRequest {
  _RegistroTempoUpdateRequestImpl({
    required int id,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) : super._(
         id: id,
         inicioEm: inicioEm,
         duracaoMinutos: duracaoMinutos,
       );

  /// Returns a shallow copy of this [RegistroTempoUpdateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RegistroTempoUpdateRequest copyWith({
    int? id,
    DateTime? inicioEm,
    int? duracaoMinutos,
  }) {
    return RegistroTempoUpdateRequest(
      id: id ?? this.id,
      inicioEm: inicioEm ?? this.inicioEm,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
    );
  }
}
