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
import '../todos/todo_tipo_linha.dart' as _i2;

abstract class TodoLinha implements _i1.SerializableModel {
  TodoLinha._({
    required this.id,
    required this.tipo,
    required this.texto,
    required this.marcado,
  });

  factory TodoLinha({
    required String id,
    required _i2.TodoTipoLinha tipo,
    required String texto,
    required bool marcado,
  }) = _TodoLinhaImpl;

  factory TodoLinha.fromJson(Map<String, dynamic> jsonSerialization) {
    return TodoLinha(
      id: jsonSerialization['id'] as String,
      tipo: _i2.TodoTipoLinha.fromJson((jsonSerialization['tipo'] as String)),
      texto: jsonSerialization['texto'] as String,
      marcado: _i1.BoolJsonExtension.fromJson(jsonSerialization['marcado']),
    );
  }

  String id;

  _i2.TodoTipoLinha tipo;

  String texto;

  bool marcado;

  /// Returns a shallow copy of this [TodoLinha]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TodoLinha copyWith({
    String? id,
    _i2.TodoTipoLinha? tipo,
    String? texto,
    bool? marcado,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TodoLinha',
      'id': id,
      'tipo': tipo.toJson(),
      'texto': texto,
      'marcado': marcado,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TodoLinhaImpl extends TodoLinha {
  _TodoLinhaImpl({
    required String id,
    required _i2.TodoTipoLinha tipo,
    required String texto,
    required bool marcado,
  }) : super._(
         id: id,
         tipo: tipo,
         texto: texto,
         marcado: marcado,
       );

  /// Returns a shallow copy of this [TodoLinha]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TodoLinha copyWith({
    String? id,
    _i2.TodoTipoLinha? tipo,
    String? texto,
    bool? marcado,
  }) {
    return TodoLinha(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      texto: texto ?? this.texto,
      marcado: marcado ?? this.marcado,
    );
  }
}
