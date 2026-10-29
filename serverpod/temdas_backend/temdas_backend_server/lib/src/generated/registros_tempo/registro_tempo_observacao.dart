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

/// Trecho de observação com horários UTC; o cliente apresenta no fuso local.
abstract class RegistroTempoObservacao
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  RegistroTempoObservacao._({
    required this.inicioEm,
    required this.fimEm,
    required this.texto,
  });

  factory RegistroTempoObservacao({
    required DateTime inicioEm,
    required DateTime fimEm,
    required String texto,
  }) = _RegistroTempoObservacaoImpl;

  factory RegistroTempoObservacao.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RegistroTempoObservacao(
      inicioEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['inicioEm'],
      ),
      fimEm: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['fimEm']),
      texto: jsonSerialization['texto'] as String,
    );
  }

  DateTime inicioEm;

  DateTime fimEm;

  String texto;

  /// Returns a shallow copy of this [RegistroTempoObservacao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RegistroTempoObservacao copyWith({
    DateTime? inicioEm,
    DateTime? fimEm,
    String? texto,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RegistroTempoObservacao',
      'inicioEm': inicioEm.toJson(),
      'fimEm': fimEm.toJson(),
      'texto': texto,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RegistroTempoObservacao',
      'inicioEm': inicioEm.toJson(),
      'fimEm': fimEm.toJson(),
      'texto': texto,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RegistroTempoObservacaoImpl extends RegistroTempoObservacao {
  _RegistroTempoObservacaoImpl({
    required DateTime inicioEm,
    required DateTime fimEm,
    required String texto,
  }) : super._(
         inicioEm: inicioEm,
         fimEm: fimEm,
         texto: texto,
       );

  /// Returns a shallow copy of this [RegistroTempoObservacao]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RegistroTempoObservacao copyWith({
    DateTime? inicioEm,
    DateTime? fimEm,
    String? texto,
  }) {
    return RegistroTempoObservacao(
      inicioEm: inicioEm ?? this.inicioEm,
      fimEm: fimEm ?? this.fimEm,
      texto: texto ?? this.texto,
    );
  }
}
