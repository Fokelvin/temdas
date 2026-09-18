import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/log_time_page.dart';
import 'package:temdas/view_model/agenda_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_agenda_repositories.dart';

void main() {
  testWidgets('move registro no dia arredonda o horário para 15 minutos', (
    tester,
  ) async {
    final registro = registroTempoFixture(
      id: 1,
      inicioLocal: DateTime(2026, 9, 9, 9),
      duracaoMinutos: 90,
    );
    final resposta = Completer<backend.RegistroTempo>();
    final registros = FakeRegistroTempoRepository(registros: [registro])
      ..respostaEditarPendente = resposta;
    final viewModel = await _abrirAgenda(tester, registros);
    await viewModel.mostrarDia(DateTime(2026, 9, 9));
    await tester.pumpAndSettle();

    final gesto = await _iniciarArrasto(
      tester,
      registroId: 1,
      dataDestino: DateTime(2026, 9, 9),
      minutoDestino: 10 * 60 + 8,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('log-time-drop-preview')))
          .data,
      '10:15 – 11:45',
    );
    await _soltarArrasto(tester, gesto);

    expect(
      registros.registrosEditados.single.inicioEm,
      DateTime(2026, 9, 9, 10, 15).toUtc(),
    );
    expect(registros.registrosEditados.single.duracaoMinutos, 90);
    resposta.complete(
      registro.copyWith(inicioEm: DateTime(2026, 9, 9, 10, 15).toUtc()),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('move registro na semana troca dia e horário com snap', (
    tester,
  ) async {
    final registro = registroTempoFixture(
      id: 1,
      inicioLocal: DateTime(2026, 9, 8, 9),
      duracaoMinutos: 90,
    );
    final resposta = Completer<backend.RegistroTempo>();
    final registros = FakeRegistroTempoRepository(registros: [registro])
      ..respostaEditarPendente = resposta;
    final viewModel = await _abrirAgenda(tester, registros);

    await _arrastar(
      tester,
      registroId: 1,
      dataDestino: DateTime(2026, 9, 9),
      minutoDestino: 14 * 60 + 15,
    );

    expect(registros.registrosEditados.single.id, 1);
    expect(
      registros.registrosEditados.single.inicioEm,
      DateTime(2026, 9, 9, 14, 15).toUtc(),
    );
    expect(registros.registrosEditados.single.duracaoMinutos, 90);
    expect(viewModel.enviando, isTrue);

    resposta.complete(
      registro.copyWith(inicioEm: DateTime(2026, 9, 9, 14, 15).toUtc()),
    );
    await tester.pumpAndSettle();

    expect(
      viewModel.registros.single.inicioEm,
      equals(DateTime(2026, 9, 9, 14, 15).toUtc()),
    );
    expect(viewModel.registros.single.duracaoMinutos, 90);
    expect(viewModel.enviando, isFalse);
  });

  testWidgets('drop além do fim do dia não envia edição', (tester) async {
    final registro = registroTempoFixture(
      id: 1,
      inicioLocal: DateTime(2026, 9, 8, 9),
      duracaoMinutos: 90,
    );
    final registros = FakeRegistroTempoRepository(registros: [registro]);
    final viewModel = await _abrirAgenda(tester, registros);

    final gesto = await _iniciarArrasto(
      tester,
      registroId: 1,
      dataDestino: DateTime(2026, 9, 9),
      minutoDestino: 23 * 60,
    );
    expect(find.byKey(const ValueKey('log-time-drop-preview')), findsOneWidget);
    await _soltarArrasto(tester, gesto);

    expect(registros.registrosEditados, isEmpty);
    expect(viewModel.registros.single.inicioEm, registro.inicioEm);
  });

  testWidgets('conflito do backend mantém o registro e mostra feedback', (
    tester,
  ) async {
    final registro = registroTempoFixture(
      id: 1,
      inicioLocal: DateTime(2026, 9, 8, 9),
      duracaoMinutos: 90,
    );
    final registros = FakeRegistroTempoRepository(registros: [registro])
      ..erroAoEditar = backend.ConflitoHorarioException(
        mensagem: 'Conflito detectado.',
        demandaConflitanteId: 2,
        registroConflitanteId: 9,
      );
    final viewModel = await _abrirAgenda(tester, registros);

    await _arrastar(
      tester,
      registroId: 1,
      dataDestino: DateTime(2026, 9, 9),
      minutoDestino: 14 * 60 + 15,
    );
    await tester.pumpAndSettle();

    expect(viewModel.registros.single.inicioEm, registro.inicioEm);
    expect(
      find.textContaining('Conflito de horário com um lançamento'),
      findsOneWidget,
    );
    expect(viewModel.enviando, isFalse);
  });
}

Future<AgendaViewModel> _abrirAgenda(
  WidgetTester tester,
  FakeRegistroTempoRepository registros,
) async {
  await tester.binding.setSurfaceSize(const Size(1280, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final viewModel = AgendaViewModel(
    hoje: DateTime(2026, 9, 9),
    demandaRepository: FakeAgendaDemandaRepository(
      demandas: [demandaAgendaFixture()],
    ),
    registroTempoRepository: registros,
  );
  addTearDown(viewModel.dispose);
  await tester.pumpWidget(MaterialApp(home: LogTimePage(viewModel: viewModel)));
  await tester.pumpAndSettle();
  return viewModel;
}

Future<void> _arrastar(
  WidgetTester tester, {
  required int registroId,
  required DateTime dataDestino,
  required int minutoDestino,
}) async {
  final gesto = await _iniciarArrasto(
    tester,
    registroId: registroId,
    dataDestino: dataDestino,
    minutoDestino: minutoDestino,
  );
  await _soltarArrasto(tester, gesto);
}

Future<TestGesture> _iniciarArrasto(
  WidgetTester tester, {
  required int registroId,
  required DateTime dataDestino,
  required int minutoDestino,
}) async {
  final origemFinder = find.byKey(ValueKey('mover-registro-$registroId'));
  final destinoFinder = find.byKey(
    ValueKey(
      'log-time-day-${dataDestino.year}-'
      '${dataDestino.month.toString().padLeft(2, '0')}-'
      '${dataDestino.day.toString().padLeft(2, '0')}',
    ),
  );
  await tester.ensureVisible(origemFinder);
  final origem = tester.getCenter(origemFinder);
  final destinoRect = tester.getRect(destinoFinder);
  final destino = Offset(
    destinoRect.left + destinoRect.width / 2,
    destinoRect.top + minutoDestino * 64 / 60 + 2,
  );
  final gesto = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    buttons: kPrimaryButton,
  );
  await gesto.addPointer(location: origem);
  await gesto.down(origem);
  await gesto.moveTo(destino);
  await tester.pump();
  return gesto;
}

Future<void> _soltarArrasto(WidgetTester tester, TestGesture gesto) async {
  await gesto.up();
  await gesto.removePointer();
  await tester.pump();
}
