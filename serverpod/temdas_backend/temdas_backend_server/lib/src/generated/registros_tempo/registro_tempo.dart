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

abstract class RegistroTempo
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  RegistroTempo._({
    this.id,
    required this.demandaId,
    required this.inicioEm,
    required this.duracaoMinutos,
    required this.criadoEm,
  });

  factory RegistroTempo({
    int? id,
    required int demandaId,
    required DateTime inicioEm,
    required int duracaoMinutos,
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
      criadoEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['criadoEm'],
      ),
    );
  }

  static final t = RegistroTempoTable();

  static const db = RegistroTempoRepository._();

  @override
  int? id;

  int demandaId;

  DateTime inicioEm;

  int duracaoMinutos;

  DateTime criadoEm;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [RegistroTempo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RegistroTempo copyWith({
    int? id,
    int? demandaId,
    DateTime? inicioEm,
    int? duracaoMinutos,
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
      'criadoEm': criadoEm.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RegistroTempo',
      if (id != null) 'id': id,
      'demandaId': demandaId,
      'inicioEm': inicioEm.toJson(),
      'duracaoMinutos': duracaoMinutos,
      'criadoEm': criadoEm.toJson(),
    };
  }

  static RegistroTempoInclude include() {
    return RegistroTempoInclude._();
  }

  static RegistroTempoIncludeList includeList({
    _i1.WhereExpressionBuilder<RegistroTempoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RegistroTempoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<RegistroTempoTable>? orderByList,
    RegistroTempoInclude? include,
  }) {
    return RegistroTempoIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RegistroTempo.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(RegistroTempo.t),
      include: include,
    );
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
    required DateTime criadoEm,
  }) : super._(
         id: id,
         demandaId: demandaId,
         inicioEm: inicioEm,
         duracaoMinutos: duracaoMinutos,
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
    DateTime? criadoEm,
  }) {
    return RegistroTempo(
      id: id is int? ? id : this.id,
      demandaId: demandaId ?? this.demandaId,
      inicioEm: inicioEm ?? this.inicioEm,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}

class RegistroTempoUpdateTable extends _i1.UpdateTable<RegistroTempoTable> {
  RegistroTempoUpdateTable(super.table);

  _i1.ColumnValue<int, int> demandaId(int value) => _i1.ColumnValue(
    table.demandaId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> inicioEm(DateTime value) =>
      _i1.ColumnValue(
        table.inicioEm,
        value,
      );

  _i1.ColumnValue<int, int> duracaoMinutos(int value) => _i1.ColumnValue(
    table.duracaoMinutos,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> criadoEm(DateTime value) =>
      _i1.ColumnValue(
        table.criadoEm,
        value,
      );
}

class RegistroTempoTable extends _i1.Table<int?> {
  RegistroTempoTable({super.tableRelation})
    : super(tableName: 'registros_tempo') {
    updateTable = RegistroTempoUpdateTable(this);
    demandaId = _i1.ColumnInt(
      'demandaId',
      this,
    );
    inicioEm = _i1.ColumnDateTime(
      'inicioEm',
      this,
    );
    duracaoMinutos = _i1.ColumnInt(
      'duracaoMinutos',
      this,
    );
    criadoEm = _i1.ColumnDateTime(
      'criadoEm',
      this,
    );
  }

  late final RegistroTempoUpdateTable updateTable;

  late final _i1.ColumnInt demandaId;

  late final _i1.ColumnDateTime inicioEm;

  late final _i1.ColumnInt duracaoMinutos;

  late final _i1.ColumnDateTime criadoEm;

  @override
  List<_i1.Column> get columns => [
    id,
    demandaId,
    inicioEm,
    duracaoMinutos,
    criadoEm,
  ];
}

class RegistroTempoInclude extends _i1.IncludeObject {
  RegistroTempoInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => RegistroTempo.t;
}

class RegistroTempoIncludeList extends _i1.IncludeList {
  RegistroTempoIncludeList._({
    _i1.WhereExpressionBuilder<RegistroTempoTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RegistroTempo.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => RegistroTempo.t;
}

class RegistroTempoRepository {
  const RegistroTempoRepository._();

  /// Returns a list of [RegistroTempo]s matching the given query parameters.
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
  Future<List<RegistroTempo>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<RegistroTempoTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RegistroTempoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<RegistroTempoTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<RegistroTempo>(
      where: where?.call(RegistroTempo.t),
      orderBy: orderBy?.call(RegistroTempo.t),
      orderByList: orderByList?.call(RegistroTempo.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [RegistroTempo] matching the given query parameters.
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
  Future<RegistroTempo?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<RegistroTempoTable>? where,
    int? offset,
    _i1.OrderByBuilder<RegistroTempoTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<RegistroTempoTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<RegistroTempo>(
      where: where?.call(RegistroTempo.t),
      orderBy: orderBy?.call(RegistroTempo.t),
      orderByList: orderByList?.call(RegistroTempo.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [RegistroTempo] by its [id] or null if no such row exists.
  Future<RegistroTempo?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<RegistroTempo>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [RegistroTempo]s in the list and returns the inserted rows.
  ///
  /// The returned [RegistroTempo]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<RegistroTempo>> insert(
    _i1.DatabaseSession session,
    List<RegistroTempo> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<RegistroTempo>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [RegistroTempo] and returns the inserted row.
  ///
  /// The returned [RegistroTempo] will have its `id` field set.
  Future<RegistroTempo> insertRow(
    _i1.DatabaseSession session,
    RegistroTempo row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<RegistroTempo>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [RegistroTempo]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<RegistroTempo>> update(
    _i1.DatabaseSession session,
    List<RegistroTempo> rows, {
    _i1.ColumnSelections<RegistroTempoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<RegistroTempo>(
      rows,
      columns: columns?.call(RegistroTempo.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RegistroTempo]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RegistroTempo> updateRow(
    _i1.DatabaseSession session,
    RegistroTempo row, {
    _i1.ColumnSelections<RegistroTempoTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<RegistroTempo>(
      row,
      columns: columns?.call(RegistroTempo.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RegistroTempo] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RegistroTempo?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<RegistroTempoUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<RegistroTempo>(
      id,
      columnValues: columnValues(RegistroTempo.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RegistroTempo]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<RegistroTempo>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<RegistroTempoUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<RegistroTempoTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<RegistroTempoTable>? orderBy,
    _i1.OrderByListBuilder<RegistroTempoTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<RegistroTempo>(
      columnValues: columnValues(RegistroTempo.t.updateTable),
      where: where(RegistroTempo.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RegistroTempo.t),
      orderByList: orderByList?.call(RegistroTempo.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [RegistroTempo]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<RegistroTempo>> delete(
    _i1.DatabaseSession session,
    List<RegistroTempo> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<RegistroTempo>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [RegistroTempo].
  Future<RegistroTempo> deleteRow(
    _i1.DatabaseSession session,
    RegistroTempo row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RegistroTempo>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<RegistroTempo>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<RegistroTempoTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<RegistroTempo>(
      where: where(RegistroTempo.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<RegistroTempoTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<RegistroTempo>(
      where: where?.call(RegistroTempo.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [RegistroTempo] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<RegistroTempoTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<RegistroTempo>(
      where: where(RegistroTempo.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
