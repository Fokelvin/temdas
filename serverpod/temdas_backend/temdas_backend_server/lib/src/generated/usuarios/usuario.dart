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

abstract class Usuario
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Usuario._({
    this.id,
    required this.supabaseUserId,
    required this.createdAt,
  });

  factory Usuario({
    int? id,
    required String supabaseUserId,
    required DateTime createdAt,
  }) = _UsuarioImpl;

  factory Usuario.fromJson(Map<String, dynamic> jsonSerialization) {
    return Usuario(
      id: jsonSerialization['id'] as int?,
      supabaseUserId: jsonSerialization['supabaseUserId'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = UsuarioTable();

  static const db = UsuarioRepository._();

  @override
  int? id;

  String supabaseUserId;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Usuario]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Usuario copyWith({
    int? id,
    String? supabaseUserId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Usuario',
      if (id != null) 'id': id,
      'supabaseUserId': supabaseUserId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Usuario',
      if (id != null) 'id': id,
      'supabaseUserId': supabaseUserId,
      'createdAt': createdAt.toJson(),
    };
  }

  static UsuarioInclude include() {
    return UsuarioInclude._();
  }

  static UsuarioIncludeList includeList({
    _i1.WhereExpressionBuilder<UsuarioTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UsuarioTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UsuarioTable>? orderByList,
    UsuarioInclude? include,
  }) {
    return UsuarioIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Usuario.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Usuario.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UsuarioImpl extends Usuario {
  _UsuarioImpl({
    int? id,
    required String supabaseUserId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         supabaseUserId: supabaseUserId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Usuario]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Usuario copyWith({
    Object? id = _Undefined,
    String? supabaseUserId,
    DateTime? createdAt,
  }) {
    return Usuario(
      id: id is int? ? id : this.id,
      supabaseUserId: supabaseUserId ?? this.supabaseUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UsuarioUpdateTable extends _i1.UpdateTable<UsuarioTable> {
  UsuarioUpdateTable(super.table);

  _i1.ColumnValue<String, String> supabaseUserId(String value) =>
      _i1.ColumnValue(
        table.supabaseUserId,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class UsuarioTable extends _i1.Table<int?> {
  UsuarioTable({super.tableRelation}) : super(tableName: 'usuarios') {
    updateTable = UsuarioUpdateTable(this);
    supabaseUserId = _i1.ColumnString(
      'supabaseUserId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final UsuarioUpdateTable updateTable;

  late final _i1.ColumnString supabaseUserId;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    supabaseUserId,
    createdAt,
  ];
}

class UsuarioInclude extends _i1.IncludeObject {
  UsuarioInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Usuario.t;
}

class UsuarioIncludeList extends _i1.IncludeList {
  UsuarioIncludeList._({
    _i1.WhereExpressionBuilder<UsuarioTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Usuario.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Usuario.t;
}

class UsuarioRepository {
  const UsuarioRepository._();

  /// Returns a list of [Usuario]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Usuario>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UsuarioTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UsuarioTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UsuarioTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Usuario>(
      where: where?.call(Usuario.t),
      orderBy: orderBy?.call(Usuario.t),
      orderByList: orderByList?.call(Usuario.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Usuario] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Usuario?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UsuarioTable>? where,
    int? offset,
    _i1.OrderByBuilder<UsuarioTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UsuarioTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Usuario>(
      where: where?.call(Usuario.t),
      orderBy: orderBy?.call(Usuario.t),
      orderByList: orderByList?.call(Usuario.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Usuario] by its [id] or null if no such row exists.
  Future<Usuario?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Usuario>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Usuario]s in the list and returns the inserted rows.
  ///
  /// The returned [Usuario]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Usuario>> insert(
    _i1.DatabaseSession session,
    List<Usuario> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Usuario>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Usuario] and returns the inserted row.
  ///
  /// The returned [Usuario] will have its `id` field set.
  Future<Usuario> insertRow(
    _i1.DatabaseSession session,
    Usuario row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Usuario>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Usuario]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Usuario>> update(
    _i1.DatabaseSession session,
    List<Usuario> rows, {
    _i1.ColumnSelections<UsuarioTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Usuario>(
      rows,
      columns: columns?.call(Usuario.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Usuario]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Usuario> updateRow(
    _i1.DatabaseSession session,
    Usuario row, {
    _i1.ColumnSelections<UsuarioTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Usuario>(
      row,
      columns: columns?.call(Usuario.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Usuario] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Usuario?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<UsuarioUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Usuario>(
      id,
      columnValues: columnValues(Usuario.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Usuario]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Usuario>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<UsuarioUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<UsuarioTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UsuarioTable>? orderBy,
    _i1.OrderByListBuilder<UsuarioTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Usuario>(
      columnValues: columnValues(Usuario.t.updateTable),
      where: where(Usuario.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Usuario.t),
      orderByList: orderByList?.call(Usuario.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Usuario]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Usuario>> delete(
    _i1.DatabaseSession session,
    List<Usuario> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Usuario>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Usuario].
  Future<Usuario> deleteRow(
    _i1.DatabaseSession session,
    Usuario row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Usuario>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Usuario>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<UsuarioTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Usuario>(
      where: where(Usuario.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UsuarioTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Usuario>(
      where: where?.call(Usuario.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Usuario] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<UsuarioTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Usuario>(
      where: where(Usuario.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
