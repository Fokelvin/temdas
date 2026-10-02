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

abstract class EmailWhitelist
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  EmailWhitelist._({
    this.id,
    required this.emailNormalizado,
    this.utilizadoEm,
    required this.createdAt,
  });

  factory EmailWhitelist({
    int? id,
    required String emailNormalizado,
    DateTime? utilizadoEm,
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
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = EmailWhitelistTable();

  static const db = EmailWhitelistRepository._();

  @override
  int? id;

  String emailNormalizado;

  DateTime? utilizadoEm;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [EmailWhitelist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmailWhitelist copyWith({
    int? id,
    String? emailNormalizado,
    DateTime? utilizadoEm,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EmailWhitelist',
      if (id != null) 'id': id,
      'emailNormalizado': emailNormalizado,
      if (utilizadoEm != null) 'utilizadoEm': utilizadoEm?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'EmailWhitelist',
      if (id != null) 'id': id,
      'emailNormalizado': emailNormalizado,
      if (utilizadoEm != null) 'utilizadoEm': utilizadoEm?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static EmailWhitelistInclude include() {
    return EmailWhitelistInclude._();
  }

  static EmailWhitelistIncludeList includeList({
    _i1.WhereExpressionBuilder<EmailWhitelistTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmailWhitelistTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmailWhitelistTable>? orderByList,
    EmailWhitelistInclude? include,
  }) {
    return EmailWhitelistIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EmailWhitelist.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EmailWhitelist.t),
      include: include,
    );
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
    required DateTime createdAt,
  }) : super._(
         id: id,
         emailNormalizado: emailNormalizado,
         utilizadoEm: utilizadoEm,
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
    DateTime? createdAt,
  }) {
    return EmailWhitelist(
      id: id is int? ? id : this.id,
      emailNormalizado: emailNormalizado ?? this.emailNormalizado,
      utilizadoEm: utilizadoEm is DateTime? ? utilizadoEm : this.utilizadoEm,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class EmailWhitelistUpdateTable extends _i1.UpdateTable<EmailWhitelistTable> {
  EmailWhitelistUpdateTable(super.table);

  _i1.ColumnValue<String, String> emailNormalizado(String value) =>
      _i1.ColumnValue(
        table.emailNormalizado,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> utilizadoEm(DateTime? value) =>
      _i1.ColumnValue(
        table.utilizadoEm,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class EmailWhitelistTable extends _i1.Table<int?> {
  EmailWhitelistTable({super.tableRelation})
    : super(tableName: 'emails_whitelist') {
    updateTable = EmailWhitelistUpdateTable(this);
    emailNormalizado = _i1.ColumnString(
      'emailNormalizado',
      this,
    );
    utilizadoEm = _i1.ColumnDateTime(
      'utilizadoEm',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final EmailWhitelistUpdateTable updateTable;

  late final _i1.ColumnString emailNormalizado;

  late final _i1.ColumnDateTime utilizadoEm;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    emailNormalizado,
    utilizadoEm,
    createdAt,
  ];
}

class EmailWhitelistInclude extends _i1.IncludeObject {
  EmailWhitelistInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => EmailWhitelist.t;
}

class EmailWhitelistIncludeList extends _i1.IncludeList {
  EmailWhitelistIncludeList._({
    _i1.WhereExpressionBuilder<EmailWhitelistTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EmailWhitelist.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => EmailWhitelist.t;
}

class EmailWhitelistRepository {
  const EmailWhitelistRepository._();

  /// Returns a list of [EmailWhitelist]s matching the given query parameters.
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
  Future<List<EmailWhitelist>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<EmailWhitelistTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmailWhitelistTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmailWhitelistTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EmailWhitelist>(
      where: where?.call(EmailWhitelist.t),
      orderBy: orderBy?.call(EmailWhitelist.t),
      orderByList: orderByList?.call(EmailWhitelist.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [EmailWhitelist] matching the given query parameters.
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
  Future<EmailWhitelist?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<EmailWhitelistTable>? where,
    int? offset,
    _i1.OrderByBuilder<EmailWhitelistTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmailWhitelistTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EmailWhitelist>(
      where: where?.call(EmailWhitelist.t),
      orderBy: orderBy?.call(EmailWhitelist.t),
      orderByList: orderByList?.call(EmailWhitelist.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EmailWhitelist] by its [id] or null if no such row exists.
  Future<EmailWhitelist?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EmailWhitelist>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EmailWhitelist]s in the list and returns the inserted rows.
  ///
  /// The returned [EmailWhitelist]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<EmailWhitelist>> insert(
    _i1.DatabaseSession session,
    List<EmailWhitelist> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<EmailWhitelist>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [EmailWhitelist] and returns the inserted row.
  ///
  /// The returned [EmailWhitelist] will have its `id` field set.
  Future<EmailWhitelist> insertRow(
    _i1.DatabaseSession session,
    EmailWhitelist row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EmailWhitelist>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EmailWhitelist]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EmailWhitelist>> update(
    _i1.DatabaseSession session,
    List<EmailWhitelist> rows, {
    _i1.ColumnSelections<EmailWhitelistTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EmailWhitelist>(
      rows,
      columns: columns?.call(EmailWhitelist.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EmailWhitelist]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EmailWhitelist> updateRow(
    _i1.DatabaseSession session,
    EmailWhitelist row, {
    _i1.ColumnSelections<EmailWhitelistTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EmailWhitelist>(
      row,
      columns: columns?.call(EmailWhitelist.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EmailWhitelist] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EmailWhitelist?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<EmailWhitelistUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<EmailWhitelist>(
      id,
      columnValues: columnValues(EmailWhitelist.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EmailWhitelist]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<EmailWhitelist>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<EmailWhitelistUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<EmailWhitelistTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmailWhitelistTable>? orderBy,
    _i1.OrderByListBuilder<EmailWhitelistTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<EmailWhitelist>(
      columnValues: columnValues(EmailWhitelist.t.updateTable),
      where: where(EmailWhitelist.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EmailWhitelist.t),
      orderByList: orderByList?.call(EmailWhitelist.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [EmailWhitelist]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EmailWhitelist>> delete(
    _i1.DatabaseSession session,
    List<EmailWhitelist> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EmailWhitelist>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EmailWhitelist].
  Future<EmailWhitelist> deleteRow(
    _i1.DatabaseSession session,
    EmailWhitelist row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EmailWhitelist>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EmailWhitelist>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<EmailWhitelistTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EmailWhitelist>(
      where: where(EmailWhitelist.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<EmailWhitelistTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EmailWhitelist>(
      where: where?.call(EmailWhitelist.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EmailWhitelist] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<EmailWhitelistTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EmailWhitelist>(
      where: where(EmailWhitelist.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
