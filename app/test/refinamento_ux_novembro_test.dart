import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/log_time_page.dart';
import 'package:temdas/view/widgets/app_selection.dart';
import 'package:temdas/view/widgets/demanda_dialog.dart';
import 'package:temdas/view/widgets/log_time_dialog.dart';
import 'package:temdas/view_model/agenda_view_model.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;

import 'support/fake_agenda_repositories.dart';
import 'support/fake_demanda_repository.dart' hide FakeRegistroTempoRepository;

Finder field(String name) => find.byKey(ValueKey('log-time-$name'));
String value(WidgetTester t, String name) =>
    t.widget<TextFormField>(field(name)).controller!.text;

Future<void> hours(WidgetTester t) async {
  for (final pair in {
    'inicio-hora': '09',
    'inicio-minuto': '15',
    'fim-hora': '10',
    'fim-minuto': '45',
  }.entries) {
    await t.enterText(field(pair.key), pair.value);
  }
}

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 768.0, 1280.0]) {
      testWidgets(
        'busca por ID/acento e seleção válida em $width escuro=$dark',
        (t) async {
          t.view.physicalSize = Size(width, 900);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          LogTimeFormData? saved;
          await t.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: Scaffold(
                body: LogTimeDialog(
                  demandas: [
                    demandaFixture(id: 42, titulo: 'Revisão de AÇÃO'),
                    demandaFixture(id: 99, titulo: 'Outra'),
                  ],
                  dataInicial: DateTime(2026, 11, 3),
                  horaInicial: const TimeOfDay(hour: 9, minute: 0),
                  onSalvar: (data) async {
                    saved = data;
                    return null;
                  },
                ),
              ),
            ),
          );
          final search = find.byKey(
            const ValueKey('selecionar-demanda-log-time'),
          );
          await t.enterText(search, 'REVISAO DE acao');
          await t.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('opcao-demanda-log-time-42')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('opcao-demanda-log-time-99')),
            findsNothing,
          );
          await t.testTextInput.receiveAction(TextInputAction.done);
          await t.pumpAndSettle();
          // Explicitly selecting an option, including by keyboard, is required.
          await t.enterText(search, '42');
          await t.pumpAndSettle();
          await t.tap(find.byKey(const ValueKey('opcao-demanda-log-time-42')));
          await t.pumpAndSettle();
          await hours(t);
          await t.enterText(
            field('observacao'),
            '  Texto preservado\ncom acentos.  ',
          );
          await t.ensureVisible(find.byKey(const ValueKey('salvar-log-time')));
          await t.tap(find.byKey(const ValueKey('salvar-log-time')));
          await t.pumpAndSettle();
          expect(saved?.demandaId, 42);
          expect(saved?.duracaoMinutos, 90);
          expect(saved?.observacao, '  Texto preservado\ncom acentos.  ');
          expect(t.takeException(), isNull);
        },
      );
    }
  }

  for (final observation in <String?>[
    'Observação salva\ncom detalhe',
    '',
    null,
  ]) {
    testWidgets('edição preenche observação $observation sem trocar Demanda', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogTimeDialog.editar(
              demandaId: 42,
              demandaTitulo: '42 - Demanda original',
              dataInicial: DateTime(2026, 11, 3),
              horaInicial: const TimeOfDay(hour: 9, minute: 15),
              duracaoInicialMinutos: 90,
              observacaoInicial: observation,
              onSalvar: (_) async => null,
            ),
          ),
        ),
      );
      expect(value(t, 'observacao'), observation ?? '');
      expect(value(t, 'inicio-hora'), '09');
      expect(value(t, 'inicio-minuto'), '15');
      expect(value(t, 'fim-hora'), '10');
      expect(value(t, 'fim-minuto'), '45');
      expect(
        find.byKey(const ValueKey('selecionar-demanda-log-time')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('criar-demanda-no-log-time')),
        findsNothing,
      );
    });
  }

  testWidgets('observações originais sem texto agregado preenchem edição', (
    t,
  ) async {
    final original = b.RegistroTempoObservacao(
      inicioEm: DateTime.utc(2026, 11, 3, 9),
      fimEm: DateTime.utc(2026, 11, 3, 10),
      texto: 'Texto legado\nsem alteração',
    );
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogTimeDialog.editar(
            demandaId: 42,
            demandaTitulo: 'Original',
            dataInicial: DateTime(2026, 11, 3),
            horaInicial: const TimeOfDay(hour: 9, minute: 0),
            duracaoInicialMinutos: 60,
            observacoesOriginais: [original],
            onSalvar: (_) async => null,
          ),
        ),
      ),
    );
    expect(value(t, 'observacao'), original.texto);
  });

  testWidgets(
    'texto livre sem opção válida não salva e informa ausência de resultados',
    (t) async {
      var saves = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogTimeDialog(
              demandas: [demandaFixture(id: 42)],
              dataInicial: DateTime(2026, 11, 3),
              onSalvar: (_) async {
                saves++;
                return null;
              },
            ),
          ),
        ),
      );
      await t.enterText(
        find.byKey(const ValueKey('selecionar-demanda-log-time')),
        'inexistente',
      );
      await t.pumpAndSettle();
      expect(find.text('Nenhuma Demanda encontrada.'), findsOneWidget);
      await t.ensureVisible(find.byKey(const ValueKey('salvar-log-time')));
      await t.tap(find.byKey(const ValueKey('salvar-log-time')));
      await t.pumpAndSettle();
      expect(find.text('Selecione uma demanda válida.'), findsOneWidget);
      expect(saves, 0);
    },
  );

  Future<({FakeDemandaRepository demands, FakeRegistroTempoRepository records})>
  openPage(WidgetTester t) async {
    final demands = FakeDemandaRepository(demandas: []);
    final records = FakeRegistroTempoRepository();
    final agenda = AgendaViewModel(
      demandaRepository: demands,
      registroTempoRepository: records,
      hoje: DateTime(2026, 11, 3),
    );
    final create = DemandasViewModel(repository: demands);
    addTearDown(agenda.dispose);
    addTearDown(create.dispose);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LogTimePage(viewModel: agenda, demandasViewModel: create),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('abrir-lancamento-global')));
    await t.pumpAndSettle();
    expect(find.text('Selecionar demanda'), findsNothing);
    expect(find.byType(LogTimeDialog), findsOneWidget);
    await hours(t);
    await t.enterText(field('observacao'), 'Rascunho do lançamento');
    return (demands: demands, records: records);
  }

  Future<void> openCreate(WidgetTester t) async {
    await t.ensureVisible(
      find.byKey(const ValueKey('criar-demanda-no-log-time')),
    );
    await t.tap(find.byKey(const ValueKey('criar-demanda-no-log-time')));
    await t.pumpAndSettle();
    expect(find.byType(CriarDemandaDialog), findsOneWidget);
  }

  testWidgets(
    'primeira Demanda usa cadastro compartilhado e não lança horas automaticamente',
    (t) async {
      final repos = await openPage(t);
      final date = t
          .widget<LogTimeDialog>(find.byType(LogTimeDialog))
          .dataInicial;
      await openCreate(t);
      await t.enterText(
        find.byKey(const ValueKey('criar-demanda-titulo')),
        'Nova ação',
      );
      await t.enterText(
        find.byKey(const ValueKey('criar-demanda-descricao')),
        'Descrição completa',
      );
      await t.enterText(
        find.byKey(const ValueKey('criar-demanda-tempo')),
        '2,5',
      );
      await t.ensureVisible(find.byKey(const ValueKey('criar-demanda')));
      await t.tap(find.byKey(const ValueKey('criar-demanda')));
      await t.pumpAndSettle();
      expect(repos.demands.chamadasCriar, 1);
      expect(repos.demands.ultimaCriacao?.tempoEstimadoMinutos, 150);
      expect(find.byType(CriarDemandaDialog), findsNothing);
      expect(
        t
            .widget<TextFormField>(
              find.byKey(const ValueKey('selecionar-demanda-log-time')),
            )
            .controller!
            .text,
        '1 - Nova ação',
      );
      expect(repos.records.registrosCriados, isEmpty);
      expect(value(t, 'inicio-minuto'), '15');
      expect(value(t, 'fim-minuto'), '45');
      expect(value(t, 'observacao'), 'Rascunho do lançamento');
      expect(
        t.widget<LogTimeDialog>(find.byType(LogTimeDialog)).dataInicial,
        date,
      );
      await t.ensureVisible(find.byKey(const ValueKey('salvar-log-time')));
      await t.tap(find.byKey(const ValueKey('salvar-log-time')));
      await t.pumpAndSettle();
      expect(repos.records.registrosCriados.single.demandaId, 1);
      expect(repos.records.registrosCriados.single.duracaoMinutos, 90);
    },
  );

  testWidgets(
    'erro e cancelamento do cadastro preservam integralmente o lançamento',
    (t) async {
      final repos = await openPage(t);
      final pending = Completer<b.Demanda>();
      repos.demands.respostaCriarPendente = pending;
      await openCreate(t);
      await t.enterText(
        find.byKey(const ValueKey('criar-demanda-titulo')),
        'Rascunho da Demanda',
      );
      await t.ensureVisible(find.byKey(const ValueKey('criar-demanda')));
      await t.tap(find.byKey(const ValueKey('criar-demanda')));
      await t.pump();
      pending.completeError(StateError('synthetic creation failure'));
      await t.pumpAndSettle();
      expect(find.byType(CriarDemandaDialog), findsOneWidget);
      expect(
        t
            .widget<TextFormField>(
              find.byKey(const ValueKey('criar-demanda-titulo')),
            )
            .controller!
            .text,
        'Rascunho da Demanda',
      );
      final cancel = find.descendant(
        of: find.byType(CriarDemandaDialog),
        matching: find.widgetWithText(TextButton, 'Cancelar'),
      );
      await t.tap(cancel);
      await t.pumpAndSettle();
      expect(value(t, 'inicio-hora'), '09');
      expect(value(t, 'inicio-minuto'), '15');
      expect(value(t, 'fim-hora'), '10');
      expect(value(t, 'fim-minuto'), '45');
      expect(value(t, 'observacao'), 'Rascunho do lançamento');
      expect(repos.records.registrosCriados, isEmpty);
    },
  );

  testWidgets(
    'seleção compartilhada não aninha registradores e preserva campos/cliques',
    (t) async {
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String?;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      var clicks = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSelection(
              child: Column(
                children: [
                  const AppSelection(
                    child: Text('Título selecionável da tela'),
                  ),
                  const Text('Descrição selecionável'),
                  const TextField(key: ValueKey('campo-nativo')),
                  TextButton(
                    onPressed: () => clicks++,
                    child: const Text('Ação normal'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(SelectionArea), findsOneWidget);
      final selection = t.state<SelectableRegionState>(
        find.byType(SelectableRegion),
      );
      selection.selectAll(SelectionChangedCause.keyboard);
      await t.pump();
      selection.contextMenuButtonItems
          .singleWhere((item) => item.type == ContextMenuButtonType.copy)
          .onPressed!();
      await t.pump();
      expect(copied, contains('Título selecionável da tela'));
      expect(copied, contains('Descrição selecionável'));
      await t.tap(find.text('Ação normal'));
      await t.pump();
      expect(clicks, 1);
      await t.enterText(
        find.byKey(const ValueKey('campo-nativo')),
        'Campo editável',
      );
      expect(find.text('Campo editável'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
