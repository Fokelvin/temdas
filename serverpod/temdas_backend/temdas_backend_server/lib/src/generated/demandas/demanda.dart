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
import '../demandas/demanda_status.dart' as _i2;
import '../demandas/prioridade.dart' as _i3;

abstract class Demanda
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Demanda._({
    this.id,
    required this.titulo,
    this.descricao,
    required this.status,
    required this.prioridade,
    this.sprint,
    required this.tempoEstimadoMinutos,
    required this.tempoExecutadoMinutos,
    this.observacoes,
    required this.criadoEm,
    required this.atualizadoEm,
    this.concluidoEm,
  });

  factory Demanda({
    int? id,
    required String titulo,
    String? descricao,
    required _i2.DemandaStatus status,
    required _i3.Prioridade prioridade,
    String? sprint,
    required int tempoEstimadoMinutos,
    required int tempoExecutadoMinutos,
    String? observacoes,
    required DateTime criadoEm,
    required DateTime atualizadoEm,
    DateTime? concluidoEm,
  }) = _DemandaImpl;

  factory Demanda.fromJson(Map<String, dynamic> jsonSerialization) {
    return Demanda(
      id: jsonSerialization['id'] as int?,
      titulo: jsonSerialization['titulo'] as String,
      descricao: jsonSerialization['descricao'] as String?,
      status: _i2.DemandaStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      prioridade: _i3.Prioridade.fromJson(
        (jsonSerialization['prioridade'] as String),
      ),
      sprint: jsonSerialization['sprint'] as String?,
      tempoEstimadoMinutos: jsonSerialization['tempoEstimadoMinutos'] as int,
      tempoExecutadoMinutos: jsonSerialization['tempoExecutadoMinutos'] as int,
      observacoes: jsonSerialization['observacoes'] as String?,
      criadoEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['criadoEm'],
      ),
      atualizadoEm: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['atualizadoEm'],
      ),
      concluidoEm: jsonSerialization['concluidoEm'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['concluidoEm'],
            ),
    );
  }

  static final t = DemandaTable();

  static const db = DemandaRepository._();

  @override
  int? id;

  String titulo;

  String? descricao;

  _i2.DemandaStatus status;

  _i3.Prioridade prioridade;

  String? sprint;

  int tempoEstimadoMinutos;

  int tempoExecutadoMinutos;

  String? observacoes;

  DateTime criadoEm;

  DateTime atualizadoEm;

  DateTime? concluidoEm;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Demanda]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Demanda copyWith({
    int? id,
    String? titulo,
    String? descricao,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
    String? sprint,
    int? tempoEstimadoMinutos,
    int? tempoExecutadoMinutos,
    String? observacoes,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    DateTime? concluidoEm,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Demanda',
      if (id != null) 'id': id,
      'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      'status': status.toJson(),
      'prioridade': prioridade.toJson(),
      if (sprint != null) 'sprint': sprint,
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      'tempoExecutadoMinutos': tempoExecutadoMinutos,
      if (observacoes != null) 'observacoes': observacoes,
      'criadoEm': criadoEm.toJson(),
      'atualizadoEm': atualizadoEm.toJson(),
      if (concluidoEm != null) 'concluidoEm': concluidoEm?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Demanda',
      if (id != null) 'id': id,
      'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      'status': status.toJson(),
      'prioridade': prioridade.toJson(),
      if (sprint != null) 'sprint': sprint,
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      'tempoExecutadoMinutos': tempoExecutadoMinutos,
      if (observacoes != null) 'observacoes': observacoes,
      'criadoEm': criadoEm.toJson(),
      'atualizadoEm': atualizadoEm.toJson(),
      if (concluidoEm != null) 'concluidoEm': concluidoEm?.toJson(),
    };
  }

  static DemandaInclude include() {
    return DemandaInclude._();
  }

  static DemandaIncludeList includeList({
    _i1.WhereExpressionBuilder<DemandaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DemandaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DemandaTable>? orderByList,
    DemandaInclude? include,
  }) {
    return DemandaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Demanda.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Demanda.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DemandaImpl extends Demanda {
  _DemandaImpl({
    int? id,
    required String titulo,
    String? descricao,
    required _i2.DemandaStatus status,
    required _i3.Prioridade prioridade,
    String? sprint,
    required int tempoEstimadoMinutos,
    required int tempoExecutadoMinutos,
    String? observacoes,
    required DateTime criadoEm,
    required DateTime atualizadoEm,
    DateTime? concluidoEm,
  }) : super._(
         id: id,
         titulo: titulo,
         descricao: descricao,
         status: status,
         prioridade: prioridade,
         sprint: sprint,
         tempoEstimadoMinutos: tempoEstimadoMinutos,
         tempoExecutadoMinutos: tempoExecutadoMinutos,
         observacoes: observacoes,
         criadoEm: criadoEm,
         atualizadoEm: atualizadoEm,
         concluidoEm: concluidoEm,
       );

  /// Returns a shallow copy of this [Demanda]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Demanda copyWith({
    Object? id = _Undefined,
    String? titulo,
    Object? descricao = _Undefined,
    _i2.DemandaStatus? status,
    _i3.Prioridade? prioridade,
    Object? sprint = _Undefined,
    int? tempoEstimadoMinutos,
    int? tempoExecutadoMinutos,
    Object? observacoes = _Undefined,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    Object? concluidoEm = _Undefined,
  }) {
    return Demanda(
      id: id is int? ? id : this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao is String? ? descricao : this.descricao,
      status: status ?? this.status,
      prioridade: prioridade ?? this.prioridade,
      sprint: sprint is String? ? sprint : this.sprint,
      tempoEstimadoMinutos: tempoEstimadoMinutos ?? this.tempoEstimadoMinutos,
      tempoExecutadoMinutos:
          tempoExecutadoMinutos ?? this.tempoExecutadoMinutos,
      observacoes: observacoes is String? ? observacoes : this.observacoes,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      concluidoEm: concluidoEm is DateTime? ? concluidoEm : this.concluidoEm,
    );
  }
}

class DemandaUpdateTable extends _i1.UpdateTable<DemandaTable> {
  DemandaUpdateTable(super.table);

  _i1.ColumnValue<String, String> titulo(String value) => _i1.ColumnValue(
    table.titulo,
    value,
  );

  _i1.ColumnValue<String, String> descricao(String? value) => _i1.ColumnValue(
    table.descricao,
    value,
  );

  _i1.ColumnValue<_i2.DemandaStatus, _i2.DemandaStatus> status(
    _i2.DemandaStatus value,
  ) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<_i3.Prioridade, _i3.Prioridade> prioridade(
    _i3.Prioridade value,
  ) => _i1.ColumnValue(
    table.prioridade,
    value,
  );

  _i1.ColumnValue<String, String> sprint(String? value) => _i1.ColumnValue(
    table.sprint,
    value,
  );

  _i1.ColumnValue<int, int> tempoEstimadoMinutos(int value) => _i1.ColumnValue(
    table.tempoEstimadoMinutos,
    value,
  );

  _i1.ColumnValue<int, int> tempoExecutadoMinutos(int value) => _i1.ColumnValue(
    table.tempoExecutadoMinutos,
    value,
  );

  _i1.ColumnValue<String, String> observacoes(String? value) => _i1.ColumnValue(
    table.observacoes,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> criadoEm(DateTime value) =>
      _i1.ColumnValue(
        table.criadoEm,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> atualizadoEm(DateTime value) =>
      _i1.ColumnValue(
        table.atualizadoEm,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> concluidoEm(DateTime? value) =>
      _i1.ColumnValue(
        table.concluidoEm,
        value,
      );
}

class DemandaTable extends _i1.Table<int?> {
  DemandaTable({super.tableRelation}) : super(tableName: 'demandas') {
    updateTable = DemandaUpdateTable(this);
    titulo = _i1.ColumnString(
      'titulo',
      this,
    );
    descricao = _i1.ColumnString(
      'descricao',
      this,
    );
    status = _i1.ColumnEnum(
      'status',
      this,
      _i1.EnumSerialization.byName,
    );
    prioridade = _i1.ColumnEnum(
      'prioridade',
      this,
      _i1.EnumSerialization.byName,
    );
    sprint = _i1.ColumnString(
      'sprint',
      this,
    );
    tempoEstimadoMinutos = _i1.ColumnInt(
      'tempoEstimadoMinutos',
      this,
    );
    tempoExecutadoMinutos = _i1.ColumnInt(
      'tempoExecutadoMinutos',
      this,
    );
    observacoes = _i1.ColumnString(
      'observacoes',
      this,
    );
    criadoEm = _i1.ColumnDateTime(
      'criadoEm',
      this,
    );
    atualizadoEm = _i1.ColumnDateTime(
      'atualizadoEm',
      this,
    );
    concluidoEm = _i1.ColumnDateTime(
      'concluidoEm',
      this,
    );
  }

  late final DemandaUpdateTable updateTable;

  late final _i1.ColumnString titulo;

  late final _i1.ColumnString descricao;

  late final _i1.ColumnEnum<_i2.DemandaStatus> status;

  late final _i1.ColumnEnum<_i3.Prioridade> prioridade;

  late final _i1.ColumnString sprint;

  late final _i1.ColumnInt tempoEstimadoMinutos;

  late final _i1.ColumnInt tempoExecutadoMinutos;

  late final _i1.ColumnString observacoes;

  late final _i1.ColumnDateTime criadoEm;

  late final _i1.ColumnDateTime atualizadoEm;

  late final _i1.ColumnDateTime concluidoEm;

  @override
  List<_i1.Column> get columns => [
    id,
    titulo,
    descricao,
    status,
    prioridade,
    sprint,
    tempoEstimadoMinutos,
    tempoExecutadoMinutos,
    observacoes,
    criadoEm,
    atualizadoEm,
    concluidoEm,
  ];
}

class DemandaInclude extends _i1.IncludeObject {
  DemandaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Demanda.t;
}

class DemandaIncludeList extends _i1.IncludeList {
  DemandaIncludeList._({
    _i1.WhereExpressionBuilder<DemandaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Demanda.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Demanda.t;
}

class DemandaRepository {
  const DemandaRepository._();

  /// Returns a list of [Demanda]s matching the given query parameters.
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
  Future<List<Demanda>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DemandaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DemandaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DemandaTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Demanda>(
      where: where?.call(Demanda.t),
      orderBy: orderBy?.call(Demanda.t),
      orderByList: orderByList?.call(Demanda.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Demanda] matching the given query parameters.
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
  Future<Demanda?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DemandaTable>? where,
    int? offset,
    _i1.OrderByBuilder<DemandaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DemandaTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Demanda>(
      where: where?.call(Demanda.t),
      orderBy: orderBy?.call(Demanda.t),
      orderByList: orderByList?.call(Demanda.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Demanda] by its [id] or null if no such row exists.
  Future<Demanda?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Demanda>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Demanda]s in the list and returns the inserted rows.
  ///
  /// The returned [Demanda]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Demanda>> insert(
    _i1.DatabaseSession session,
    List<Demanda> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Demanda>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Demanda] and returns the inserted row.
  ///
  /// The returned [Demanda] will have its `id` field set.
  Future<Demanda> insertRow(
    _i1.DatabaseSession session,
    Demanda row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Demanda>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Demanda]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Demanda>> update(
    _i1.DatabaseSession session,
    List<Demanda> rows, {
    _i1.ColumnSelections<DemandaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Demanda>(
      rows,
      columns: columns?.call(Demanda.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Demanda]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Demanda> updateRow(
    _i1.DatabaseSession session,
    Demanda row, {
    _i1.ColumnSelections<DemandaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Demanda>(
      row,
      columns: columns?.call(Demanda.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Demanda] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Demanda?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<DemandaUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Demanda>(
      id,
      columnValues: columnValues(Demanda.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Demanda]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Demanda>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<DemandaUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<DemandaTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DemandaTable>? orderBy,
    _i1.OrderByListBuilder<DemandaTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Demanda>(
      columnValues: columnValues(Demanda.t.updateTable),
      where: where(Demanda.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Demanda.t),
      orderByList: orderByList?.call(Demanda.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Demanda]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Demanda>> delete(
    _i1.DatabaseSession session,
    List<Demanda> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Demanda>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Demanda].
  Future<Demanda> deleteRow(
    _i1.DatabaseSession session,
    Demanda row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Demanda>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Demanda>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DemandaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Demanda>(
      where: where(Demanda.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DemandaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Demanda>(
      where: where?.call(Demanda.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Demanda] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DemandaTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Demanda>(
      where: where(Demanda.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
