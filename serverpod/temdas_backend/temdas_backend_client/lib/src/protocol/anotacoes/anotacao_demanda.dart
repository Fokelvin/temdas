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

abstract class AnotacaoDemanda implements _i1.SerializableModel {
  AnotacaoDemanda._({
    this.id,
    required this.demandaId,
    required this.autorId,
    required this.conteudo,
    required this.criadoEm,
    this.editadoEm,
    this.excluidoEm,
  });

  factory AnotacaoDemanda({
    int? id,
    required int demandaId,
    required int autorId,
    required String conteudo,
    required DateTime criadoEm,
    DateTime? editadoEm,
    DateTime? excluidoEm,
  }) = _AnotacaoDemandaImpl;

  factory AnotacaoDemanda.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnotacaoDemanda(
      id: jsonSerialization['id'] as int?,
      demandaId: jsonSerialization['demandaId'] as int,
      autorId: jsonSerialization['autorId'] as int,
      conteudo: jsonSerialization['conteudo'] as String,
      criadoEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['criadoEm'],
      ),
      editadoEm: jsonSerialization['editadoEm'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['editadoEm']),
      excluidoEm: jsonSerialization['excluidoEm'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['excluidoEm']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int demandaId;

  int autorId;

  String conteudo;

  DateTime criadoEm;

  DateTime? editadoEm;

  DateTime? excluidoEm;

  /// Returns a shallow copy of this [AnotacaoDemanda]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AnotacaoDemanda copyWith({
    int? id,
    int? demandaId,
    int? autorId,
    String? conteudo,
    DateTime? criadoEm,
    DateTime? editadoEm,
    DateTime? excluidoEm,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnotacaoDemanda',
      if (id != null) 'id': id,
      'demandaId': demandaId,
      'autorId': autorId,
      'conteudo': conteudo,
      'criadoEm': criadoEm.toJson(),
      if (editadoEm != null) 'editadoEm': editadoEm?.toJson(),
      if (excluidoEm != null) 'excluidoEm': excluidoEm?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AnotacaoDemandaImpl extends AnotacaoDemanda {
  _AnotacaoDemandaImpl({
    int? id,
    required int demandaId,
    required int autorId,
    required String conteudo,
    required DateTime criadoEm,
    DateTime? editadoEm,
    DateTime? excluidoEm,
  }) : super._(
         id: id,
         demandaId: demandaId,
         autorId: autorId,
         conteudo: conteudo,
         criadoEm: criadoEm,
         editadoEm: editadoEm,
         excluidoEm: excluidoEm,
       );

  /// Returns a shallow copy of this [AnotacaoDemanda]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AnotacaoDemanda copyWith({
    Object? id = _Undefined,
    int? demandaId,
    int? autorId,
    String? conteudo,
    DateTime? criadoEm,
    Object? editadoEm = _Undefined,
    Object? excluidoEm = _Undefined,
  }) {
    return AnotacaoDemanda(
      id: id is int? ? id : this.id,
      demandaId: demandaId ?? this.demandaId,
      autorId: autorId ?? this.autorId,
      conteudo: conteudo ?? this.conteudo,
      criadoEm: criadoEm ?? this.criadoEm,
      editadoEm: editadoEm is DateTime? ? editadoEm : this.editadoEm,
      excluidoEm: excluidoEm is DateTime? ? excluidoEm : this.excluidoEm,
    );
  }
}
