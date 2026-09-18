import 'package:flutter/foundation.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../data/repositories/relatorio_repository.dart';

enum RelatorioPeriodoTipo { semana, mes, personalizado }

class RelatorioPeriodoLimites {
  const RelatorioPeriodoLimites({
    required this.inicioLocal,
    required this.fimExclusivoLocal,
  });

  final DateTime inicioLocal;
  final DateTime fimExclusivoLocal;

  DateTime get inicioUtc => inicioLocal.toUtc();
  DateTime get fimExclusivoUtc => fimExclusivoLocal.toUtc();
}

RelatorioPeriodoLimites calcularLimitesRelatorio({
  required RelatorioPeriodoTipo tipo,
  required DateTime agora,
  DateTime? dataInicial,
  DateTime? dataFinal,
}) {
  final hoje = _somenteDataLocal(agora.toLocal());
  switch (tipo) {
    case RelatorioPeriodoTipo.semana:
      final inicio = DateTime(
        hoje.year,
        hoje.month,
        hoje.day - (hoje.weekday - DateTime.monday),
      );
      return RelatorioPeriodoLimites(
        inicioLocal: inicio,
        fimExclusivoLocal: DateTime(
          inicio.year,
          inicio.month,
          inicio.day + DateTime.daysPerWeek,
        ),
      );
    case RelatorioPeriodoTipo.mes:
      final inicio = DateTime(hoje.year, hoje.month);
      return RelatorioPeriodoLimites(
        inicioLocal: inicio,
        fimExclusivoLocal: DateTime(inicio.year, inicio.month + 1),
      );
    case RelatorioPeriodoTipo.personalizado:
      if (dataInicial == null || dataFinal == null) {
        throw ArgumentError('Informe as datas do período personalizado.');
      }
      final inicio = _somenteDataLocal(dataInicial.toLocal());
      final fimInclusivo = _somenteDataLocal(dataFinal.toLocal());
      return RelatorioPeriodoLimites(
        inicioLocal: inicio,
        fimExclusivoLocal: DateTime(
          fimInclusivo.year,
          fimInclusivo.month,
          fimInclusivo.day + 1,
        ),
      );
  }
}

class RelatoriosViewModel extends ChangeNotifier {
  RelatoriosViewModel({
    RelatorioRepository? repository,
    DateTime Function()? relogio,
  }) : _repository = repository ?? RelatorioRepository(),
       _relogio = relogio ?? DateTime.now {
    final limites = calcularLimitesRelatorio(
      tipo: RelatorioPeriodoTipo.semana,
      agora: _relogio(),
    );
    _dataInicialPersonalizada = limites.inicioLocal;
    _dataFinalPersonalizada = DateTime(
      limites.fimExclusivoLocal.year,
      limites.fimExclusivoLocal.month,
      limites.fimExclusivoLocal.day - 1,
    );
  }

  final RelatorioRepository _repository;
  final DateTime Function() _relogio;

  RelatorioPeriodoTipo _tipo = RelatorioPeriodoTipo.semana;
  late DateTime _dataInicialPersonalizada;
  late DateTime _dataFinalPersonalizada;
  backend.DemandaStatus? _status;
  backend.Prioridade? _prioridade;
  backend.RelatorioDemandasResponse? _resposta;
  bool _carregando = false;
  bool _descartado = false;
  int _requestToken = 0;
  String? _erro;

  RelatorioPeriodoTipo get tipo => _tipo;
  DateTime get dataInicialPersonalizada => _dataInicialPersonalizada;
  DateTime get dataFinalPersonalizada => _dataFinalPersonalizada;
  backend.DemandaStatus? get status => _status;
  backend.Prioridade? get prioridade => _prioridade;
  backend.RelatorioDemandasResponse? get resposta => _resposta;
  bool get carregando => _carregando;
  String? get erro => _erro;

  RelatorioPeriodoLimites get limitesAtuais => calcularLimitesRelatorio(
    tipo: _tipo,
    agora: _relogio(),
    dataInicial: _dataInicialPersonalizada,
    dataFinal: _dataFinalPersonalizada,
  );

  void selecionarTipo(RelatorioPeriodoTipo tipo) {
    if (_tipo == tipo) return;
    _tipo = tipo;
    _erro = null;
    _notificar();
  }

  void selecionarDataInicial(DateTime data) {
    _dataInicialPersonalizada = _somenteDataLocal(data.toLocal());
    _erro = null;
    _notificar();
  }

  void selecionarDataFinal(DateTime data) {
    _dataFinalPersonalizada = _somenteDataLocal(data.toLocal());
    _erro = null;
    _notificar();
  }

  void selecionarStatus(backend.DemandaStatus? status) {
    _status = status;
    _erro = null;
    _notificar();
  }

  void selecionarPrioridade(backend.Prioridade? prioridade) {
    _prioridade = prioridade;
    _erro = null;
    _notificar();
  }

  Future<void> gerarRelatorio() async {
    if (_descartado || _carregando) return;

    final limites = limitesAtuais;
    if (!limites.inicioLocal.isBefore(limites.fimExclusivoLocal)) {
      _erro = 'A data inicial deve ser anterior ou igual à data final.';
      _notificar();
      return;
    }

    final token = ++_requestToken;
    _carregando = true;
    _erro = null;
    _notificar();

    try {
      final resposta = await _repository.gerarRelatorio(
        backend.RelatorioDemandaRequest(
          inicioEm: limites.inicioUtc,
          fimExclusivo: limites.fimExclusivoUtc,
          status: _status,
          prioridade: _prioridade,
        ),
      );
      if (_descartado || token != _requestToken) return;
      _resposta = resposta;
    } catch (error, stackTrace) {
      if (_descartado || token != _requestToken) return;
      debugPrint('[RelatoriosViewModel] Falha ao carregar relatório: $error');
      debugPrintStack(stackTrace: stackTrace);
      _erro = 'Não foi possível carregar o relatório. Tente novamente.';
    } finally {
      if (!_descartado && token == _requestToken) {
        _carregando = false;
        _notificar();
      }
    }
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }
}

DateTime _somenteDataLocal(DateTime data) =>
    DateTime(data.year, data.month, data.day);
