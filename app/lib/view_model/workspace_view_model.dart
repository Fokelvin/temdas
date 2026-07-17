import 'package:flutter/foundation.dart';

import '../model/demanda.dart';

enum AgendaMode { dia, semana }

class WorkspaceViewModel extends ChangeNotifier {
  WorkspaceViewModel({DateTime? hoje})
    : _dataSelecionada = _dateOnly(hoje ?? DateTime.now()) {
    _demandas.addAll(_mockDemandas());
    _logs.addAll(_mockLogs(_dataSelecionada));
  }

  final List<Demanda> _demandas = [];
  final List<LogTime> _logs = [];
  DateTime _dataSelecionada;
  AgendaMode _mode = AgendaMode.dia;
  int _nextDemandId = 20;
  int _nextLogId = 20;

  List<Demanda> get demandas => List.unmodifiable(_demandas);
  List<LogTime> get logs => List.unmodifiable(_logs);
  DateTime get dataSelecionada => _dataSelecionada;
  AgendaMode get mode => _mode;
  DateTime get inicioSemana => _dataSelecionada.subtract(
    Duration(days: _dataSelecionada.weekday - DateTime.monday),
  );
  List<DateTime> get diasDaSemana =>
      List.generate(7, (index) => inicioSemana.add(Duration(days: index)));

  List<Demanda> get demandasRaiz =>
      _demandas.where((item) => !item.isFilha).toList(growable: false);
  List<Demanda> filhasDe(String id) =>
      _demandas.where((item) => item.parentId == id).toList(growable: false);
  Demanda demandaPorId(String id) =>
      _demandas.firstWhere((item) => item.id == id);
  List<LogTime> logsDoDia(DateTime date) =>
      _logs.where((item) => _sameDay(item.data, date)).toList()
        ..sort((a, b) => a.hora.totalMinutes.compareTo(b.hora.totalMinutes));
  Duration executadoDaDemanda(String id) => _sum(
    _logs.where((item) => item.demandaId == id).map((item) => item.duracao),
  );
  Duration get executadoDoPeriodo =>
      _sum(_logsDoPeriodo.map((item) => item.duracao));
  int get lancamentosDoPeriodo => _logsDoPeriodo.length;

  Iterable<LogTime> get _logsDoPeriodo => _mode == AgendaMode.dia
      ? logsDoDia(_dataSelecionada)
      : diasDaSemana.expand(logsDoDia);

  void setMode(AgendaMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  void selecionarData(DateTime value) {
    _dataSelecionada = _dateOnly(value);
    notifyListeners();
  }

  void periodoAnterior() => selecionarData(
    _dataSelecionada.subtract(Duration(days: _mode == AgendaMode.dia ? 1 : 7)),
  );
  void proximoPeriodo() => selecionarData(
    _dataSelecionada.add(Duration(days: _mode == AgendaMode.dia ? 1 : 7)),
  );
  void irParaHoje() => selecionarData(DateTime.now());

  void alterarStatus(Demanda demanda, DemandaStatus status) {
    demanda.status = status;
    notifyListeners();
  }

  void adicionarDemanda({
    required String titulo,
    required Duration estimado,
    required DemandaStatus status,
    String? parentId,
  }) {
    _demandas.add(
      Demanda(
        id: 'd${_nextDemandId++}',
        titulo: titulo,
        tempoEstimado: estimado,
        status: status,
        parentId: parentId,
      ),
    );
    notifyListeners();
  }

  void adicionarLog({
    required String demandaId,
    required DateTime data,
    required TimeOfDayValue hora,
    required Duration duracao,
  }) {
    _logs.add(
      LogTime(
        id: 'l${_nextLogId++}',
        demandaId: demandaId,
        data: _dateOnly(data),
        hora: hora,
        duracao: duracao,
      ),
    );
    notifyListeners();
  }

  static Duration _sum(Iterable<Duration> values) =>
      values.fold(Duration.zero, (total, value) => total + value);
  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<Demanda> _mockDemandas() => [
    Demanda(
      id: 'd1',
      titulo: 'Planejar interface do TEMDAS',
      tempoEstimado: const Duration(hours: 4),
      status: DemandaStatus.emAndamento,
    ),
    Demanda(
      id: 'd2',
      titulo: 'Desenhar visão diária',
      tempoEstimado: const Duration(hours: 2),
      status: DemandaStatus.concluida,
      parentId: 'd1',
    ),
    Demanda(
      id: 'd3',
      titulo: 'Validar fluxo de cadastro',
      tempoEstimado: const Duration(hours: 2),
      status: DemandaStatus.emAndamento,
    ),
    Demanda(
      id: 'd4',
      titulo: 'Revisar visão semanal',
      tempoEstimado: const Duration(hours: 2),
    ),
    Demanda(
      id: 'd5',
      titulo: 'Teste com usuários',
      tempoEstimado: const Duration(hours: 1),
    ),
  ];

  static List<LogTime> _mockLogs(DateTime hoje) => [
    LogTime(
      id: 'l1',
      demandaId: 'd1',
      data: hoje,
      hora: const TimeOfDayValue(9, 0),
      duracao: const Duration(hours: 1, minutes: 20),
    ),
    LogTime(
      id: 'l2',
      demandaId: 'd2',
      data: hoje,
      hora: const TimeOfDayValue(11, 30),
      duracao: const Duration(hours: 1, minutes: 30),
    ),
    LogTime(
      id: 'l3',
      demandaId: 'd3',
      data: hoje,
      hora: const TimeOfDayValue(14, 0),
      duracao: const Duration(minutes: 25),
    ),
    LogTime(
      id: 'l4',
      demandaId: 'd4',
      data: hoje.add(const Duration(days: 1)),
      hora: const TimeOfDayValue(10, 0),
      duracao: const Duration(minutes: 45),
    ),
  ];
}
