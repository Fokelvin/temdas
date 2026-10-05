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

abstract class AuthMe
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AuthMe._({
    required this.usuarioId,
    required this.aal,
  });

  factory AuthMe({
    required int usuarioId,
    required String aal,
  }) = _AuthMeImpl;

  factory AuthMe.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthMe(
      usuarioId: jsonSerialization['usuarioId'] as int,
      aal: jsonSerialization['aal'] as String,
    );
  }

  int usuarioId;

  String aal;

  /// Returns a shallow copy of this [AuthMe]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuthMe copyWith({
    int? usuarioId,
    String? aal,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthMe',
      'usuarioId': usuarioId,
      'aal': aal,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuthMe',
      'usuarioId': usuarioId,
      'aal': aal,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AuthMeImpl extends AuthMe {
  _AuthMeImpl({
    required int usuarioId,
    required String aal,
  }) : super._(
         usuarioId: usuarioId,
         aal: aal,
       );

  /// Returns a shallow copy of this [AuthMe]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuthMe copyWith({
    int? usuarioId,
    String? aal,
  }) {
    return AuthMe(
      usuarioId: usuarioId ?? this.usuarioId,
      aal: aal ?? this.aal,
    );
  }
}
