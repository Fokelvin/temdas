import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/widgets/registro_tempo_observacoes.dart';
import 'package:temdas/view/widgets/log_time_dialog.dart';
import 'package:temdas/view/demanda_detalhe_page.dart';
import 'package:temdas/view_model/demanda_detalhe_view_model.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;
import 'support/fake_demanda_repository.dart';
import 'support/fake_sprint_repository.dart';

class ObservacaoRepo extends FakeRegistroTempoRepository {
  ObservacaoRepo(b.RegistroTempo registro) : super(registros: [registro]);
  int atualizacoes = 0;
  @override
  Future<b.RegistroTempo> atualizarObservacao(
    int id,
    String? observacao,
  ) async {
    atualizacoes++;
    return super.atualizarObservacao(id, observacao);
  }
}

void main() {
  final inicio = DateTime.utc(2026, 11, 1, 2, 45);
  final fim = DateTime.utc(2026, 11, 1, 3, 15);
  final originais = [
    for (var i = 0; i < 2; i++)
      b.RegistroTempoObservacao(
        inicioEm: inicio,
        fimEm: fim,
        texto: 'texto legítimo igual',
      ),
  ];
  final sp = Platform.environment['TZ'] == 'America/Sao_Paulo';
  final inicioEsperado = sp
      ? '31/10/2026 às 23:45 (UTC-03:00)'
      : '01/11/2026 às 02:45 (UTC+00:00)';
  final fimEsperado = sp
      ? '01/11/2026 às 00:15 (UTC-03:00)'
      : '01/11/2026 às 03:15 (UTC+00:00)';
  test(
    'formata o instante original no fuso local e identifica a virada de dia',
    () {
      expect(formatarHorarioOriginal(inicio), inicioEsperado);
      expect(formatarHorarioOriginal(fim), fimEsperado);
    },
  );
  testWidgets(
    'mantém duas origens legítimas iguais e horários locais separados do texto',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegistroTempoObservacoes(
              texto: 'texto legítimo igual\n\ntexto legítimo igual',
              originais: originais,
            ),
          ),
        ),
      );
      expect(find.text('texto legítimo igual'), findsNWidgets(2));
      expect(
        find.text('Horário original 1: $inicioEsperado — $fimEsperado'),
        findsOneWidget,
      );
      expect(
        find.text('Horário original 2: $inicioEsperado — $fimEsperado'),
        findsOneWidget,
      );
      expect(find.textContaining('2026-11-01T02:45'), findsNothing);
    },
  );
  testWidgets(
    'não interpreta nem converte datas escritas pelo usuário no texto livre',
    (tester) async {
      const literal =
          '[2026-11-01T02:45:00.000Z — 2026-11-01T03:15:00.000Z]\ntexto digitado';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RegistroTempoObservacoes(texto: literal)),
        ),
      );
      expect(find.text(literal), findsOneWidget);
      expect(find.textContaining('Horário original'), findsNothing);
    },
  );
  testWidgets(
    'Horas e edição isolada mostram mesmos horários locais; salvar sem alterações preserva proveniência',
    (tester) async {
      final registro = b.RegistroTempo(
        id: 1,
        demandaId: 1,
        inicioEm: inicio,
        duracaoMinutos: 30,
        criadoEm: inicio,
        observacao: 'texto legítimo igual\n\ntexto legítimo igual',
        observacoesOriginais: originais,
      );
      final repo = ObservacaoRepo(registro);
      final vm = DemandaDetalheViewModel(
        demandaRepository: FakeDemandaRepository(
          demandas: [demandaFixture(id: 1)],
        ),
        registroTempoRepository: repo,
        sprintViewModel: SprintViewModel(
          repository: FakeSprintRepository(sprints: []),
        ),
      );
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        MaterialApp(home: DemandaDetalhePage(demandaId: 1, viewModel: vm)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Horas'));
      await tester.pumpAndSettle();
      expect(
        find.text('Horário original 1: $inicioEsperado — $fimEsperado'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Editar observação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar observação'));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(
            'Horário original 1: $inicioEsperado — $fimEsperado',
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('demanda-texto')))
            .controller!
            .text,
        registro.observacao,
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(repo.atualizacoes, 0);
      expect(vm.registros.single.observacoesOriginais, hasLength(2));
      expect(vm.registros.single.inicioEm, inicio);
    },
  );
  testWidgets(
    'formulário da agenda apresenta origens no mesmo fuso sem inserir rótulos no texto editável',
    (tester) async {
      LogTimeFormData? capturado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogTimeDialog.editar(
              demandaTitulo: 'D',
              dataInicial: DateTime(2026, 11, 2),
              horaInicial: const TimeOfDay(hour: 9, minute: 0),
              duracaoInicialMinutos: 30,
              observacaoInicial: 'texto legítimo igual\n\ntexto legítimo igual',
              observacoesOriginais: originais,
              onSalvar: (d) async {
                capturado = d;
                return null;
              },
            ),
          ),
        ),
      );
      expect(
        find.text('Horário original 1: $inicioEsperado — $fimEsperado'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('log-time-observacao')),
            )
            .controller!
            .text,
        'texto legítimo igual\n\ntexto legítimo igual',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('salvar-log-time')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
      await tester.pumpAndSettle();
      expect(
        capturado!.observacao,
        'texto legítimo igual\n\ntexto legítimo igual',
      );
      expect(capturado!.duracaoMinutos, 30);
    },
  );
}
