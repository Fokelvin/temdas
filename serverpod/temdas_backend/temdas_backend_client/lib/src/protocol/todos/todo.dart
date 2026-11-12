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
import '../todos/todo_linha.dart' as _i2;
import 'package:temdas_backend_client/src/protocol/protocol.dart' as _i3;

abstract class Todo implements _i1.SerializableModel {
  Todo._({
    this.id,
    required this.usuarioId,
    this.demandaId,
    required this.conteudo,
    this.linhas,
    this.data,
    bool? concluido,
    required this.criadoEm,
    this.posicao,
    double? largura,
    double? altura,
  }) : concluido = concluido ?? false,
       largura = largura ?? 232.0,
       altura = altura ?? 232.0;

  factory Todo({
    int? id,
    required int usuarioId,
    int? demandaId,
    required String conteudo,
    List<_i2.TodoLinha>? linhas,
    String? data,
    bool? concluido,
    required DateTime criadoEm,
    int? posicao,
    double? largura,
    double? altura,
  }) = _TodoImpl;

  factory Todo.fromJson(Map<String, dynamic> jsonSerialization) {
    return Todo(
      id: jsonSerialization['id'] as int?,
      usuarioId: jsonSerialization['usuarioId'] as int,
      demandaId: jsonSerialization['demandaId'] as int?,
      conteudo: jsonSerialization['conteudo'] as String,
      linhas: jsonSerialization['linhas'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.TodoLinha>>(
              jsonSerialization['linhas'],
            ),
      data: jsonSerialization['data'] as String?,
      concluido: jsonSerialization['concluido'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['concluido']),
      criadoEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['criadoEm'],
      ),
      posicao: jsonSerialization['posicao'] as int?,
      largura: (jsonSerialization['largura'] as num?)?.toDouble(),
      altura: (jsonSerialization['altura'] as num?)?.toDouble(),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int usuarioId;

  int? demandaId;

  String conteudo;

  List<_i2.TodoLinha>? linhas;

  String? data;

  bool concluido;

  DateTime criadoEm;

  int? posicao;

  double largura;

  double altura;

  /// Returns a shallow copy of this [Todo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Todo copyWith({
    int? id,
    int? usuarioId,
    int? demandaId,
    String? conteudo,
    List<_i2.TodoLinha>? linhas,
    String? data,
    bool? concluido,
    DateTime? criadoEm,
    int? posicao,
    double? largura,
    double? altura,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Todo',
      if (id != null) 'id': id,
      'usuarioId': usuarioId,
      if (demandaId != null) 'demandaId': demandaId,
      'conteudo': conteudo,
      if (linhas != null)
        'linhas': linhas?.toJson(valueToJson: (v) => v.toJson()),
      if (data != null) 'data': data,
      'concluido': concluido,
      'criadoEm': criadoEm.toJson(),
      if (posicao != null) 'posicao': posicao,
      'largura': largura,
      'altura': altura,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TodoImpl extends Todo {
  _TodoImpl({
    int? id,
    required int usuarioId,
    int? demandaId,
    required String conteudo,
    List<_i2.TodoLinha>? linhas,
    String? data,
    bool? concluido,
    required DateTime criadoEm,
    int? posicao,
    double? largura,
    double? altura,
  }) : super._(
         id: id,
         usuarioId: usuarioId,
         demandaId: demandaId,
         conteudo: conteudo,
         linhas: linhas,
         data: data,
         concluido: concluido,
         criadoEm: criadoEm,
         posicao: posicao,
         largura: largura,
         altura: altura,
       );

  /// Returns a shallow copy of this [Todo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Todo copyWith({
    Object? id = _Undefined,
    int? usuarioId,
    Object? demandaId = _Undefined,
    String? conteudo,
    Object? linhas = _Undefined,
    Object? data = _Undefined,
    bool? concluido,
    DateTime? criadoEm,
    Object? posicao = _Undefined,
    double? largura,
    double? altura,
  }) {
    return Todo(
      id: id is int? ? id : this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      demandaId: demandaId is int? ? demandaId : this.demandaId,
      conteudo: conteudo ?? this.conteudo,
      linhas: linhas is List<_i2.TodoLinha>?
          ? linhas
          : this.linhas?.map((e0) => e0.copyWith()).toList(),
      data: data is String? ? data : this.data,
      concluido: concluido ?? this.concluido,
      criadoEm: criadoEm ?? this.criadoEm,
      posicao: posicao is int? ? posicao : this.posicao,
      largura: largura ?? this.largura,
      altura: altura ?? this.altura,
    );
  }
}
