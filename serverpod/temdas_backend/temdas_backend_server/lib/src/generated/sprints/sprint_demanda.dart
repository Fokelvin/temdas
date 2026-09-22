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

abstract class SprintDemanda
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  SprintDemanda._({
    this.id,
    required this.sprintId,
    required this.demandaId,
  });

  factory SprintDemanda({
    int? id,
    required int sprintId,
    required int demandaId,
  }) = _SprintDemandaImpl;

  factory SprintDemanda.fromJson(Map<String, dynamic> jsonSerialization) {
    return SprintDemanda(
      id: jsonSerialization['id'] as int?,
      sprintId: jsonSerialization['sprintId'] as int,
      demandaId: jsonSerialization['demandaId'] as int,
    );
  }

  static final t = SprintDemandaTable();

  static const db = SprintDemandaRepository._();

  @override
  int? id;

  int sprintId;

  int demandaId;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [SprintDemanda]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SprintDemanda copyWith({
    int? id,
    int? sprintId,
    int? demandaId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SprintDemanda',
      if (id != null) 'id': id,
      'sprintId': sprintId,
      'demandaId': demandaId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SprintDemanda',
      if (id != null) 'id': id,
      'sprintId': sprintId,
      'demandaId': demandaId,
    };
  }

  static SprintDemandaInclude include() {
    return SprintDemandaInclude._();
  }

  static SprintDemandaIncludeList includeList({
    _i1.WhereExpressionBuilder<SprintDemandaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SprintDemandaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SprintDemandaTable>? orderByList,
    SprintDemandaInclude? include,
  }) {
    return SprintDemandaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SprintDemanda.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SprintDemanda.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SprintDemandaImpl extends SprintDemanda {
  _SprintDemandaImpl({
    int? id,
    required int sprintId,
    required int demandaId,
  }) : super._(
         id: id,
         sprintId: sprintId,
         demandaId: demandaId,
       );

  /// Returns a shallow copy of this [SprintDemanda]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SprintDemanda copyWith({
    Object? id = _Undefined,
    int? sprintId,
    int? demandaId,
  }) {
    return SprintDemanda(
      id: id is int? ? id : this.id,
      sprintId: sprintId ?? this.sprintId,
      demandaId: demandaId ?? this.demandaId,
    );
  }
}

class SprintDemandaUpdateTable extends _i1.UpdateTable<SprintDemandaTable> {
  SprintDemandaUpdateTable(super.table);

  _i1.ColumnValue<int, int> sprintId(int value) => _i1.ColumnValue(
    table.sprintId,
    value,
  );

  _i1.ColumnValue<int, int> demandaId(int value) => _i1.ColumnValue(
    table.demandaId,
    value,
  );
}

class SprintDemandaTable extends _i1.Table<int?> {
  SprintDemandaTable({super.tableRelation})
    : super(tableName: 'sprints_demandas') {
    updateTable = SprintDemandaUpdateTable(this);
    sprintId = _i1.ColumnInt(
      'sprintId',
      this,
    );
    demandaId = _i1.ColumnInt(
      'demandaId',
      this,
    );
  }

  late final SprintDemandaUpdateTable updateTable;

  late final _i1.ColumnInt sprintId;

  late final _i1.ColumnInt demandaId;

  @override
  List<_i1.Column> get columns => [
    id,
    sprintId,
    demandaId,
  ];
}

class SprintDemandaInclude extends _i1.IncludeObject {
  SprintDemandaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => SprintDemanda.t;
}

class SprintDemandaIncludeList extends _i1.IncludeList {
  SprintDemandaIncludeList._({
    _i1.WhereExpressionBuilder<SprintDemandaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SprintDemanda.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => SprintDemanda.t;
}

class SprintDemandaRepository {
  const SprintDemandaRepository._();

  /// Returns a list of [SprintDemanda]s matching the given query parameters.
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
  Future<List<SprintDemanda>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SprintDemandaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SprintDemandaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SprintDemandaTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SprintDemanda>(
      where: where?.call(SprintDemanda.t),
      orderBy: orderBy?.call(SprintDemanda.t),
      orderByList: orderByList?.call(SprintDemanda.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SprintDemanda] matching the given query parameters.
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
  Future<SprintDemanda?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SprintDemandaTable>? where,
    int? offset,
    _i1.OrderByBuilder<SprintDemandaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SprintDemandaTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SprintDemanda>(
      where: where?.call(SprintDemanda.t),
      orderBy: orderBy?.call(SprintDemanda.t),
      orderByList: orderByList?.call(SprintDemanda.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SprintDemanda] by its [id] or null if no such row exists.
  Future<SprintDemanda?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SprintDemanda>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SprintDemanda]s in the list and returns the inserted rows.
  ///
  /// The returned [SprintDemanda]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<SprintDemanda>> insert(
    _i1.DatabaseSession session,
    List<SprintDemanda> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<SprintDemanda>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [SprintDemanda] and returns the inserted row.
  ///
  /// The returned [SprintDemanda] will have its `id` field set.
  Future<SprintDemanda> insertRow(
    _i1.DatabaseSession session,
    SprintDemanda row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SprintDemanda>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SprintDemanda]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SprintDemanda>> update(
    _i1.DatabaseSession session,
    List<SprintDemanda> rows, {
    _i1.ColumnSelections<SprintDemandaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SprintDemanda>(
      rows,
      columns: columns?.call(SprintDemanda.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SprintDemanda]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SprintDemanda> updateRow(
    _i1.DatabaseSession session,
    SprintDemanda row, {
    _i1.ColumnSelections<SprintDemandaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SprintDemanda>(
      row,
      columns: columns?.call(SprintDemanda.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SprintDemanda] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SprintDemanda?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<SprintDemandaUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SprintDemanda>(
      id,
      columnValues: columnValues(SprintDemanda.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SprintDemanda]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SprintDemanda>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SprintDemandaUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SprintDemandaTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SprintDemandaTable>? orderBy,
    _i1.OrderByListBuilder<SprintDemandaTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SprintDemanda>(
      columnValues: columnValues(SprintDemanda.t.updateTable),
      where: where(SprintDemanda.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SprintDemanda.t),
      orderByList: orderByList?.call(SprintDemanda.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SprintDemanda]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SprintDemanda>> delete(
    _i1.DatabaseSession session,
    List<SprintDemanda> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SprintDemanda>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SprintDemanda].
  Future<SprintDemanda> deleteRow(
    _i1.DatabaseSession session,
    SprintDemanda row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SprintDemanda>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SprintDemanda>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SprintDemandaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SprintDemanda>(
      where: where(SprintDemanda.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SprintDemandaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SprintDemanda>(
      where: where?.call(SprintDemanda.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SprintDemanda] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SprintDemandaTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SprintDemanda>(
      where: where(SprintDemanda.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
