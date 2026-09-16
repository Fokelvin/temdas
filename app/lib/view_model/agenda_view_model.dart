import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../data/repositories/demanda_repository.dart';
import '../data/repositories/registro_tempo_repository.dart';

enum AgendaMode { dia, semana }

class AgendaViewModel extends ChangeNotifier {
  AgendaViewModel({
    DemandaRepository? demandaRepository,
    RegistroTempoRepository? registroTempoRepository,
    DateTime? hoje,
    DateTime Function()? relogio,
  }) : _demandaRepository = demandaRepository ?? DemandaRepository(),
       _registroTempoRepository =
           registroTempoRepository ?? RegistroTempoRepository(),
       _relogio = relogio ?? DateTime.now,
       _dataSelecionada = _somenteDataLocal(
         hoje ?? relogio?.call() ?? DateTime.now(),
       );

  final DemandaRepository _demandaRepository;
  final RegistroTempoRepository _registroTempoRepository;
  final DateTime Function() _relogio;

  DateTime _dataSelecionada;
  AgendaMode _mode = AgendaMode.dia;
  bool _carregando = false;
  bool _enviando = false;
  bool _disposed = false;
  String? _erro;
  String? _erroEdicao;
  int _requestToken = 0;
  List<backend.Demanda> _demandas = const [];
  List<backend.RegistroTempo> _registros = const [];
  Map<int, backend.Demanda> _demandasPorId = const {};
  Map<DateTime, List<backend.RegistroTempo>> _registrosPorDia = const {};
  Map<int, List<backend.RegistroTempo>> _registrosPorDemanda = const {};

  DateTime get dataSelecionada => _dataSelecionada;
  AgendaMode get mode => _mode;
  bool get carregando => _carregando;
  bool get enviando => _enviando;
  String? get erro => _erro;
  String? get erroEdicao => _erroEdicao;

  List<backend.Demanda> get demandas => UnmodifiableListView(_demandas);
  List<backend.RegistroTempo> get registros => UnmodifiableListView(_registros);
  List<backend.RegistroTempo> get registrosDoPeriodo => registros;
  Map<int, backend.Demanda> get demandasPorId =>
      UnmodifiableMapView(_demandasPorId);
  Map<DateTime, List<backend.RegistroTempo>> get registrosPorDia =>
      UnmodifiableMapView(_registrosPorDia);
  Map<int, List<backend.RegistroTempo>> get registrosPorDemanda =>
      UnmodifiableMapView(_registrosPorDemanda);

  DateTime get inicioSemana {
    final dia =
        _dataSelecionada.day - (_dataSelecionada.weekday - DateTime.monday);
    return DateTime(_dataSelecionada.year, _dataSelecionada.month, dia);
  }

  List<DateTime> get diasDaSemana => List.unmodifiable(
    List.generate(
      DateTime.daysPerWeek,
      (index) => DateTime(
        inicioSemana.year,
        inicioSemana.month,
        inicioSemana.day + index,
      ),
    ),
  );

  DateTime get inicioPeriodoLocal =>
      _mode == AgendaMode.dia ? _dataSelecionada : inicioSemana;

  DateTime get fimPeriodoLocal {
    final inicio = inicioPeriodoLocal;
    return DateTime(
      inicio.year,
      inicio.month,
      inicio.day + (_mode == AgendaMode.dia ? 1 : DateTime.daysPerWeek),
    );
  }

  DateTime get inicioPeriodoUtc => inicioPeriodoLocal.toUtc();
  DateTime get fimPeriodoUtc => fimPeriodoLocal.toUtc();

  int get lancamentosDoPeriodo => _registros.length;
  int get tempoExecutadoMinutosNoPeriodo =>
      _registros.fold(0, (total, registro) => total + registro.duracaoMinutos);
  Duration get executadoDoPeriodo =>
      Duration(minutes: tempoExecutadoMinutosNoPeriodo);

  backend.Demanda? demandaPorId(int demandaId) => _demandasPorId[demandaId];

  List<backend.RegistroTempo> registrosDoDia(DateTime data) {
    final chave = _somenteDataLocal(data);
    return _registrosPorDia[chave] ?? const [];
  }

  List<backend.RegistroTempo> registrosDaDemandaNoPeriodo(int demandaId) =>
      _registrosPorDemanda[demandaId] ?? const [];

  int tempoExecutadoMinutosDaDemandaNoPeriodo(int demandaId) =>
      registrosDaDemandaNoPeriodo(
        demandaId,
      ).fold(0, (total, registro) => total + registro.duracaoMinutos);

  Future<void> carregar() => carregarAgenda();

  Future<void> carregarAgenda() async {
    final token = ++_requestToken;
    final inicio = inicioPeriodoUtc;
    final fim = fimPeriodoUtc;

    _carregando = true;
    _erro = null;
    _notificar();

    try {
      final (demandas, registros) = await (
        _demandaRepository.listarDemandas(),
        _registroTempoRepository.listarPorPeriodo(inicio: inicio, fim: fim),
      ).wait;

      if (!_requestAtual(token)) return;

      _demandas = List.of(demandas);
      _registros = List.of(registros)
        ..sort((a, b) => a.inicioEm.compareTo(b.inicioEm));
      _reconstruirIndices();
    } catch (error, stackTrace) {
      if (!_requestAtual(token)) return;

      debugPrint('[AgendaViewModel] Falha ao carregar a agenda: $error');
      debugPrintStack(stackTrace: stackTrace);
      _erro = 'Não foi possível carregar a agenda. Tente novamente.';
    } finally {
      if (_requestAtual(token)) {
        _carregando = false;
        _notificar();
      }
    }
  }

  Future<void> setMode(AgendaMode value) {
    if (_mode == value) return Future.value();
    _mode = value;
    return carregarAgenda();
  }

  Future<void> selecionarData(DateTime value) {
    final novaData = _somenteDataLocal(value);
    if (novaData == _dataSelecionada) return Future.value();
    _dataSelecionada = novaData;
    return carregarAgenda();
  }

  Future<void> mostrarDia(DateTime value) {
    final novaData = _somenteDataLocal(value);
    if (_mode == AgendaMode.dia && novaData == _dataSelecionada) {
      return Future.value();
    }
    _mode = AgendaMode.dia;
    _dataSelecionada = novaData;
    return carregarAgenda();
  }

  Future<void> periodoAnterior() {
    final dias = _mode == AgendaMode.dia ? 1 : DateTime.daysPerWeek;
    return selecionarData(
      DateTime(
        _dataSelecionada.year,
        _dataSelecionada.month,
        _dataSelecionada.day - dias,
      ),
    );
  }

  Future<void> proximoPeriodo() {
    final dias = _mode == AgendaMode.dia ? 1 : DateTime.daysPerWeek;
    return selecionarData(
      DateTime(
        _dataSelecionada.year,
        _dataSelecionada.month,
        _dataSelecionada.day + dias,
      ),
    );
  }

  Future<void> irParaHoje() => selecionarData(_relogio());

  Future<bool> registrarTempo({
    required int demandaId,
    required DateTime data,
    required TimeOfDay hora,
    required double duracaoHoras,
  }) async {
    if (_enviando) return false;

    final duracaoMinutos = converterHorasEmMinutos(duracaoHoras);
    if (duracaoMinutos == null) {
      _erro = 'A duração deve ser positiva e resultar em minutos inteiros.';
      _notificar();
      return false;
    }

    if (!_demandasPorId.containsKey(demandaId)) {
      _erro = 'Selecione uma demanda válida.';
      _notificar();
      return false;
    }

    final inicioLocal = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );

    _enviando = true;
    _erro = null;
    _notificar();

    try {
      await _registroTempoRepository.registrarTempo(
        demandaId: demandaId,
        inicioEm: inicioLocal.toUtc(),
        duracaoMinutos: duracaoMinutos,
      );
      if (!_disposed) await carregarAgenda();
      return true;
    } catch (error, stackTrace) {
      if (error is backend.ConflitoHorarioException) {
        _erro =
            'Conflito de horário com um lançamento de outra demanda. '
            'Ajuste a data, o horário ou a duração e tente novamente.';
        return false;
      }
      debugPrint('[AgendaViewModel] Falha ao registrar tempo: $error');
      debugPrintStack(stackTrace: stackTrace);
      _erro = 'Não foi possível registrar o tempo. Tente novamente.';
      return false;
    } finally {
      _enviando = false;
      _notificar();
    }
  }

  Future<bool> editarRegistroTempo({
    required int id,
    required DateTime data,
    required TimeOfDay hora,
    required double duracaoHoras,
  }) async {
    if (_disposed || _enviando) return false;

    _erroEdicao = null;
    final duracaoMinutos = converterHorasEmMinutos(duracaoHoras);
    if (duracaoMinutos == null) {
      _erroEdicao =
          'A duração deve ser positiva e resultar em minutos inteiros.';
      _notificar();
      return false;
    }

    final inicioLocal = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );

    _enviando = true;
    _notificar();
    try {
      await _registroTempoRepository.editarRegistroTempo(
        id: id,
        inicioEm: inicioLocal.toUtc(),
        duracaoMinutos: duracaoMinutos,
      );
      // Reconsulta o período para refletir mudanças de data e registros
      // absorvidos, usando apenas os valores persistidos pelo backend.
      if (!_disposed) await carregarAgenda();
      return true;
    } on backend.ConflitoHorarioException {
      _erroEdicao =
          'Conflito de horário com um lançamento de outra demanda. '
          'Ajuste a data, o horário ou a duração e tente novamente.';
      return false;
    } catch (error, stackTrace) {
      debugPrint('[AgendaViewModel] Falha ao editar lançamento: $error');
      debugPrintStack(stackTrace: stackTrace);
      _erroEdicao = 'Não foi possível editar o lançamento. Tente novamente.';
      return false;
    } finally {
      _enviando = false;
      _notificar();
    }
  }

  Future<bool> excluirRegistroTempo(int id) async {
    if (_enviando) return false;

    _enviando = true;
    _erro = null;
    _notificar();

    try {
      final excluido = await _registroTempoRepository.excluirRegistroTempo(id);
      if (!excluido) {
        _erro = 'O lançamento não foi encontrado ou já foi excluído.';
        return false;
      }
      if (!_disposed) await carregarAgenda();
      return true;
    } catch (error, stackTrace) {
      debugPrint('[AgendaViewModel] Falha ao excluir lançamento: $error');
      debugPrintStack(stackTrace: stackTrace);
      _erro = 'Não foi possível excluir o lançamento. Tente novamente.';
      return false;
    } finally {
      _enviando = false;
      _notificar();
    }
  }

  void limparErro() {
    if (_erro == null) return;
    _erro = null;
    _notificar();
  }

  static int? converterHorasEmMinutos(double horas) {
    if (!horas.isFinite || horas <= 0) return null;

    final minutos = horas * Duration.minutesPerHour;
    if (!minutos.isFinite) return null;

    final minutosInteiros = minutos.round();
    if ((minutos - minutosInteiros).abs() > 1e-9) return null;
    return minutosInteiros;
  }

  void _reconstruirIndices() {
    _demandasPorId = {
      for (final demanda in _demandas)
        if (demanda.id case final int id) id: demanda,
    };

    final porDia = <DateTime, List<backend.RegistroTempo>>{};
    final porDemanda = <int, List<backend.RegistroTempo>>{};
    for (final registro in _registros) {
      final inicioLocal = registro.inicioEm.toLocal();
      final dataLocal = _somenteDataLocal(inicioLocal);
      porDia.putIfAbsent(dataLocal, () => []).add(registro);
      porDemanda.putIfAbsent(registro.demandaId, () => []).add(registro);
    }

    _registrosPorDia = {
      for (final MapEntry(:key, :value) in porDia.entries)
        key: List.unmodifiable(value),
    };
    _registrosPorDemanda = {
      for (final MapEntry(:key, :value) in porDemanda.entries)
        key: List.unmodifiable(value),
    };
  }

  bool _requestAtual(int token) => !_disposed && token == _requestToken;

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  static DateTime _somenteDataLocal(DateTime value) {
    final local = value.isUtc ? value.toLocal() : value;
    return DateTime(local.year, local.month, local.day);
  }

  @override
  void dispose() {
    _disposed = true;
    _requestToken++;
    super.dispose();
  }
}
