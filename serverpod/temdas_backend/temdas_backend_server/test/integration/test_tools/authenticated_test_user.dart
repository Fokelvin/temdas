import 'package:serverpod_test/serverpod_test.dart';
import 'package:temdas_backend_server/src/auth/supabase_auth_service.dart';
import 'package:temdas_backend_server/src/generated/protocol.dart';

/// Gives legacy domain regression tests one persisted owner per test group.
/// Ownership and JWT boundary tests use signed tokens separately.
Future<void> installAal2TestUser(TestSessionBuilder builder, String sub) async {
  final session = builder.build();
  var usuario = await Usuario.db.findFirstRow(
    session,
    where: (t) => t.supabaseUserId.equals(sub),
  );
  usuario ??= await Usuario.db.insertRow(
    session,
    Usuario(supabaseUserId: sub, createdAt: DateTime.now().toUtc()),
  );
  final owner = usuario;
  setUsuarioResolverForTesting(
    (_) async => AuthenticatedUsuario(owner, sub, 'aal2'),
  );
}

void clearAal2TestUser() => setUsuarioResolverForTesting(null);
