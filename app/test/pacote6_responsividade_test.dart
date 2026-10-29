import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/auth_pages.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/sprint_page.dart';
import 'package:temdas/view/log_time_page.dart';
import 'package:temdas/view/meu_perfil_page.dart';
import 'package:temdas/view/widgets/log_time_dialog.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas/view_model/agenda_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;
import 'support/fake_demanda_repository.dart';
import 'support/fake_sprint_repository.dart';
import 'support/fake_agenda_repositories.dart' as a;

b.Sprint sprint() => b.Sprint(
  id: 7,
  usuarioId: 1,
  nome: 'Entrega com nome longo e legível',
  dataInicio: DateTime(2026, 9, 1),
  dataFim: DateTime(2026, 9, 7),
  tempoPrevistoMinutos: 120,
  status: b.SprintStatus.ativa,
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in [
    const Size(320, 640),
    const Size(768, 600),
    const Size(1440, 900),
  ]) {
    for (final dark in [false, true]) {
      for (final page in [
        'Demandas',
        'Sprint',
        'Log Time',
        'Login',
        'Perfil',
        'Formulário Log Time',
        'Formulário Sprint',
      ]) {
        testWidgets('$page em $size / escuro=$dark / texto ampliado', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final dvm = DemandasViewModel(
            repository: FakeDemandaRepository(demandas: [demandaFixture()]),
          );
          final svm = SprintViewModel(
            repository: FakeSprintRepository(sprints: [sprint()]),
          );
          final avm = AgendaViewModel(
            demandaRepository: a.FakeAgendaDemandaRepository(
              demandas: [a.demandaAgendaFixture()],
            ),
            registroTempoRepository: a.FakeRegistroTempoRepository(),
            hoje: DateTime(2026, 9, 9),
          );
          addTearDown(dvm.dispose);
          addTearDown(svm.dispose);
          addTearDown(avm.dispose);
          final content = switch (page) {
            'Demandas' => DemandasPage(viewModel: dvm, sprintViewModel: svm),
            'Formulário Sprint' ||
            'Sprint' => SprintPage(viewModel: svm, demandasViewModel: dvm),
            'Log Time' => LogTimePage(viewModel: avm),
            'Login' => const LoginPage(session: null),
            'Perfil' => const MeuPerfilPage(),
            _ => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => LogTimeDialog(
                      demandaTitulo: 'Demanda de teste',
                      dataInicial: DateTime(2026, 9, 9),
                    ),
                  ),
                  child: const Text('Formulário'),
                ),
              ),
            ),
          };
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.8)),
                child: child!,
              ),
              home: content,
            ),
          );
          await tester.pumpAndSettle();
          if (page == 'Formulário Log Time') {
            await tester.tap(find.text('Formulário'));
            await tester.pumpAndSettle();
          }
          if (page == 'Formulário Sprint') {
            await tester.tap(find.byKey(const ValueKey('nova-sprint')));
            await tester.pumpAndSettle();
          }
          if (page.startsWith('Formulário') && size.width < 600) {
            tester.view.viewInsets = const FakeViewPadding(bottom: 240);
            addTearDown(tester.view.resetViewInsets);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
