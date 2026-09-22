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
import '../demandas/transicao_status_erro_codigo.dart' as _i2;

abstract class TransicaoStatusException
    implements
        _i1.SerializableException,
        _i1.SerializableModel,
        _i1.ProtocolSerialization {
  TransicaoStatusException._({
    required this.codigo,
    required this.mensagem,
    bool? podeConcluirEmCascata,
  }) : podeConcluirEmCascata = podeConcluirEmCascata ?? false;

  factory TransicaoStatusException({
    required _i2.TransicaoStatusErroCodigo codigo,
    required String mensagem,
    bool? podeConcluirEmCascata,
  }) = _TransicaoStatusExceptionImpl;

  factory TransicaoStatusException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TransicaoStatusException(
      codigo: _i2.TransicaoStatusErroCodigo.fromJson(
        (jsonSerialization['codigo'] as String),
      ),
      mensagem: jsonSerialization['mensagem'] as String,
      podeConcluirEmCascata: jsonSerialization['podeConcluirEmCascata'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['podeConcluirEmCascata'],
            ),
    );
  }

  _i2.TransicaoStatusErroCodigo codigo;

  String mensagem;

  bool podeConcluirEmCascata;

  /// Returns a shallow copy of this [TransicaoStatusException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TransicaoStatusException copyWith({
    _i2.TransicaoStatusErroCodigo? codigo,
    String? mensagem,
    bool? podeConcluirEmCascata,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TransicaoStatusException',
      'codigo': codigo.toJson(),
      'mensagem': mensagem,
      'podeConcluirEmCascata': podeConcluirEmCascata,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TransicaoStatusException',
      'codigo': codigo.toJson(),
      'mensagem': mensagem,
      'podeConcluirEmCascata': podeConcluirEmCascata,
    };
  }

  @override
  String toString() {
    return 'TransicaoStatusException(codigo: $codigo, mensagem: $mensagem, podeConcluirEmCascata: $podeConcluirEmCascata)';
  }
}

class _TransicaoStatusExceptionImpl extends TransicaoStatusException {
  _TransicaoStatusExceptionImpl({
    required _i2.TransicaoStatusErroCodigo codigo,
    required String mensagem,
    bool? podeConcluirEmCascata,
  }) : super._(
         codigo: codigo,
         mensagem: mensagem,
         podeConcluirEmCascata: podeConcluirEmCascata,
       );

  /// Returns a shallow copy of this [TransicaoStatusException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TransicaoStatusException copyWith({
    _i2.TransicaoStatusErroCodigo? codigo,
    String? mensagem,
    bool? podeConcluirEmCascata,
  }) {
    return TransicaoStatusException(
      codigo: codigo ?? this.codigo,
      mensagem: mensagem ?? this.mensagem,
      podeConcluirEmCascata:
          podeConcluirEmCascata ?? this.podeConcluirEmCascata,
    );
  }
}
