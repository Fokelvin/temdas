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

abstract class AnotacaoDemanda
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = AnotacaoDemandaTable();

  static const db = AnotacaoDemandaRepository._();

  @override
  int? id;

  int demandaId;

  int autorId;

  String conteudo;

  DateTime criadoEm;

  DateTime? editadoEm;

  DateTime? excluidoEm;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static AnotacaoDemandaInclude include() {
    return AnotacaoDemandaInclude._();
  }

  static AnotacaoDemandaIncludeList includeList({
    _i1.WhereExpressionBuilder<AnotacaoDemandaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AnotacaoDemandaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AnotacaoDemandaTable>? orderByList,
    AnotacaoDemandaInclude? include,
  }) {
    return AnotacaoDemandaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AnotacaoDemanda.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AnotacaoDemanda.t),
      include: include,
    );
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

class AnotacaoDemandaUpdateTable extends _i1.UpdateTable<AnotacaoDemandaTable> {
  AnotacaoDemandaUpdateTable(super.table);

  _i1.ColumnValue<int, int> demandaId(int value) => _i1.ColumnValue(
    table.demandaId,
    value,
  );

  _i1.ColumnValue<int, int> autorId(int value) => _i1.ColumnValue(
    table.autorId,
    value,
  );

  _i1.ColumnValue<String, String> conteudo(String value) => _i1.ColumnValue(
    table.conteudo,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> criadoEm(DateTime value) =>
      _i1.ColumnValue(
        table.criadoEm,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> editadoEm(DateTime? value) =>
      _i1.ColumnValue(
        table.editadoEm,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> excluidoEm(DateTime? value) =>
      _i1.ColumnValue(
        table.excluidoEm,
        value,
      );
}

class AnotacaoDemandaTable extends _i1.Table<int?> {
  AnotacaoDemandaTable({super.tableRelation})
    : super(tableName: 'anotacoes_demanda') {
    updateTable = AnotacaoDemandaUpdateTable(this);
    demandaId = _i1.ColumnInt(
      'demandaId',
      this,
    );
    autorId = _i1.ColumnInt(
      'autorId',
      this,
    );
    conteudo = _i1.ColumnString(
      'conteudo',
      this,
    );
    criadoEm = _i1.ColumnDateTime(
      'criadoEm',
      this,
    );
    editadoEm = _i1.ColumnDateTime(
      'editadoEm',
      this,
    );
    excluidoEm = _i1.ColumnDateTime(
      'excluidoEm',
      this,
    );
  }

  late final AnotacaoDemandaUpdateTable updateTable;

  late final _i1.ColumnInt demandaId;

  late final _i1.ColumnInt autorId;

  late final _i1.ColumnString conteudo;

  late final _i1.ColumnDateTime criadoEm;

  late final _i1.ColumnDateTime editadoEm;

  late final _i1.ColumnDateTime excluidoEm;

  @override
  List<_i1.Column> get columns => [
    id,
    demandaId,
    autorId,
    conteudo,
    criadoEm,
    editadoEm,
    excluidoEm,
  ];
}

class AnotacaoDemandaInclude extends _i1.IncludeObject {
  AnotacaoDemandaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => AnotacaoDemanda.t;
}

class AnotacaoDemandaIncludeList extends _i1.IncludeList {
  AnotacaoDemandaIncludeList._({
    _i1.WhereExpressionBuilder<AnotacaoDemandaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AnotacaoDemanda.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => AnotacaoDemanda.t;
}

class AnotacaoDemandaRepository {
  const AnotacaoDemandaRepository._();

  /// Returns a list of [AnotacaoDemanda]s matching the given query parameters.
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
  Future<List<AnotacaoDemanda>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AnotacaoDemandaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AnotacaoDemandaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AnotacaoDemandaTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AnotacaoDemanda>(
      where: where?.call(AnotacaoDemanda.t),
      orderBy: orderBy?.call(AnotacaoDemanda.t),
      orderByList: orderByList?.call(AnotacaoDemanda.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AnotacaoDemanda] matching the given query parameters.
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
  Future<AnotacaoDemanda?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AnotacaoDemandaTable>? where,
    int? offset,
    _i1.OrderByBuilder<AnotacaoDemandaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AnotacaoDemandaTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AnotacaoDemanda>(
      where: where?.call(AnotacaoDemanda.t),
      orderBy: orderBy?.call(AnotacaoDemanda.t),
      orderByList: orderByList?.call(AnotacaoDemanda.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AnotacaoDemanda] by its [id] or null if no such row exists.
  Future<AnotacaoDemanda?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AnotacaoDemanda>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AnotacaoDemanda]s in the list and returns the inserted rows.
  ///
  /// The returned [AnotacaoDemanda]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<AnotacaoDemanda>> insert(
    _i1.DatabaseSession session,
    List<AnotacaoDemanda> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<AnotacaoDemanda>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [AnotacaoDemanda] and returns the inserted row.
  ///
  /// The returned [AnotacaoDemanda] will have its `id` field set.
  Future<AnotacaoDemanda> insertRow(
    _i1.DatabaseSession session,
    AnotacaoDemanda row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AnotacaoDemanda>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [AnotacaoDemanda]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AnotacaoDemanda>> update(
    _i1.DatabaseSession session,
    List<AnotacaoDemanda> rows, {
    _i1.ColumnSelections<AnotacaoDemandaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AnotacaoDemanda>(
      rows,
      columns: columns?.call(AnotacaoDemanda.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AnotacaoDemanda]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AnotacaoDemanda> updateRow(
    _i1.DatabaseSession session,
    AnotacaoDemanda row, {
    _i1.ColumnSelections<AnotacaoDemandaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<AnotacaoDemanda>(
      row,
      columns: columns?.call(AnotacaoDemanda.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AnotacaoDemanda] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AnotacaoDemanda?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<AnotacaoDemandaUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AnotacaoDemanda>(
      id,
      columnValues: columnValues(AnotacaoDemanda.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AnotacaoDemanda]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AnotacaoDemanda>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<AnotacaoDemandaUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<AnotacaoDemandaTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AnotacaoDemandaTable>? orderBy,
    _i1.OrderByListBuilder<AnotacaoDemandaTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AnotacaoDemanda>(
      columnValues: columnValues(AnotacaoDemanda.t.updateTable),
      where: where(AnotacaoDemanda.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AnotacaoDemanda.t),
      orderByList: orderByList?.call(AnotacaoDemanda.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AnotacaoDemanda]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AnotacaoDemanda>> delete(
    _i1.DatabaseSession session,
    List<AnotacaoDemanda> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AnotacaoDemanda>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [AnotacaoDemanda].
  Future<AnotacaoDemanda> deleteRow(
    _i1.DatabaseSession session,
    AnotacaoDemanda row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AnotacaoDemanda>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AnotacaoDemanda>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AnotacaoDemandaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AnotacaoDemanda>(
      where: where(AnotacaoDemanda.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AnotacaoDemandaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AnotacaoDemanda>(
      where: where?.call(AnotacaoDemanda.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AnotacaoDemanda] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AnotacaoDemandaTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AnotacaoDemanda>(
      where: where(AnotacaoDemanda.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
