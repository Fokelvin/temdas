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
import '../registros_tempo/registro_tempo_observacao.dart' as _i2;
import 'package:temdas_backend_client/src/protocol/protocol.dart' as _i3;

abstract class RegistroTempo implements _i1.SerializableModel {
  RegistroTempo._({
    this.id,
    required this.demandaId,
    required this.inicioEm,
    required this.duracaoMinutos,
    this.observacao,
    this.observacoesOriginais,
    required this.criadoEm,
  });

  factory RegistroTempo({
    int? id,
    required int demandaId,
    required DateTime inicioEm,
    required int duracaoMinutos,
    String? observacao,
    List<_i2.RegistroTempoObservacao>? observacoesOriginais,
    required DateTime criadoEm,
  }) = _RegistroTempoImpl;

  factory RegistroTempo.fromJson(Map<String, dynamic> jsonSerialization) {
    return RegistroTempo(
      id: jsonSerialization['id'] as int?,
      demandaId: jsonSerialization['demandaId'] as int,
      inicioEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['inicioEm'],
      ),
      duracaoMinutos: jsonSerialization['duracaoMinutos'] as int,
      observacao: jsonSerialization['observacao'] as String?,
      observacoesOriginais: jsonSerialization['observacoesOriginais'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.RegistroTempoObservacao>>(
              jsonSerialization['observacoesOriginais'],
            ),
      criadoEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['criadoEm'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int demandaId;

  DateTime inicioEm;

  int duracaoMinutos;

  String? observacao;

  List<_i2.RegistroTempoObservacao>? observacoesOriginais;

  DateTime criadoEm;

  /// Returns a shallow copy of this [RegistroTempo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RegistroTempo copyWith({
    int? id,
    int? demandaId,
    DateTime? inicioEm,
    int? duracaoMinutos,
    String? observacao,
    List<_i2.RegistroTempoObservacao>? observacoesOriginais,
    DateTime? criadoEm,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RegistroTempo',
      if (id != null) 'id': id,
      'demandaId': demandaId,
      'inicioEm': inicioEm.toJson(),
      'duracaoMinutos': duracaoMinutos,
      if (observacao != null) 'observacao': observacao,
      if (observacoesOriginais != null)
        'observacoesOriginais': observacoesOriginais?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      'criadoEm': criadoEm.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RegistroTempoImpl extends RegistroTempo {
  _RegistroTempoImpl({
    int? id,
    required int demandaId,
    required DateTime inicioEm,
    required int duracaoMinutos,
    String? observacao,
    List<_i2.RegistroTempoObservacao>? observacoesOriginais,
    required DateTime criadoEm,
  }) : super._(
         id: id,
         demandaId: demandaId,
         inicioEm: inicioEm,
         duracaoMinutos: duracaoMinutos,
         observacao: observacao,
         observacoesOriginais: observacoesOriginais,
         criadoEm: criadoEm,
       );

  /// Returns a shallow copy of this [RegistroTempo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RegistroTempo copyWith({
    Object? id = _Undefined,
    int? demandaId,
    DateTime? inicioEm,
    int? duracaoMinutos,
    Object? observacao = _Undefined,
    Object? observacoesOriginais = _Undefined,
    DateTime? criadoEm,
  }) {
    return RegistroTempo(
      id: id is int? ? id : this.id,
      demandaId: demandaId ?? this.demandaId,
      inicioEm: inicioEm ?? this.inicioEm,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
      observacao: observacao is String? ? observacao : this.observacao,
      observacoesOriginais:
          observacoesOriginais is List<_i2.RegistroTempoObservacao>?
          ? observacoesOriginais
          : this.observacoesOriginais?.map((e0) => e0.copyWith()).toList(),
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
