import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/data/repositories/anotacao_demanda_repository.dart';
import 'package:temdas/view/demanda_detalhe_page.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view/widgets/demanda_tree.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
import 'package:temdas/view/widgets/log_time_dialog.dart';
import 'package:temdas/view_model/demanda_detalhe_view_model.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;
import 'support/fake_demanda_repository.dart';
import 'support/fake_sprint_repository.dart';

class Notes extends AnotacaoDemandaRepository {
  final items = <b.AnotacaoDemanda>[];
  bool falharLista = false;
  bool falharSalvar = false;
  int consultas = 0;
  @override
  Future<List<b.AnotacaoDemanda>> listar(int demandaId) async {
    consultas++;
    if (falharLista) throw StateError('offline');
    return items
        .where((a) => a.demandaId == demandaId && a.excluidoEm == null)
        .toList()
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
  }

  @override
  Future<b.AnotacaoDemanda> criar(int demandaId, String conteudo) async {
    if (falharSalvar) throw StateError('offline');
    final nota = b.AnotacaoDemanda(
      id: items.length + 1,
      demandaId: demandaId,
      autorId: 1,
      conteudo: conteudo,
      criadoEm: DateTime.utc(2026, 10, 1),
    );
    items.add(nota);
    return nota;
  }

  @override
  Future<b.AnotacaoDemanda> editar(int id, String conteudo) async {
    final i = items.indexWhere((a) => a.id == id);
    return items[i] = items[i].copyWith(
      conteudo: conteudo,
      editadoEm: DateTime.utc(2026, 10, 2),
    );
  }

  @override
  Future<void> excluir(int id) async {
    final i = items.indexWhere((a) => a.id == id);
    items[i] = items[i].copyWith(excluidoEm: DateTime.utc(2026, 10, 3));
  }
}

class PendingNotes extends Notes {
  final pending = <Completer<List<b.AnotacaoDemanda>>>[];
  @override
  Future<List<b.AnotacaoDemanda>> listar(int demandaId) {
    final result = Completer<List<b.AnotacaoDemanda>>();
    pending.add(result);
    return result.future;
  }
}

DemandaDetalheViewModel model({
  Notes? notes,
  FakeRegistroTempoRepository? horas,
  b.DemandaStatus status = b.DemandaStatus.aberta,
}) => DemandaDetalheViewModel(
  demandaRepository: FakeDemandaRepository(
    demandas: [demandaFixture(id: 1, status: status)],
  ),
  registroTempoRepository: horas ?? FakeRegistroTempoRepository(),
  anotacaoRepository: notes ?? Notes(),
  sprintViewModel: SprintViewModel(
    repository: FakeSprintRepository(sprints: []),
  ),
);
Future<void> abrir(
  WidgetTester tester,
  DemandaDetalheViewModel vm, {
  bool painel = true,
  Brightness brilho = Brightness.light,
  double escala = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brilho),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: painel
          ? Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      mostrarDetalhesDemandaDialog(context, 1, viewModel: vm),
                  child: const Text('Abrir'),
                ),
              ),
            )
          : DemandaDetalhePage(demandaId: 1, viewModel: vm),
    ),
  );
  if (painel) await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('ampliar e arrastar preservam aba e consulta de anotações', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notes = Notes()
      ..items.add(
        b.AnotacaoDemanda(
          id: 1,
          demandaId: 1,
          autorId: 1,
          conteudo: 'Anotação preservada',
          criadoEm: DateTime.utc(2026),
        ),
      );
    final vm = model(notes: notes);
    addTearDown(vm.dispose);
    await abrir(tester, vm);
    await tester.tap(find.text('Anotações'));
    await tester.pumpAndSettle();
    expect(notes.consultas, 1);
    final controller = DefaultTabController.of(
      tester.element(find.byType(TabBar)),
    );
    expect(controller.index, 1);
    await tester.tap(find.byTooltip('Ampliar painel'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('redimensionar-painel-demanda')),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    expect(notes.consultas, 1);
    expect(find.text('Anotação preservada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'consulta atrasada de anotações não sobrescreve uma resposta mais recente',
    () async {
      final notes = PendingNotes();
      final vm = model(notes: notes);
      addTearDown(vm.dispose);
      await vm.carregar(1);
      final antiga = vm.carregarAnotacoes(1);
      final recente = vm.carregarAnotacoes(1);
      final nova = b.AnotacaoDemanda(
        id: 2,
        demandaId: 1,
        autorId: 1,
        conteudo: 'recente',
        criadoEm: DateTime.utc(2026),
      );
      notes.pending[1].complete([nova]);
      await recente;
      notes.pending[0].complete([nova.copyWith(id: 1, conteudo: 'antiga')]);
      await antiga;
      expect(vm.anotacoes.single.conteudo, 'recente');
      expect(vm.carregandoAnotacoes, isFalse);
    },
  );

  for (final tamanho in [const Size(1440, 900), const Size(390, 844)]) {
    for (final brilho in Brightness.values) {
      testWidgets('painel direito e abas em $tamanho / $brilho', (
        tester,
      ) async {
        tester.view.physicalSize = tamanho;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final vm = model();
        addTearDown(vm.dispose);
        await abrir(tester, vm, brilho: brilho);
        final painel = find.byKey(const ValueKey('demanda-detalhe-dialog'));
        expect(
          tester.getSize(painel).width,
          tamanho.width < 840 ? tamanho.width : 420,
        );
        expect(tester.getTopRight(painel).dx, tamanho.width);
        expect(find.text('Visão geral'), findsOneWidget);
        expect(find.text('Anotações'), findsOneWidget);
        expect(find.text('Horas'), findsOneWidget);
        final topo = tester.getTopLeft(find.text('Demanda #1'));
        await tester.scrollUntilVisible(
          find.text('Sem Sprint'),
          200,
          scrollable: find.descendant(
            of: find.byKey(const PageStorageKey('demanda-visao-geral')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Sem Sprint'), findsOneWidget);
        expect(tester.getTopLeft(find.text('Demanda #1')), topo);
        await tester.tap(find.byTooltip('Fechar detalhes'));
        await tester.pumpAndSettle();
        expect(painel, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('celular com texto ampliado mantém abas e conteúdo utilizáveis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = model();
    addTearDown(vm.dispose);
    await abrir(tester, vm, escala: 2);
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);
    await tester.ensureVisible(find.text('Horas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horas'));
    await tester.pumpAndSettle();
    expect(find.text('Total: 0 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('fechar painel mantém quadro e expansão durante reconsulta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final demandas = [for (var id = 1; id <= 15; id++) demandaFixture(id: id)];
    final repository = FakeDemandaRepository(demandas: demandas);
    final vm = DemandasViewModel(repository: repository);
    final sprint = SprintViewModel(
      repository: FakeSprintRepository(sprints: []),
    );
    addTearDown(vm.dispose);
    addTearDown(sprint.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DemandasPage(viewModel: vm, sprintViewModel: sprint),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expandir-demanda-1')));
    await tester.pumpAndSettle();
    final tree = tester.element(find.byType(DemandaTree));
    await tester.tap(find.byKey(const ValueKey('abrir-painel-demanda-1')));
    await tester.pumpAndSettle();
    expect(find.text('Demanda #1'), findsOneWidget);
    final pendente = Completer<List<b.Demanda>>();
    repository.respostasListarPendentes.add(pendente);
    await tester.tap(find.byTooltip('Fechar detalhes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(vm.carregando, isTrue);
    expect(tester.element(find.byType(DemandaTree)), same(tree));
    expect(find.byKey(const ValueKey('status-demanda-1')), findsOneWidget);
    pendente.complete(demandas);
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(DemandaTree)), same(tree));
    expect(find.byKey(const ValueKey('status-demanda-1')), findsOneWidget);
  });
  testWidgets('corpo abre detalhes e apenas o ícone expande ou recolhe', (
    tester,
  ) async {
    int aberturas = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DemandaCard(
            demanda: demandaFixture(id: 1),
            tempoExecutadoTotalMinutos: 0,
            onEditar: () {},
            onExcluir: () {},
            onConcluir: () {},
            onAlterarStatus: (_) {},
            onMostrarTudo: () => aberturas++,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('abrir-painel-demanda-1')));
    await tester.pumpAndSettle();
    expect(aberturas, 1);
    expect(find.byKey(const ValueKey('status-demanda-1')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('expandir-demanda-1')));
    await tester.pumpAndSettle();
    expect(aberturas, 1);
    expect(find.byKey(const ValueKey('status-demanda-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('expandir-demanda-1')));
    await tester.pumpAndSettle();
    expect(aberturas, 1);
  });
  testWidgets('anotações criam, editam, excluem e preservam texto em erro', (
    tester,
  ) async {
    final notes = Notes();
    final vm = model(notes: notes, status: b.DemandaStatus.concluida);
    addTearDown(vm.dispose);
    await abrir(tester, vm);
    expect(notes.consultas, 0);
    await tester.tap(find.text('Anotações'));
    await tester.pumpAndSettle();
    expect(notes.consultas, 1);
    await tester.tap(find.text('Nova anotação'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('demanda-texto')),
      '  primeira\nlinha  ',
    );
    notes.falharSalvar = true;
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível salvar. Tente novamente.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('demanda-texto')))
          .controller!
          .text,
      '  primeira\nlinha  ',
    );
    notes.falharSalvar = false;
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('  primeira\nlinha  '), findsOneWidget);
    await tester.tap(find.text('Editar anotação'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('demanda-texto')),
      'editada',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('editada'), findsOneWidget);
    expect(find.textContaining('Editada em'), findsOneWidget);
    await tester.tap(find.text('Excluir anotação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('editada'), findsNothing);
    expect(notes.items.single.excluidoEm, isNotNull);
  });
  testWidgets(
    'erro de anotações permite tentar novamente e não mostra ações de outro autor',
    (tester) async {
      final notes = Notes()..falharLista = true;
      notes.items.add(
        b.AnotacaoDemanda(
          id: 1,
          demandaId: 1,
          autorId: 2,
          conteudo: 'outro autor',
          criadoEm: DateTime.utc(2026),
        ),
      );
      final vm = model(notes: notes);
      addTearDown(vm.dispose);
      await abrir(tester, vm);
      await tester.tap(find.text('Anotações'));
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível carregar as anotações.'),
        findsOneWidget,
      );
      notes.falharLista = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('outro autor'), findsOneWidget);
      expect(find.text('Editar anotação'), findsNothing);
      expect(find.text('Excluir anotação'), findsNothing);
    },
  );
  testWidgets(
    'aba Horas edita só observação e preserva intervalo de demanda cancelada',
    (tester) async {
      final registro = b.RegistroTempo(
        id: 1,
        demandaId: 1,
        inicioEm: DateTime.utc(2026, 10, 1, 9),
        duracaoMinutos: 45,
        criadoEm: DateTime.utc(2026, 10, 1, 10),
        observacao: 'original',
      );
      final horas = FakeRegistroTempoRepository(registros: [registro]);
      final vm = model(horas: horas, status: b.DemandaStatus.cancelada);
      addTearDown(vm.dispose);
      await abrir(tester, vm, painel: false);
      await tester.tap(find.text('Horas'));
      await tester.pumpAndSettle();
      expect(find.text('Total: 45 min'), findsOneWidget);
      expect(find.text('Excluir lançamento'), findsNothing);
      await tester.tap(find.text('Editar observação'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('log-time-inicio-hora')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('demanda-texto')),
        'nova observação',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      final salvo = (await horas.listarDaDemanda(1)).single;
      expect(salvo.observacao, 'nova observação');
      expect(salvo.inicioEm, registro.inicioEm);
      expect(salvo.duracaoMinutos, registro.duracaoMinutos);
      expect(salvo.criadoEm, registro.criadoEm);
      expect(horas.chamadasExcluir, 0);
    },
  );
  testWidgets(
    'formulário Log Time retorna observação opcional na criação e edição',
    (tester) async {
      for (final edicao in [false, true]) {
        LogTimeFormData? capturado;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => edicao
                        ? LogTimeDialog.editar(
                            demandaTitulo: 'D',
                            dataInicial: DateTime(2026, 10, 1),
                            horaInicial: const TimeOfDay(hour: 9, minute: 0),
                            duracaoInicialMinutos: 30,
                            observacaoInicial: 'existente',
                            onSalvar: (d) async {
                              capturado = d;
                              return null;
                            },
                          )
                        : LogTimeDialog(
                            demandaTitulo: 'D',
                            dataInicial: DateTime(2026, 10, 1),
                            horaInicial: const TimeOfDay(hour: 9, minute: 0),
                            onSalvar: (d) async {
                              capturado = d;
                              return null;
                            },
                          ),
                  ),
                  child: const Text('Lançar'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Lançar'));
        await tester.pumpAndSettle();
        if (edicao) expect(find.text('existente'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('log-time-observacao')),
          ' trabalho realizado ',
        );
        await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
        await tester.pumpAndSettle();
        expect(capturado!.observacao, ' trabalho realizado ');
        expect(capturado!.duracaoMinutos, 30);
      }
    },
  );
}
