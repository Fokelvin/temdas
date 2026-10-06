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

abstract class RegistroTempoException
    implements _i1.SerializableException, _i1.SerializableModel {
  RegistroTempoException._({required this.codigo});

  factory RegistroTempoException({required String codigo}) =
      _RegistroTempoExceptionImpl;

  factory RegistroTempoException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RegistroTempoException(
      codigo: jsonSerialization['codigo'] as String,
    );
  }

  String codigo;

  /// Returns a shallow copy of this [RegistroTempoException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RegistroTempoException copyWith({String? codigo});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RegistroTempoException',
      'codigo': codigo,
    };
  }

  @override
  String toString() {
    return 'RegistroTempoException(codigo: $codigo)';
  }
}

class _RegistroTempoExceptionImpl extends RegistroTempoException {
  _RegistroTempoExceptionImpl({required String codigo})
    : super._(codigo: codigo);

  /// Returns a shallow copy of this [RegistroTempoException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RegistroTempoException copyWith({String? codigo}) {
    return RegistroTempoException(codigo: codigo ?? this.codigo);
  }
}
