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

abstract class AuthException
    implements
        _i1.SerializableException,
        _i1.SerializableModel,
        _i1.ProtocolSerialization {
  AuthException._({required this.codigo});

  factory AuthException({required String codigo}) = _AuthExceptionImpl;

  factory AuthException.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthException(codigo: jsonSerialization['codigo'] as String);
  }

  String codigo;

  /// Returns a shallow copy of this [AuthException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuthException copyWith({String? codigo});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthException',
      'codigo': codigo,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuthException',
      'codigo': codigo,
    };
  }

  @override
  String toString() {
    return 'AuthException(codigo: $codigo)';
  }
}

class _AuthExceptionImpl extends AuthException {
  _AuthExceptionImpl({required String codigo}) : super._(codigo: codigo);

  /// Returns a shallow copy of this [AuthException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuthException copyWith({String? codigo}) {
    return AuthException(codigo: codigo ?? this.codigo);
  }
}
