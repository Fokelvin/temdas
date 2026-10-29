import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/log_time_page.dart';
import 'package:temdas/view/widgets/log_time_calendar.dart';
import 'package:temdas/view/widgets/log_time_dialog.dart';
import 'package:temdas/view_model/agenda_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_agenda_repositories.dart';

void main() {
  testWidgets(
    'texto ampliado mantém indicadores e grade sem cortes no celular',
    (tester) async {
      await _abrir(
        tester,
        size: const Size(390, 844),
        theme: AppTheme.dark,
        escala: 1.5,
      );
      expect(find.text('Lançamentos no período'), findsOneWidget);
      expect(find.text('Tempo executado'), findsOneWidget);
      expect(
        tester.getSize(find.byType(LogTimeCalendar)).height,
        greaterThan(100),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'troca Dia/Semana e navegação mantêm data da criação e colunas alinhadas',
    (tester) async {
      await _abrir(tester);
      await tester.tap(find.text('Dia'));
      await tester.pumpAndSettle();
      expect(_dia(DateTime(2026, 9, 9)), findsOneWidget);
      expect(_dia(DateTime(2026, 9, 10)), findsNothing);
      await tester.tap(find.byKey(const ValueKey('proximo-periodo')));
      await tester.pumpAndSettle();
      expect(_dia(DateTime(2026, 9, 9)), findsNothing);
      await tester.tapAt(_ponto(tester, DateTime(2026, 9, 10), 9 * 60));
      await tester.pumpAndSettle();
      await _continuar(tester);
      expect(
        tester.widget<LogTimeDialog>(find.byType(LogTimeDialog)).dataInicial,
        DateTime(2026, 9, 10),
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semana'));
      await tester.pumpAndSettle();
      for (var day = 7; day <= 13; day++) {
        final column = _dia(DateTime(2026, 9, day));
        expect(column, findsOneWidget);
        expect(
          tester
              .getCenter(find.text('${day.toString().padLeft(2, '0')}/09'))
              .dx,
          closeTo(tester.getCenter(column).dx, 1),
        );
      }
    },
  );

  testWidgets(
    'recarga da agenda desabilita criação até os dados estarem disponíveis',
    (tester) async {
      final repository = FakeRegistroTempoRepository();
      final vm = await _abrir(tester, repository: repository);
      final pending = Completer<List<backend.RegistroTempo>>();
      repository.respostasPendentes.add(pending);
      final loading = vm.carregarAgenda();
      await tester.pump();
      expect(find.byKey(const ValueKey('agenda-carregando')), findsOneWidget);
      expect(find.byType(LogTimeCalendar), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('abrir-lancamento-global')),
            )
            .onPressed,
        isNull,
      );
      pending.complete([]);
      await loading;
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('abrir-lancamento-global')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tapAt(_ponto(tester, DateTime(2026, 9, 9), 9 * 60));
      await tester.pumpAndSettle();
      expect(find.text('Selecionar demanda'), findsOneWidget);
    },
  );

  testWidgets('rolagem horizontal por toque no celular não cria lançamento', (
    tester,
  ) async {
    await _abrir(tester, size: const Size(390, 844));
    final day = DateTime(2026, 9, 7);
    final left = tester.getTopLeft(_dia(day)).dx;
    await tester.dragFrom(_ponto(tester, day, 9 * 60), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_dia(day)).dx, lessThan(left));
    expect(find.text('Selecionar demanda'), findsNothing);
  });

  for (final mode in AgendaMode.values) {
    for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
      testWidgets(
        '$mode / $kind inicia no horário clicado com snap e salva 30 minutos',
        (tester) async {
          final repository = FakeRegistroTempoRepository();
          await _abrir(tester, repository: repository, mode: mode);
          final day = DateTime(2026, 9, mode == AgendaMode.dia ? 9 : 12);
          final point = _ponto(tester, day, 9 * 60 + 8);
          final gesture = await tester.startGesture(point, kind: kind);
          await gesture.up();
          await tester.pumpAndSettle();
          expect(find.text('Selecionar demanda'), findsOneWidget);
          await _continuar(tester);
          expect(_campo(tester, 'inicio-hora'), '09');
          expect(_campo(tester, 'inicio-minuto'), '15');
          expect(_campo(tester, 'fim-hora'), '09');
          expect(_campo(tester, 'fim-minuto'), '45');
          expect(
            tester
                .widget<LogTimeDialog>(find.byType(LogTimeDialog))
                .dataInicial,
            day,
          );
          await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
          await tester.pumpAndSettle();
          expect(
            repository.registrosCriados.single.inicioEm,
            DateTime(day.year, day.month, day.day, 9, 15).toUtc(),
          );
          expect(repository.registrosCriados.single.duracaoMinutos, 30);
          expect(
            find.byKey(const ValueKey('abrir-lancamento-global')),
            findsOneWidget,
          );
        },
      );
    }
  }

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'hover discreto acompanha snap e some ao sair em ${theme.brightness}',
      (tester) async {
        await _abrir(tester, theme: theme);
        expect(_indicacoes, findsNothing);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(_ponto(tester, DateTime(2026, 9, 9), 9 * 60 + 8));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('adicionar-horario-2026-09-09-555')),
          findsOneWidget,
        );
        expect(find.text('Selecionar demanda'), findsNothing);
        await mouse.moveTo(_ponto(tester, DateTime(2026, 9, 9), 9 * 60 + 25));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('adicionar-horario-2026-09-09-570')),
          findsOneWidget,
        );
        await mouse.moveTo(const Offset(10, 10));
        await tester.pump();
        expect(_indicacoes, findsNothing);
        await mouse.removePointer();
      },
    );
  }

  testWidgets(
    'não oferece intervalo de 30 minutos que intersecta registro, permite encostar no início',
    (tester) async {
      await _abrir(
        tester,
        repository: FakeRegistroTempoRepository(
          registros: [
            registroTempoFixture(
              inicioLocal: DateTime(2026, 9, 9, 9, 20),
              duracaoMinutos: 30,
            ),
          ],
        ),
      );
      final day = DateTime(2026, 9, 9);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: _ponto(tester, day, 9 * 60));
      await tester.pump();
      expect(_indicacoes, findsNothing);
      await tester.tapAt(_ponto(tester, day, 9 * 60));
      await tester.pumpAndSettle();
      expect(find.text('Selecionar demanda'), findsNothing);
      await mouse.moveTo(_ponto(tester, day, 8 * 60 + 45));
      await tester.pump();
      expect(_indicacoes, findsOneWidget);
      await mouse.removePointer();
      await tester.tapAt(_ponto(tester, day, 8 * 60 + 45));
      await tester.pumpAndSettle();
      await _continuar(tester);
      expect(_campo(tester, 'inicio-minuto'), '45');
      expect(_campo(tester, 'fim-hora'), '09');
      expect(_campo(tester, 'fim-minuto'), '15');
    },
  );

  testWidgets('blocos continuam editáveis e exclusão não aciona criação', (
    tester,
  ) async {
    final repository = FakeRegistroTempoRepository(
      registros: [
        registroTempoFixture(
          id: 1,
          inicioLocal: DateTime(2026, 9, 9, 9),
          duracaoMinutos: 60,
        ),
      ],
    );
    await _abrir(tester, repository: repository);
    await tester.tap(find.byKey(const ValueKey('editar-registro-1')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<LogTimeDialog>(find.byType(LogTimeDialog)).edicao,
      isTrue,
    );
    expect(find.text('Selecionar demanda'), findsNothing);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('confirmar-exclusao-registro-1')),
    );
    await tester.pumpAndSettle();
    expect(repository.idsExcluidos, [1]);
    expect(repository.registrosCriados, isEmpty);
    expect(find.text('Selecionar demanda'), findsNothing);
  });

  testWidgets(
    'fim do dia mantém 30 minutos e não propõe intervalo passando da meia-noite',
    (tester) async {
      final repository = FakeRegistroTempoRepository();
      await _abrir(tester, mode: AgendaMode.dia, repository: repository);
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(LogTimeCalendar),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Scrollable &&
                axisDirectionToAxis(w.axisDirection) == Axis.vertical,
          ),
        ),
      );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      final day = DateTime(2026, 9, 9);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      for (final minute in [23 * 60 + 30, 23 * 60 + 45, 23 * 60 + 59]) {
        await mouse.moveTo(_ponto(tester, day, minute));
        await tester.pump();
        expect(_indicacoes, findsNothing);
        await tester.tapAt(_ponto(tester, day, minute));
        await tester.pump();
        expect(find.text('Selecionar demanda'), findsNothing);
      }
      await mouse.removePointer();
      await tester.tapAt(_ponto(tester, day, 23 * 60 + 15));
      await tester.pumpAndSettle();
      await _continuar(tester);
      expect(_campo(tester, 'inicio-hora'), '23');
      expect(_campo(tester, 'inicio-minuto'), '15');
      expect(_campo(tester, 'fim-hora'), '23');
      expect(_campo(tester, 'fim-minuto'), '45');
      await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
      await tester.pumpAndSettle();
      expect(
        repository.registrosCriados.single.inicioEm,
        DateTime(2026, 9, 9, 23, 15).toUtc(),
      );
      expect(repository.registrosCriados.single.duracaoMinutos, 30);
    },
  );

  testWidgets('sem Demandas desabilita hover, toque e botão global', (
    tester,
  ) async {
    await _abrir(tester, demandas: []);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('abrir-lancamento-global')),
          )
          .onPressed,
      isNull,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(
      location: _ponto(tester, DateTime(2026, 9, 9), 9 * 60),
    );
    await tester.pump();
    expect(_indicacoes, findsNothing);
    await mouse.removePointer();
    await tester.tapAt(_ponto(tester, DateTime(2026, 9, 9), 9 * 60));
    await tester.pumpAndSettle();
    expect(find.text('Selecionar demanda'), findsNothing);
  });

  testWidgets('enquanto salva edição não permite criação na grade ou global', (
    tester,
  ) async {
    final registro = registroTempoFixture(
      id: 1,
      inicioLocal: DateTime(2026, 9, 9, 9),
    );
    final pending = Completer<backend.RegistroTempo>();
    final repository = FakeRegistroTempoRepository(registros: [registro])
      ..respostaEditarPendente = pending;
    final vm = await _abrir(tester, repository: repository);
    final operation = vm.editarRegistroTempo(
      id: 1,
      data: DateTime(2026, 9, 9),
      hora: const TimeOfDay(hour: 9, minute: 0),
      duracaoHoras: .5,
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('abrir-lancamento-global')),
          )
          .onPressed,
      isNull,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(
      location: _ponto(tester, DateTime(2026, 9, 9), 10 * 60),
    );
    await tester.pump();
    expect(_indicacoes, findsNothing);
    await mouse.removePointer();
    await tester.tapAt(_ponto(tester, DateTime(2026, 9, 9), 10 * 60));
    await tester.pump();
    expect(find.text('Selecionar demanda'), findsNothing);
    pending.complete(registro);
    await operation;
    await tester.pumpAndSettle();
    await tester.tapAt(_ponto(tester, DateTime(2026, 9, 9), 10 * 60));
    await tester.pumpAndSettle();
    expect(find.text('Selecionar demanda'), findsOneWidget);
  });

  testWidgets('rolagem por toque em horário vazio não abre o seletor', (
    tester,
  ) async {
    await _abrir(tester);
    final point = _ponto(tester, DateTime(2026, 9, 9), 9 * 60);
    final top = tester.getTopLeft(_dia(DateTime(2026, 9, 9))).dy;
    await tester.dragFrom(point, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_dia(DateTime(2026, 9, 9))).dy, lessThan(top));
    expect(find.text('Selecionar demanda'), findsNothing);
  });

  testWidgets('cancelar seletor libera nova criação e preserva botão global', (
    tester,
  ) async {
    await _abrir(tester);
    await tester.tapAt(_ponto(tester, DateTime(2026, 9, 12), 9 * 60));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('abrir-lancamento-global')));
    await tester.pumpAndSettle();
    await _continuar(tester);
    final dialog = tester.widget<LogTimeDialog>(find.byType(LogTimeDialog));
    expect(dialog.dataInicial, DateTime(2026, 9, 9));
    expect(dialog.horaInicial, isNull);
    expect(dialog.duracaoInicialMinutos, 30);
  });

  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(2000, 1080),
  ]) {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      testWidgets(
        'prioriza calendário e mantém colunas em $size / ${theme.brightness}',
        (tester) async {
          await _abrir(
            tester,
            size: size,
            theme: theme,
            repository: FakeRegistroTempoRepository(
              registros: [
                registroTempoFixture(
                  inicioLocal: DateTime(2026, 9, 9, 9),
                  duracaoMinutos: 30,
                ),
              ],
            ),
          );
          final calendar = tester.getSize(
            find.byKey(const ValueKey('agenda-calendario')),
          );
          expect(
            calendar.width,
            closeTo(size.width - (size.width < 600 ? 16 : 32), .01),
          );
          expect(calendar.height, greaterThan(size.height / 2));
          expect(
            tester
                .getSize(find.byKey(const ValueKey('agenda-indicadores')))
                .height,
            lessThanOrEqualTo(80),
          );
          expect(find.text('Lançamentos no período'), findsOneWidget);
          expect(find.text('Tempo executado'), findsOneWidget);
          expect(find.text('30min'), findsOneWidget);
          if (size.width > 1240) {
            expect(calendar.width, greaterThan(1240));
            final day = _dia(DateTime(2026, 9, 9));
            expect(
              tester.getSize(day).width,
              closeTo((calendar.width - 72) / 7, .01),
            );
            expect(
              tester.getCenter(find.text('09/09')).dx,
              closeTo(tester.getCenter(day).dx, 1),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Finder get _indicacoes => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('adicionar-horario-'),
);
Finder _dia(DateTime day) => find.byKey(
  ValueKey(
    'log-time-day-${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
  ),
);
Offset _ponto(WidgetTester tester, DateTime day, int minute) {
  final rect = tester.getRect(_dia(day));
  return Offset(rect.center.dx, rect.top + minute * 64 / 60 + .5);
}

String _campo(WidgetTester tester, String name) => tester
    .widget<TextFormField>(find.byKey(ValueKey('log-time-$name')))
    .controller!
    .text;
Future<void> _continuar(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('confirmar-demanda-log-time')));
  await tester.pumpAndSettle();
}

Future<AgendaViewModel> _abrir(
  WidgetTester tester, {
  FakeRegistroTempoRepository? repository,
  List<backend.Demanda>? demandas,
  AgendaMode mode = AgendaMode.semana,
  Size size = const Size(1280, 1000),
  ThemeData? theme,
  double escala = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final vm = AgendaViewModel(
    hoje: DateTime(2026, 9, 9),
    demandaRepository: FakeAgendaDemandaRepository(
      demandas: demandas ?? [demandaAgendaFixture()],
    ),
    registroTempoRepository: repository ?? FakeRegistroTempoRepository(),
  );
  addTearDown(vm.dispose);
  await vm.setMode(mode);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: LogTimePage(viewModel: vm),
    ),
  );
  await tester.pumpAndSettle();
  return vm;
}
