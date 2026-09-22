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
import '../sprints/sprint_erro_codigo.dart' as _i2;

abstract class SprintException
    implements _i1.SerializableException, _i1.SerializableModel {
  SprintException._({required this.codigo});

  factory SprintException({required _i2.SprintErroCodigo codigo}) =
      _SprintExceptionImpl;

  factory SprintException.fromJson(Map<String, dynamic> jsonSerialization) {
    return SprintException(
      codigo: _i2.SprintErroCodigo.fromJson(
        (jsonSerialization['codigo'] as String),
      ),
    );
  }

  _i2.SprintErroCodigo codigo;

  /// Returns a shallow copy of this [SprintException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SprintException copyWith({_i2.SprintErroCodigo? codigo});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SprintException',
      'codigo': codigo.toJson(),
    };
  }

  @override
  String toString() {
    return 'SprintException(codigo: $codigo)';
  }
}

class _SprintExceptionImpl extends SprintException {
  _SprintExceptionImpl({required _i2.SprintErroCodigo codigo})
    : super._(codigo: codigo);

  /// Returns a shallow copy of this [SprintException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SprintException copyWith({_i2.SprintErroCodigo? codigo}) {
    return SprintException(codigo: codigo ?? this.codigo);
  }
}
