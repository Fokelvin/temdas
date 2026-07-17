enum DemandaStatus { pendente, emAndamento, concluida }

extension DemandaStatusLabel on DemandaStatus {
  String get label => switch (this) {
    DemandaStatus.pendente => 'Pendente',
    DemandaStatus.emAndamento => 'Em andamento',
    DemandaStatus.concluida => 'Concluída',
  };
}

class Demanda {
  Demanda({
    required this.id,
    required this.titulo,
    required this.tempoEstimado,
    this.status = DemandaStatus.pendente,
    this.parentId,
    this.sprintId,
  });

  final String id;
  final String titulo;
  final Duration tempoEstimado;
  DemandaStatus status;
  final String? parentId;
  final String? sprintId;

  bool get isFilha => parentId != null;
}

class LogTime {
  const LogTime({
    required this.id,
    required this.demandaId,
    required this.data,
    required this.hora,
    required this.duracao,
  });

  final String id;
  final String demandaId;
  final DateTime data;
  final TimeOfDayValue hora;
  final Duration duracao;
}

/// Representação independente da UI para manter o Model sem dependência do Flutter.
class TimeOfDayValue {
  const TimeOfDayValue(this.hour, this.minute);

  final int hour;
  final int minute;

  int get totalMinutes => hour * 60 + minute;
}
