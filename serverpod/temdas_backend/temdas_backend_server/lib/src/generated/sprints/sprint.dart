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
import '../sprints/sprint_status.dart' as _i2;

abstract class Sprint implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Sprint._({
    this.id,
    required this.nome,
    this.nomeNormalizado,
    required this.dataInicio,
    required this.dataFim,
    this.tempoPrevistoMinutos,
    required this.status,
  });

  factory Sprint({
    int? id,
    required String nome,
    String? nomeNormalizado,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
    required _i2.SprintStatus status,
  }) = _SprintImpl;

  factory Sprint.fromJson(Map<String, dynamic> jsonSerialization) {
    return Sprint(
      id: jsonSerialization['id'] as int?,
      nome: jsonSerialization['nome'] as String,
      nomeNormalizado: jsonSerialization['nomeNormalizado'] as String?,
      dataInicio: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['dataInicio'],
      ),
      dataFim: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dataFim']),
      tempoPrevistoMinutos: jsonSerialization['tempoPrevistoMinutos'] as int?,
      status: _i2.SprintStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
    );
  }

  static final t = SprintTable();

  static const db = SprintRepository._();

  @override
  int? id;

  String nome;

  String? nomeNormalizado;

  DateTime dataInicio;

  DateTime dataFim;

  int? tempoPrevistoMinutos;

  _i2.SprintStatus status;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Sprint]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Sprint copyWith({
    int? id,
    String? nome,
    String? nomeNormalizado,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? tempoPrevistoMinutos,
    _i2.SprintStatus? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Sprint',
      if (id != null) 'id': id,
      'nome': nome,
      if (nomeNormalizado != null) 'nomeNormalizado': nomeNormalizado,
      'dataInicio': dataInicio.toJson(),
      'dataFim': dataFim.toJson(),
      if (tempoPrevistoMinutos != null)
        'tempoPrevistoMinutos': tempoPrevistoMinutos,
      'status': status.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Sprint',
      if (id != null) 'id': id,
      'nome': nome,
      'dataInicio': dataInicio.toJson(),
      'dataFim': dataFim.toJson(),
      if (tempoPrevistoMinutos != null)
        'tempoPrevistoMinutos': tempoPrevistoMinutos,
      'status': status.toJson(),
    };
  }

  static SprintInclude include() {
    return SprintInclude._();
  }

  static SprintIncludeList includeList({
    _i1.WhereExpressionBuilder<SprintTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SprintTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SprintTable>? orderByList,
    SprintInclude? include,
  }) {
    return SprintIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Sprint.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Sprint.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SprintImpl extends Sprint {
  _SprintImpl({
    int? id,
    required String nome,
    String? nomeNormalizado,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
    required _i2.SprintStatus status,
  }) : super._(
         id: id,
         nome: nome,
         nomeNormalizado: nomeNormalizado,
         dataInicio: dataInicio,
         dataFim: dataFim,
         tempoPrevistoMinutos: tempoPrevistoMinutos,
         status: status,
       );

  /// Returns a shallow copy of this [Sprint]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Sprint copyWith({
    Object? id = _Undefined,
    String? nome,
    Object? nomeNormalizado = _Undefined,
    DateTime? dataInicio,
    DateTime? dataFim,
    Object? tempoPrevistoMinutos = _Undefined,
    _i2.SprintStatus? status,
  }) {
    return Sprint(
      id: id is int? ? id : this.id,
      nome: nome ?? this.nome,
      nomeNormalizado: nomeNormalizado is String?
          ? nomeNormalizado
          : this.nomeNormalizado,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      tempoPrevistoMinutos: tempoPrevistoMinutos is int?
          ? tempoPrevistoMinutos
          : this.tempoPrevistoMinutos,
      status: status ?? this.status,
    );
  }
}

class SprintUpdateTable extends _i1.UpdateTable<SprintTable> {
  SprintUpdateTable(super.table);

  _i1.ColumnValue<String, String> nome(String value) => _i1.ColumnValue(
    table.nome,
    value,
  );

  _i1.ColumnValue<String, String> nomeNormalizado(String? value) =>
      _i1.ColumnValue(
        table.nomeNormalizado,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> dataInicio(DateTime value) =>
      _i1.ColumnValue(
        table.dataInicio,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> dataFim(DateTime value) =>
      _i1.ColumnValue(
        table.dataFim,
        value,
      );

  _i1.ColumnValue<int, int> tempoPrevistoMinutos(int? value) => _i1.ColumnValue(
    table.tempoPrevistoMinutos,
    value,
  );

  _i1.ColumnValue<_i2.SprintStatus, _i2.SprintStatus> status(
    _i2.SprintStatus value,
  ) => _i1.ColumnValue(
    table.status,
    value,
  );
}

class SprintTable extends _i1.Table<int?> {
  SprintTable({super.tableRelation}) : super(tableName: 'sprints') {
    updateTable = SprintUpdateTable(this);
    nome = _i1.ColumnString(
      'nome',
      this,
    );
    nomeNormalizado = _i1.ColumnString(
      'nomeNormalizado',
      this,
    );
    dataInicio = _i1.ColumnDateTime(
      'dataInicio',
      this,
    );
    dataFim = _i1.ColumnDateTime(
      'dataFim',
      this,
    );
    tempoPrevistoMinutos = _i1.ColumnInt(
      'tempoPrevistoMinutos',
      this,
    );
    status = _i1.ColumnEnum(
      'status',
      this,
      _i1.EnumSerialization.byName,
    );
  }

  late final SprintUpdateTable updateTable;

  late final _i1.ColumnString nome;

  late final _i1.ColumnString nomeNormalizado;

  late final _i1.ColumnDateTime dataInicio;

  late final _i1.ColumnDateTime dataFim;

  late final _i1.ColumnInt tempoPrevistoMinutos;

  late final _i1.ColumnEnum<_i2.SprintStatus> status;

  @override
  List<_i1.Column> get columns => [
    id,
    nome,
    nomeNormalizado,
    dataInicio,
    dataFim,
    tempoPrevistoMinutos,
    status,
  ];
}

class SprintInclude extends _i1.IncludeObject {
  SprintInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Sprint.t;
}

class SprintIncludeList extends _i1.IncludeList {
  SprintIncludeList._({
    _i1.WhereExpressionBuilder<SprintTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Sprint.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Sprint.t;
}

class SprintRepository {
  const SprintRepository._();

  /// Returns a list of [Sprint]s matching the given query parameters.
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
  Future<List<Sprint>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SprintTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SprintTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SprintTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Sprint>(
      where: where?.call(Sprint.t),
      orderBy: orderBy?.call(Sprint.t),
      orderByList: orderByList?.call(Sprint.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Sprint] matching the given query parameters.
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
  Future<Sprint?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SprintTable>? where,
    int? offset,
    _i1.OrderByBuilder<SprintTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SprintTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Sprint>(
      where: where?.call(Sprint.t),
      orderBy: orderBy?.call(Sprint.t),
      orderByList: orderByList?.call(Sprint.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Sprint] by its [id] or null if no such row exists.
  Future<Sprint?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Sprint>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Sprint]s in the list and returns the inserted rows.
  ///
  /// The returned [Sprint]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Sprint>> insert(
    _i1.DatabaseSession session,
    List<Sprint> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Sprint>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Sprint] and returns the inserted row.
  ///
  /// The returned [Sprint] will have its `id` field set.
  Future<Sprint> insertRow(
    _i1.DatabaseSession session,
    Sprint row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Sprint>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Sprint]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Sprint>> update(
    _i1.DatabaseSession session,
    List<Sprint> rows, {
    _i1.ColumnSelections<SprintTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Sprint>(
      rows,
      columns: columns?.call(Sprint.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Sprint]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Sprint> updateRow(
    _i1.DatabaseSession session,
    Sprint row, {
    _i1.ColumnSelections<SprintTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Sprint>(
      row,
      columns: columns?.call(Sprint.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Sprint] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Sprint?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<SprintUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Sprint>(
      id,
      columnValues: columnValues(Sprint.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Sprint]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Sprint>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SprintUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SprintTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SprintTable>? orderBy,
    _i1.OrderByListBuilder<SprintTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Sprint>(
      columnValues: columnValues(Sprint.t.updateTable),
      where: where(Sprint.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Sprint.t),
      orderByList: orderByList?.call(Sprint.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Sprint]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Sprint>> delete(
    _i1.DatabaseSession session,
    List<Sprint> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Sprint>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Sprint].
  Future<Sprint> deleteRow(
    _i1.DatabaseSession session,
    Sprint row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Sprint>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Sprint>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SprintTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Sprint>(
      where: where(Sprint.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SprintTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Sprint>(
      where: where?.call(Sprint.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Sprint] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SprintTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Sprint>(
      where: where(Sprint.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
