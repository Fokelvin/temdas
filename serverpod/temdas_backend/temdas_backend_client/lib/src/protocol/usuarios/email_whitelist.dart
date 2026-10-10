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

abstract class EmailWhitelist implements _i1.SerializableModel {
  EmailWhitelist._({
    this.id,
    required this.emailNormalizado,
    this.utilizadoEm,
    this.ultimoConviteEm,
    this.conviteReservaId,
    this.conviteReservadoAte,
    required this.createdAt,
  });

  factory EmailWhitelist({
    int? id,
    required String emailNormalizado,
    DateTime? utilizadoEm,
    DateTime? ultimoConviteEm,
    String? conviteReservaId,
    DateTime? conviteReservadoAte,
    required DateTime createdAt,
  }) = _EmailWhitelistImpl;

  factory EmailWhitelist.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmailWhitelist(
      id: jsonSerialization['id'] as int?,
      emailNormalizado: jsonSerialization['emailNormalizado'] as String,
      utilizadoEm: jsonSerialization['utilizadoEm'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['utilizadoEm'],
            ),
      ultimoConviteEm: jsonSerialization['ultimoConviteEm'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['ultimoConviteEm'],
            ),
      conviteReservaId: jsonSerialization['conviteReservaId'] as String?,
      conviteReservadoAte: jsonSerialization['conviteReservadoAte'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['conviteReservadoAte'],
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String emailNormalizado;

  DateTime? utilizadoEm;

  DateTime? ultimoConviteEm;

  String? conviteReservaId;

  DateTime? conviteReservadoAte;

  DateTime createdAt;

  /// Returns a shallow copy of this [EmailWhitelist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmailWhitelist copyWith({
    int? id,
    String? emailNormalizado,
    DateTime? utilizadoEm,
    DateTime? ultimoConviteEm,
    String? conviteReservaId,
    DateTime? conviteReservadoAte,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EmailWhitelist',
      if (id != null) 'id': id,
      'emailNormalizado': emailNormalizado,
      if (utilizadoEm != null) 'utilizadoEm': utilizadoEm?.toJson(),
      if (ultimoConviteEm != null) 'ultimoConviteEm': ultimoConviteEm?.toJson(),
      if (conviteReservaId != null) 'conviteReservaId': conviteReservaId,
      if (conviteReservadoAte != null)
        'conviteReservadoAte': conviteReservadoAte?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EmailWhitelistImpl extends EmailWhitelist {
  _EmailWhitelistImpl({
    int? id,
    required String emailNormalizado,
    DateTime? utilizadoEm,
    DateTime? ultimoConviteEm,
    String? conviteReservaId,
    DateTime? conviteReservadoAte,
    required DateTime createdAt,
  }) : super._(
         id: id,
         emailNormalizado: emailNormalizado,
         utilizadoEm: utilizadoEm,
         ultimoConviteEm: ultimoConviteEm,
         conviteReservaId: conviteReservaId,
         conviteReservadoAte: conviteReservadoAte,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [EmailWhitelist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EmailWhitelist copyWith({
    Object? id = _Undefined,
    String? emailNormalizado,
    Object? utilizadoEm = _Undefined,
    Object? ultimoConviteEm = _Undefined,
    Object? conviteReservaId = _Undefined,
    Object? conviteReservadoAte = _Undefined,
    DateTime? createdAt,
  }) {
    return EmailWhitelist(
      id: id is int? ? id : this.id,
      emailNormalizado: emailNormalizado ?? this.emailNormalizado,
      utilizadoEm: utilizadoEm is DateTime? ? utilizadoEm : this.utilizadoEm,
      ultimoConviteEm: ultimoConviteEm is DateTime?
          ? ultimoConviteEm
          : this.ultimoConviteEm,
      conviteReservaId: conviteReservaId is String?
          ? conviteReservaId
          : this.conviteReservaId,
      conviteReservadoAte: conviteReservadoAte is DateTime?
          ? conviteReservadoAte
          : this.conviteReservadoAte,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
