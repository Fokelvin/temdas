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
import '../demandas/movimentacao_demanda_erro_codigo.dart' as _i2;

abstract class MovimentacaoDemandaException
    implements
        _i1.SerializableException,
        _i1.SerializableModel,
        _i1.ProtocolSerialization {
  MovimentacaoDemandaException._({
    required this.codigo,
    required this.mensagem,
  });

  factory MovimentacaoDemandaException({
    required _i2.MovimentacaoDemandaErroCodigo codigo,
    required String mensagem,
  }) = _MovimentacaoDemandaExceptionImpl;

  factory MovimentacaoDemandaException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MovimentacaoDemandaException(
      codigo: _i2.MovimentacaoDemandaErroCodigo.fromJson(
        (jsonSerialization['codigo'] as String),
      ),
      mensagem: jsonSerialization['mensagem'] as String,
    );
  }

  _i2.MovimentacaoDemandaErroCodigo codigo;

  String mensagem;

  /// Returns a shallow copy of this [MovimentacaoDemandaException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MovimentacaoDemandaException copyWith({
    _i2.MovimentacaoDemandaErroCodigo? codigo,
    String? mensagem,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MovimentacaoDemandaException',
      'codigo': codigo.toJson(),
      'mensagem': mensagem,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MovimentacaoDemandaException',
      'codigo': codigo.toJson(),
      'mensagem': mensagem,
    };
  }

  @override
  String toString() {
    return 'MovimentacaoDemandaException(codigo: $codigo, mensagem: $mensagem)';
  }
}

class _MovimentacaoDemandaExceptionImpl extends MovimentacaoDemandaException {
  _MovimentacaoDemandaExceptionImpl({
    required _i2.MovimentacaoDemandaErroCodigo codigo,
    required String mensagem,
  }) : super._(
         codigo: codigo,
         mensagem: mensagem,
       );

  /// Returns a shallow copy of this [MovimentacaoDemandaException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MovimentacaoDemandaException copyWith({
    _i2.MovimentacaoDemandaErroCodigo? codigo,
    String? mensagem,
  }) {
    return MovimentacaoDemandaException(
      codigo: codigo ?? this.codigo,
      mensagem: mensagem ?? this.mensagem,
    );
  }
}
